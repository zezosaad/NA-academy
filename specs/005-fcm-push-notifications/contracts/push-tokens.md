# Contract — `PushTokens` API

**Module**: `back/src/push-tokens/`
**Base path**: `/me/push-tokens` (always scoped to the authenticated user — there is no admin endpoint to view another user's tokens)
**Auth**: All endpoints require a valid JWT. No role check beyond authentication; tokens are always self-managed.

This contract documents how the Flutter `na_app/` registers and refreshes its FCM token on the server. The shapes here are normative.

---

## Endpoint summary

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/me/push-tokens` | Register a new token (or rotate-in-place an existing one for this device). |
| `PATCH` | `/me/push-tokens/:id` | Refresh metadata (e.g., `appVersion`, `lastSeenAt`) or replace the token string after FCM rotation. |
| `DELETE` | `/me/push-tokens/:id` | Tombstone a token (e.g., on logout). |
| `GET` | `/me/push-tokens` | List the current user's active token (returns 0 or 1 row). |

---

## DTOs

### `RegisterTokenDto`

```ts
export class RegisterTokenDto {
  @IsString()
  @Length(50, 4096)              // FCM tokens are typically ~163 chars; bound generously
  token!: string;

  @IsIn(['ios', 'android'])
  platform!: 'ios' | 'android';

  @IsString()
  @IsOptional()
  @Length(1, 64)
  appVersion?: string;

  @IsMongoId()
  @IsOptional()
  deviceId?: string;             // the hardware-bound Device._id, if available client-side
}
```

### `RefreshTokenDto`

```ts
export class RefreshTokenDto {
  @IsString()
  @IsOptional()
  @Length(50, 4096)
  token?: string;                // present only when the FCM token itself rotated

  @IsString()
  @IsOptional()
  @Length(1, 64)
  appVersion?: string;
}
```

### `PushTokenResponseDto`

```ts
export class PushTokenResponseDto {
  id!: string;
  platform!: 'ios' | 'android';
  appVersion?: string;
  deviceId?: string;
  lastSeenAt!: string;           // ISO 8601
  createdAt!: string;
}
```

(The actual `token` string is **never** returned — it's a delivery secret. Clients only need the `id` to refresh / delete.)

---

## Endpoint specifications

### `POST /me/push-tokens`

**Behavior**:

1. Compute `tokenHash = sha256(token)`.
2. If a row with this `tokenHash` already exists:
   - If `userId` matches the caller and `tombstonedAt` is null → no-op; return that row's `PushTokenResponseDto`. (Idempotent re-register.)
   - If `userId` matches and `tombstonedAt` is set → un-tombstone (set `tombstonedAt = null`, refresh `lastSeenAt`).
   - If `userId` is **different** → tombstone the existing row (token has changed hands; this happens when a user logs in on a hand-me-down device) and proceed to step 3.
3. Tombstone the caller's existing active token, if any: set `tombstonedAt = now()`.
4. Insert a new `PushToken` row with `userId = current`, `token`, `tokenHash`, `platform`, `appVersion`, optional `deviceId`, `lastSeenAt = now()`.
5. Return the response DTO.

**Response**: `201 Created` + `PushTokenResponseDto`.

**Errors**: standard validation `400`. No `409` — duplicates are handled by the upsert logic above.

---

### `PATCH /me/push-tokens/:id`

**Behavior**:

- If the row's `userId` ≠ caller → `403`.
- If `dto.token` is provided: rotate the token string. Update `tokenHash`. If the new hash collides with another active row owned by *another* user, tombstone that other row first (mirror of the rotation case above).
- Update `appVersion` and `lastSeenAt` regardless.

**Response**: `200 OK` + `PushTokenResponseDto`.

---

### `DELETE /me/push-tokens/:id`

**Behavior**: tombstones the row (`tombstonedAt = now()`). Idempotent.

**Response**: `204 No Content`.

---

### `GET /me/push-tokens`

**Behavior**: returns the caller's currently-active token row, or `[]` if none.

**Response**: `200 OK` + `PushTokenResponseDto[]` (length 0 or 1).

---

## Lifecycle wiring

The Flutter client implements the following lifecycle in `na_app/lib/core/notifications/push_token_registrar.dart`:

| Event | Action |
|---|---|
| User logs in | Get current FCM token via `FirebaseMessaging.instance.getToken()`. `POST /me/push-tokens`. Persist returned `id` in `flutter_secure_storage` under key `push_token_id`. |
| `FirebaseMessaging.instance.onTokenRefresh` fires | `PATCH /me/push-tokens/<stored id>` with the new `token`. |
| App resume | If permission is granted but our stored token is stale (> 7 days `lastSeenAt`), fire a no-token-change `PATCH` to refresh `lastSeenAt`. |
| User logs out | `DELETE /me/push-tokens/<stored id>`, clear the stored id. |
| OS notification permission revoked | The token is still valid for delivery (the OS just won't display alerts). We do not delete the token in this case; the in-app inbox remains the surface of record. |

---

## Cross-module coordination with `devices`

`back/src/devices/devices.service.ts::resetDevice(userId)` is extended:

```ts
// pseudocode
async resetDevice(userId: string): Promise<void> {
  await this.deviceModel.findOneAndUpdate(
    { userId: new Types.ObjectId(userId) },
    { isActive: false },
    { new: true },
  ).exec();

  // NEW
  await this.pushTokensService.tombstoneActiveForUser(userId);

  this.logger.log(`Device reset (and push token tombstoned) for user ${userId}`);
}
```

The `PushTokensService.tombstoneActiveForUser(userId)` method is the only cross-module surface; it does no FCM call (we cannot un-register a token from FCM directly — Google rotates / invalidates them autonomously).

---

## Why no admin endpoints

The admin dashboard never needs to look at raw push tokens. Per-recipient delivery state is exposed through `GET /notifications/:id` (which contains `failureReason` like `unregistered` or `no-active-token`); that's enough to debug "why didn't user X get this?". Exposing tokens elsewhere would be a security regression.
