# Contract: Entitlement Verification

Owns FR-013 (revoke on entitlement loss), FR-013a (14-day grace re-verify), FR-014 (content-version detection).

---

## `POST /media/entitlement/verify`

Called by the Flutter client on every reconnect, every play attempt that crosses the 14-day grace, and on app foreground after extended background. The server returns, for each requested `mediaId`, whether the authenticated user still has access and whether the content version has changed.

### Request

```ts
// VerifyEntitlementDto (back/src/media/dto/verify-entitlement.dto.ts)
class VerifyEntitlementDto {
  @ArrayMinSize(1)
  @ArrayMaxSize(100)
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => VerifyEntitlementItemDto)
  items!: VerifyEntitlementItemDto[];
}

class VerifyEntitlementItemDto {
  @IsMongoId()
  mediaId!: string;

  @IsMongoId()
  lessonId!: string;

  @IsMongoId()
  subjectId!: string;

  @IsString()
  @IsOptional()
  knownContentVersion?: string;
}
```

### Response

```ts
// EntitlementVerificationResultDto
class EntitlementVerificationResultDto {
  @IsString()
  serverTimestamp!: string;          // ISO 8601, UTC — anchors the client's monotonic clock

  @ValidateNested({ each: true })
  @Type(() => EntitlementVerificationItemDto)
  items!: EntitlementVerificationItemDto[];
}

class EntitlementVerificationItemDto {
  mediaId!: string;
  lessonId!: string;

  // 'allowed': user can keep / continue using offline copy
  // 'revoked': user has lost access — client MUST delete ciphertext and the row
  // 'superseded': content was updated server-side; old copy may keep playing; offer re-download
  decision!: 'allowed' | 'revoked' | 'superseded';

  currentContentVersion!: string;    // present even when allowed; informs supersession detection
  reason?: string;                   // human-readable, for in-app diagnostic; optional
}
```

### Auth

- `@ApiBearerAuth()` — same JWT as the rest of the API.
- `@Roles('student', 'teacher')` — admins have no offline use case.

### Service contract

`MediaService.verifyEntitlements(userId, items)` reuses the existing `LessonsService.canAccessMediaContent(userId, subjectId, mediaId)` per item. For `superseded`, it compares the request's `knownContentVersion` against the server's current value, derived from `MediaAsset.updatedAt.getTime().toString()` (sufficient for "changed since I downloaded it"; can be replaced with a stricter content hash later without breaking the wire format).

### Errors

- `400 Bad Request` — DTO validation failure (empty array, invalid ObjectId, etc.).
- `401 Unauthorized` — missing/invalid JWT.
- `403 Forbidden` — role guard rejection (admin).

The endpoint **does not** return `403` for individual `revoked` items; it returns `200` with `decision='revoked'` per item. This lets the client cleanly process a mixed result without exception handling per item.

### Throttling

Apply existing `@nestjs/throttler` defaults. Realistic call rate is < 1 per minute per device on reconnect; no special bucket required.

### Swagger placement

`@ApiTags('Media')`; `@ApiOperation({ summary: 'Verify offline-download entitlements for a batch of media assets' })`; full `@ApiOkResponse` for `EntitlementVerificationResultDto`.

### Client contract (Flutter)

- Called by `OfflineEntitlementController` (Riverpod) on reconnect via `connectivity_observer`, on app resume, and lazily before any play attempt where `effective_now − last_verified_at` > 14 days.
- The client uses `serverTimestamp` to update `MonotonicClock` (resets the 14-day grace anchor).
- Per item: `allowed` → update `last_verified_*` fields, status stays `complete`; `revoked` → status → `revoked`, ciphertext deleted, row deleted; `superseded` → status stays `complete` but a "newer version available" banner appears in the lesson screen until the user re-downloads.

### Sample request/response

```http
POST /media/entitlement/verify
Authorization: Bearer <jwt>
Content-Type: application/json

{
  "items": [
    { "mediaId": "65f...", "lessonId": "65a...", "subjectId": "65b...", "knownContentVersion": "1714421000000" }
  ]
}
```

```json
{
  "serverTimestamp": "2026-04-30T14:22:01.000Z",
  "items": [
    {
      "mediaId": "65f...",
      "lessonId": "65a...",
      "decision": "allowed",
      "currentContentVersion": "1714421000000"
    }
  ]
}
```
