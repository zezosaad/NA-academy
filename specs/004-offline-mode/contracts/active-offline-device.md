# Contract: Active Offline Device (claim / status / release)

Owns FR-012a, FR-012b, FR-012c, FR-012d — the single-active-offline-device tracking that makes the sync-then-wipe handoff possible.

The new `OfflineActiveDevice` collection is documented in `data-model.md §1.1`.

---

## `POST /devices/offline/claim`

Idempotent. Called by the Flutter client the first time it starts a download on this device, or after the user taps "make this my offline device" on a manage-downloads screen. Causes any other device's offline downloads to enter `pendingWipe=true` so they self-destruct sync-then-wipe on next reconnect.

### Request

```ts
// back/src/devices/dto/claim-active-offline-device.dto.ts
class ClaimActiveOfflineDeviceDto {
  @IsMongoId()
  deviceId!: string;     // must equal the caller's currently-active Device._id
}
```

### Response

```ts
class ClaimActiveOfflineDeviceResultDto {
  status!: 'claimed' | 'already_active';
  previousDeviceId?: string;       // present when status='claimed' and there was a prior active offline device
  serverTimestamp!: string;         // ISO 8601, UTC
}
```

### Auth

- `@ApiBearerAuth()`, `@Roles('student', 'teacher')`.
- The `deviceId` MUST belong to the authenticated user and be `Device.isActive=true` (existing schema).

### Service contract

`DevicesService.claimOfflineActive(userId, deviceId)`:

1. Verify `Device` exists, is owned by `userId`, and is `isActive=true` (otherwise `403`).
2. Upsert `OfflineActiveDevice` for this `userId`:
   - If no doc: insert `{ userId, deviceId, hardwareId, claimedAt: now, lastVerifiedAt: now, pendingWipe: false }`. Return `claimed`.
   - If doc exists with `deviceId == new`: refresh `lastVerifiedAt`, return `already_active`.
   - If doc exists with different `deviceId`: set `previousDeviceId = current.deviceId`, then overwrite `deviceId`, `hardwareId`, `claimedAt = now`, `pendingWipe = true`. Return `claimed` with `previousDeviceId`.

### Errors

- `400 Bad Request` — DTO invalid.
- `401 Unauthorized`.
- `403 Forbidden` — `deviceId` not owned by user or not `isActive`.

---

## `GET /devices/offline/status`

Lightweight call used on every reconnect by **all** devices to detect "am I still the active offline device?" — drives the sync-then-wipe flow on a deactivated device.

### Response

```ts
class OfflineDeviceStatusDto {
  isActiveOfflineDevice!: boolean;
  pendingWipeForThisDevice!: boolean;   // true ⇒ this device is the previous one and must sync-then-wipe
  serverTimestamp!: string;
}
```

### Service contract

`DevicesService.statusForCallingDevice(userId, deviceId)`:

- If no `OfflineActiveDevice` doc exists for the user → `{ isActiveOfflineDevice: false, pendingWipeForThisDevice: false }`.
- If doc's `deviceId == calling`: `isActiveOfflineDevice = true`, `pendingWipeForThisDevice = false`. Refresh `lastVerifiedAt`.
- If doc's `previousDeviceId == calling` (i.e., we are the deactivated previous device): `isActiveOfflineDevice = false`, `pendingWipeForThisDevice = true`.
- Otherwise: `isActiveOfflineDevice = false`, `pendingWipeForThisDevice = false` (this device never held offline downloads).

The `deviceId` is **derived from the caller's request context** (e.g., a header or the JWT's bound device claim), not passed in the URL — adjust to match how `back/` already identifies the calling device. If there is no existing convention, accept `deviceId` as a `@Query` parameter validated by `@IsMongoId()` and verified to belong to the authenticated user.

### Auth

`@ApiBearerAuth()`, `@Roles('student', 'teacher')`.

---

## `POST /devices/offline/release`

Called by the deactivated previous device after it has finished its sync-then-wipe sequence. Tells the server "I have flushed my pending progress, I have deleted my ciphertext; please clear `previousDeviceId` and `pendingWipe` for the new active device."

### Request

```ts
class ReleaseOfflineDeviceDto {
  @IsMongoId()
  deviceId!: string;     // must equal the caller's currently-active Device._id
}
```

### Response

```ts
class ReleaseOfflineDeviceResultDto {
  status!: 'released' | 'not_in_pending_wipe';
  serverTimestamp!: string;
}
```

### Service contract

`DevicesService.releasePreviousOffline(userId, deviceId)`:

- Find the `OfflineActiveDevice` doc for this user.
- If `pendingWipe == true && previousDeviceId == deviceId`:
  - Set `previousDeviceId = null`, `pendingWipe = false`. Return `released`.
- Otherwise: return `not_in_pending_wipe` (idempotent — the new device may have already moved on, or another release call already won the race).

### Auth

`@ApiBearerAuth()`, `@Roles('student', 'teacher')`.

---

## Sequence: device handoff (sync-then-wipe)

```text
Device A (was active offline)                              Device B (newly downloading)
     │                                                              │
     │                       (offline)                               │
     │                                                              │
     │                                       POST /devices/offline/claim
     │                                       { deviceId: B }
     │                                                              │
     │                                       ◄── 200 { status:'claimed', previousDeviceId: A }
     │                                                              │
     │                                       (B starts downloading)
     │                                                              │
     │ network returns                                              │
     │                                                              │
     │ GET /devices/offline/status ──────────►                      │
     │ ◄── 200 { isActiveOfflineDevice:false, pendingWipeForThisDevice:true }
     │                                                              │
     │ POST /lesson-progress/batch  (drain pending_progress_events) │
     │ ◄── 200 { acceptedClientEventIds:[...] }                     │
     │                                                              │
     │ (delete local ciphertext, show notification)                 │
     │                                                              │
     │ POST /devices/offline/release ────────►                      │
     │ ◄── 200 { status:'released' }                                │
     │                                                              │
     │ (offline_downloads on Device A is now empty)                 │
     │                                                              │
```

If either of the last two POSTs fails, the deactivated device retries with backoff. **Local ciphertext deletion is gated on a successful progress flush** — so progress is never lost, even if the user closes the app mid-handoff (FR-012d).

---

## Errors common to all three endpoints

- `401 Unauthorized` — missing/invalid JWT.
- `403 Forbidden` — `deviceId` does not belong to the authenticated user or is `Device.isActive=false`.

---

## Swagger placement

`@ApiTags('Devices')` on a new `DevicesController` (or extension of an existing one), with each endpoint having `@ApiOperation` summaries:
- `claim`: "Claim this device as the user's active offline-downloads device."
- `status`: "Report whether this device is currently the active offline-downloads device."
- `release`: "Confirm sync-then-wipe completion on a deactivated previous device."
