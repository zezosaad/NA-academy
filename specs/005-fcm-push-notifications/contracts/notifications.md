# Contract — `Notifications` API

**Module**: `back/src/notifications/`
**Base path**: `/notifications`
**Auth**: All endpoints require a valid JWT (`JwtAuthGuard` is global). Per-endpoint role rules are listed below.
**Documentation**: All endpoints registered with Swagger via `@ApiTags('Notifications')` + per-route `@ApiOperation` / `@ApiResponse`.

This contract is the single source of truth consumed by both `admin-dashboard/` (TypeScript) and `na_app/` (Dart, via `freezed` DTOs). The shapes here are normative.

---

## Endpoint summary

| Method | Path | Purpose | Allowed roles |
|---|---|---|---|
| `POST` | `/notifications` | Compose and send a notification. | `admin`, `teacher` (audience-restricted) |
| `GET` | `/notifications` | List sent notifications (history; admin/teacher view). | `admin`, `teacher` (filtered to own sends) |
| `GET` | `/notifications/:id` | Get one notification with detail (recipient list, payload). | `admin`, `teacher` (own only) |
| `GET` | `/notifications/me` | Inbox for the current user. | any authenticated user |
| `PATCH` | `/notifications/me/:id/read` | Mark one inbox item as read. | any authenticated user (must be own recipient row) |
| `POST` | `/notifications/me/read-all` | Mark all of the current user's inbox as read. | any authenticated user |

---

## DTOs

### `AudienceDto`

```ts
// audience.dto.ts
export type AudienceKind = 'all' | 'user-list' | 'subject';

export class AudienceDto {
  @IsIn(['all', 'user-list', 'subject'])
  kind!: AudienceKind;

  // Required when kind === 'user-list'
  @ValidateIf(o => o.kind === 'user-list')
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(1000)
  @IsMongoId({ each: true })
  userIds?: string[];

  // Required when kind === 'subject'
  @ValidateIf(o => o.kind === 'subject')
  @IsMongoId()
  subjectId?: string;
}
```

### `CreateNotificationDto`

```ts
// create-notification.dto.ts
export class CreateNotificationDto {
  @IsString()
  @Length(1, 100)
  @Matches(/^[\s\S]+$/) // any character, validates non-empty after trim
  title!: string;

  @IsString()
  @Length(1, 1000)
  body!: string;

  @IsObject()
  @IsOptional()
  @ValidateData()           // custom validator: keys ∈ /^[a-zA-Z][a-zA-Z0-9_]{0,31}$/, all values strings, total ≤ 4 KB
  data?: Record<string, string>;

  @ValidateNested()
  @Type(() => AudienceDto)
  audience!: AudienceDto;
}
```

Header (required): `Idempotency-Key: <UUIDv4>` — see Decision 6 in `research.md`. The handler enforces presence and UUID v4 format; missing or malformed → `400 Bad Request`.

### `NotificationResponseDto`

```ts
export class NotificationStatsDto {
  total!: number;
  delivered!: number;
  failed!: number;
  read!: number;
}

export class AudienceResponseDto {
  kind!: AudienceKind;
  userIds?: string[];           // present iff kind === 'user-list'
  subjectId?: string;           // present iff kind === 'subject'
  resolvedRecipientCount!: number;
}

export class NotificationResponseDto {
  id!: string;
  title!: string;
  body!: string;
  data?: Record<string, string>;
  senderId!: string;
  senderName!: string;          // hydrated from User.name on read
  senderRole!: 'admin' | 'teacher';
  audience!: AudienceResponseDto;
  stats!: NotificationStatsDto;
  createdAt!: string;           // ISO 8601
}
```

### `RecipientStateDto` (returned by `GET /notifications/:id` detail)

```ts
export class RecipientStateDto {
  userId!: string;
  userName!: string;
  state!: 'pending' | 'delivered' | 'failed';
  failureReason?: string;
  deliveredAt?: string;
  readAt?: string;
}

export class NotificationDetailResponseDto extends NotificationResponseDto {
  recipients?: RecipientStateDto[];     // present if not archived
  recipientsArchived?: boolean;         // true once 365-day retention has pruned per-recipient rows
  recipientsArchivedAt?: string;        // ISO timestamp of the prune
}
```

### `InboxItemDto` (returned by `GET /notifications/me`)

```ts
export class InboxItemDto {
  id!: string;
  title!: string;
  body!: string;
  data?: Record<string, string>;
  createdAt!: string;
  readAt?: string;
  senderName!: string;
}

export class InboxResponseDto {
  items!: InboxItemDto[];
  nextCursor?: string;          // ISO timestamp; pass to ?before=<cursor> for next page
  unreadCount!: number;
}
```

### `NotificationListQueryDto` (history list filters)

```ts
export class NotificationListQueryDto {
  @IsOptional() @IsString() @Length(1, 100)
  q?: string;                                  // keyword over title + body, FR-027

  @IsOptional() @IsIn(['all', 'user-list', 'subject'])
  audienceKind?: AudienceKind;

  @IsOptional() @IsMongoId()
  subjectId?: string;                          // when audienceKind === 'subject'

  @IsOptional() @IsISO8601()
  before?: string;                             // pagination cursor (createdAt)

  @IsOptional() @IsInt() @Min(1) @Max(100)
  limit?: number = 20;
}
```

---

## Endpoint specifications

### `POST /notifications`

**Auth**: `@Roles(UserRole.ADMIN, UserRole.TEACHER)`.

**Request body**: `CreateNotificationDto`. **Header**: `Idempotency-Key: <uuid>`.

**Behavior**:

1. Resolve and validate audience.
   - `kind = 'all'`: any authenticated admin only. Teacher → `403`.
   - `kind = 'user-list'`: admin only. Teacher → `403`.
   - `kind = 'subject'`: admin always; teacher only if `Subject.createdBy === currentUserId`. Otherwise `403`.
2. Look up active recipients (`User.status === 'active'`) into `resolvedUserIds`. If empty → `422 Unprocessable Entity` with `code = 'audience-empty'`.
3. Idempotency check: if `(senderId, idempotencyKey)` already exists, return that document's response unchanged (`200 OK`, idempotent replay).
4. Create `Notification` document with `audience.resolvedUserIds` snapshotted.
5. Bulk-insert `NotificationRecipient` rows (state = `pending`) for each resolved user.
6. Resolve active `PushToken` for each user; for users with no active token, mark their recipient row `failed` with `failureReason = 'no-active-token'`.
7. Fan-out to FCM via `firebase-admin` `sendEachForMulticast` in batches of 500. For each response, update the recipient row to `delivered` or `failed` (with `failureReason` mapped from the FCM error code).
8. Update `Notification.stats` aggregates.

**Response timing**:

- For `resolvedRecipientCount ≤ 1000`: synchronous; respond after step 8 with `201 Created` and the full `NotificationResponseDto`.
- For `resolvedRecipientCount > 1000`: respond at step 5 with `202 Accepted` and the `NotificationResponseDto` (stats may still be partial); steps 6–8 continue asynchronously.

**Errors**:

| Status | Code | When |
|---|---|---|
| `400` | `validation` | DTO validation failed (length, types). |
| `400` | `idempotency-key-missing` / `idempotency-key-malformed` | Header missing or not a UUID v4. |
| `400` | `body-contains-secret` | Body matched a known credential pattern (FR-033 hardening). |
| `403` | `audience-forbidden` | Teacher attempting `all` / `user-list`, or teacher targeting a non-owned subject. |
| `404` | `subject-not-found` | `audience.kind = 'subject'` and the subject does not exist. |
| `422` | `audience-empty` | Resolved audience has zero recipients. |

**Audit log**: writes a `notifications.send` row with `{ senderId, audienceDescriptor, titleHash, bodyHash, idempotencyKey, resolvedRecipientCount }` via the existing logging interceptor.

---

### `GET /notifications`

Admin: returns all notifications. Teacher: filtered to `senderId === currentUser._id`.

**Query**: `NotificationListQueryDto`.
**Response**: `{ items: NotificationResponseDto[], nextCursor?: string }`.
**Pagination**: cursor on `createdAt`. Cursor opaque to clients (ISO timestamp, but treated as opaque).

---

### `GET /notifications/:id`

**Auth**: admin (any) or teacher (own sends only — `senderId` check).
**Response**: `NotificationDetailResponseDto`.

If the per-recipient retention window has elapsed (parent `createdAt < now - 365d`), `recipients` is omitted, `recipientsArchived: true`, and `recipientsArchivedAt` is set.

---

### `GET /notifications/me`

**Auth**: any authenticated user.
**Query**: `?limit=20&before=<cursor>`.
**Response**: `InboxResponseDto`.

Returns the joined view of `NotificationRecipient` (where `userId === currentUserId`) and the parent `Notification` document, ordered by `Notification.createdAt DESC`.

`unreadCount` is computed once per request as `count where readAt is null`.

---

### `PATCH /notifications/me/:id/read`

**Auth**: any authenticated user.
**Behavior**: sets `readAt = now()` on the `NotificationRecipient` row matching `(notificationId, userId = current)`. Recomputes `Notification.stats.read`.
**Idempotent**: if already read, returns `200 OK` with the existing timestamp.
**Errors**: `404` if no matching recipient row.

---

### `POST /notifications/me/read-all`

**Auth**: any authenticated user.
**Behavior**: bulk-sets `readAt = now()` on all `NotificationRecipient` rows where `userId = current` and `readAt is null`. Recomputes parent `Notification.stats.read` for each affected notification.
**Response**: `{ markedRead: number }`.

---

## RBAC matrix

| Endpoint | `student` | `teacher` | `admin` |
|---|---|---|---|
| `POST /notifications` (kind=all) | 403 | 403 | ✅ |
| `POST /notifications` (kind=user-list) | 403 | 403 | ✅ |
| `POST /notifications` (kind=subject, owned) | 403 | ✅ | ✅ |
| `POST /notifications` (kind=subject, not owned) | 403 | 403 | ✅ |
| `GET /notifications` | 403 | own only | ✅ all |
| `GET /notifications/:id` | 403 | own only | ✅ |
| `GET /notifications/me` | ✅ | ✅ | ✅ |
| `PATCH /notifications/me/:id/read` | ✅ (own row) | ✅ (own row) | ✅ (own row) |
| `POST /notifications/me/read-all` | ✅ | ✅ | ✅ |

Layer-1 enforcement via `@Roles(...)` decorator + `RolesGuard`. Layer-2 (audience ownership) inside `NotificationsService`.

---

## Rate limiting

- `POST /notifications`: 30 requests / minute / sender (existing `@nestjs/throttler` global default plus per-route override). Catches accidental loops.
- `PATCH /notifications/me/:id/read`: no per-route override; covered by the global throttler.
