# Phase 1 — Data Model: Offline Mode

This document defines the new entities, the additive changes to existing entities, validation rules, and state transitions introduced by the offline-mode feature.

---

## 1. Server-side: MongoDB collections

### 1.1 `OfflineActiveDevice` (new collection: `offline_active_devices`)

Tracks the **single device per user** that currently holds offline downloads (the "active offline device"). This is **separate from** the existing `Device` schema in `back/src/devices/schemas/device.schema.ts`, which tracks the auth-bound device.

| Field | Type | Required | Notes |
|---|---|---|---|
| `_id` | `ObjectId` | yes | mongoose default |
| `userId` | `ObjectId` (ref `User`) | yes | unique index — one document per user |
| `deviceId` | `ObjectId` (ref `Device`) | yes | the `Device` currently designated as the offline-active device |
| `hardwareId` | `string` | yes | denormalized from `Device.hardwareId` for fast comparison without join |
| `claimedAt` | `Date` | yes | when this device became the active offline device |
| `lastVerifiedAt` | `Date` | yes | last successful entitlement-verify response sent to this device |
| `pendingWipe` | `boolean` | yes | `true` once a new device claims; the previous device, on next reconnect, must sync-then-wipe before this flips to a fresh active state |
| `previousDeviceId` | `ObjectId \| null` | optional | only set while `pendingWipe=true` for the *new* document; identifies which device must sync-then-wipe |
| `createdAt`, `updatedAt` | `Date` | yes | mongoose timestamps |

**Indexes**:
- `{ userId: 1 }` unique — guarantees at most one active offline device per user.

**State machine**:

```text
                    claim(deviceA)
       (no doc) ─────────────────────────► { deviceId=A, pendingWipe=false }
                                                     │
                                                     │ claim(deviceB)
                                                     ▼
                                          { deviceId=B, previousDeviceId=A,
                                            pendingWipe=true }
                                                     │
                                                     │ deviceA reconnects, syncs
                                                     │ progress, then confirms wipe
                                                     ▼
                                          { deviceId=B, previousDeviceId=null,
                                            pendingWipe=false }
                                                     │
                                                     │ release(deviceB) (e.g., user
                                                     │ taps "remove all downloads")
                                                     ▼
                                                  (doc deleted)
```

**Validation rules**:
- `userId` must match the authenticated user on every claim/release call.
- `deviceId` must reference a `Device` document that is currently active (`isActive=true`) for the same user — prevents claiming on a reset/inactive device record.
- `pendingWipe=true` implies `previousDeviceId != null` and vice versa; enforced at the service layer.

---

### 1.2 `Device` (existing — additive only)

Existing schema at `back/src/devices/schemas/device.schema.ts` is **not modified for behavior**. We add no required fields and change no defaults. Optional metadata may be added in a follow-up if needed.

(No diff in this feature.)

---

### 1.3 `LessonProgress` (existing — no schema change, only service-layer behavior)

The schema at `back/src/lesson-progress/schemas/lesson-progress.schema.ts` already has `watchedSeconds`, `durationSeconds`, `isCompleted`, `completedAt`, `lastWatchedAt`. We do not change the schema. The new behavior is service-layer:

- **Batch merge semantics**: Given `n` events for the same `(userId, lessonId)`, after merging, the stored document MUST satisfy:
  - `watchedSeconds = max(existing.watchedSeconds, max(incoming.watchedSeconds))`
  - `isCompleted = existing.isCompleted || any(incoming.isCompleted)`
  - `completedAt = earliest non-null among existing and any incoming whose isCompleted=true` (preserves first-completion timestamp)
  - `lastWatchedAt = max(existing.lastWatchedAt, max(incoming.lastWatchedAt))`
- **Idempotency**: Each incoming event carries a `clientEventId` (string, ULID-shaped). The service stores a small per-user ring buffer (in-memory or capped collection) of recently-seen `clientEventId`s and drops duplicates within a 7-day window. Older replays fall through to the merge logic, which is idempotent by construction.

**No new index required**; the existing `(userId, lessonId)` unique index is sufficient.

---

### 1.4 `MediaAsset` (existing — no schema change)

`MediaAsset` remains as-is. Entitlement is computed at request time via the existing `LessonsService.canAccessMediaContent(userId, subjectId, mediaId)` helper, which already enforces Activation Code + subject access. The new `POST /media/entitlement/verify` endpoint reuses this helper without touching the schema.

---

## 2. Client-side: Flutter local storage

### 2.1 Drift database schema (`offline.db`, app-private dir)

Three tables in one local SQLite database, accessed via Drift-generated DAOs. The DB file lives at `<getApplicationDocumentsDirectory()>/offline.db`.

#### Table `offline_downloads`

| Column | Type | Notes |
|---|---|---|
| `id` | `INTEGER PRIMARY KEY AUTOINCREMENT` | local row id |
| `lesson_id` | `TEXT NOT NULL UNIQUE` | server `Lesson._id`; one download per lesson |
| `subject_id` | `TEXT NOT NULL` | for the manage-downloads grouping |
| `media_id` | `TEXT NOT NULL` | server `MediaAsset._id` — drives entitlement-verify |
| `lesson_title` | `TEXT NOT NULL` | denormalized for the manage-downloads list |
| `course_title` | `TEXT NOT NULL` | denormalized |
| `bytes_downloaded` | `INTEGER NOT NULL` | for resume support |
| `bytes_total` | `INTEGER NOT NULL` | from `Content-Length` |
| `status` | `TEXT NOT NULL` | one of `queued`, `downloading`, `complete`, `failed`, `revoked`, `superseded`, `needs_reverify` |
| `quality` | `TEXT NOT NULL` | `standard` \| `high` |
| `iv_base64` | `TEXT NOT NULL` | per-file random 96-bit IV, base64 |
| `auth_tag_base64` | `TEXT` | AES-GCM auth tag, written when status=complete |
| `ciphertext_path` | `TEXT NOT NULL` | absolute path to the encrypted file on disk |
| `content_version` | `TEXT` | server-provided version id; if it changes, prompt re-download |
| `last_verified_at_wall` | `INTEGER` | milliseconds since epoch — wall clock at last successful verify |
| `last_verified_at_uptime` | `INTEGER` | monotonic uptime ms recorded at the same instant; together with current uptime gives tamper-resistant elapsed |
| `last_verified_boot_id` | `TEXT` | a stable id for the current boot session; if it changes, force re-verify before play |
| `downloaded_at_wall` | `INTEGER NOT NULL` | for the manage-downloads "downloaded on" column |
| `created_at_wall` | `INTEGER NOT NULL` | row creation |
| `updated_at_wall` | `INTEGER NOT NULL` | row update |

Indexes: unique on `lesson_id`; index on `subject_id`; index on `status`.

#### Table `pending_progress_events`

Buffer for offline-recorded progress that will be flushed via `POST /lesson-progress/batch` on reconnect.

| Column | Type | Notes |
|---|---|---|
| `id` | `INTEGER PRIMARY KEY AUTOINCREMENT` | local row id |
| `client_event_id` | `TEXT NOT NULL UNIQUE` | ULID; sent to server for dedup |
| `lesson_id` | `TEXT NOT NULL` | server `Lesson._id` |
| `subject_id` | `TEXT NOT NULL` | server `Subject._id` |
| `watched_seconds` | `INTEGER NOT NULL` | latest position observed offline |
| `is_completed` | `INTEGER NOT NULL` | 0/1 |
| `recorded_at_wall` | `INTEGER NOT NULL` | wall clock when recorded |
| `recorded_at_uptime` | `INTEGER NOT NULL` | monotonic uptime ms |
| `boot_id` | `TEXT NOT NULL` | boot session id at recording time |
| `created_at_wall` | `INTEGER NOT NULL` | row creation |

Indexes: unique on `client_event_id`; index on `lesson_id`.

**Drain semantics**: on reconnect, all rows are read in `(lesson_id, watched_seconds DESC)` order, batched per call (max 100 events / call), POSTed; on success, deleted. On failure, retain and retry with exponential backoff. A row is **never** deleted before its server-acknowledged write.

#### Table `cached_snapshot_blobs`

Holds the JSON snapshots that drive the offline cold-start experience (FR-010, FR-020). One row per logical "view" — courses list, lesson list per course, lesson text, profile.

| Column | Type | Notes |
|---|---|---|
| `key` | `TEXT PRIMARY KEY` | e.g., `enrolled_courses`, `lessons:<courseId>`, `lesson_text:<lessonId>`, `profile` |
| `payload_json` | `TEXT NOT NULL` | serialized JSON of the server response |
| `etag` | `TEXT` | optional, for conditional refresh when online |
| `refreshed_at_wall` | `INTEGER NOT NULL` | last refresh timestamp |

Refresh policy: opportunistic — every successful online navigation overwrites the matching key. The cache is best-effort; a missing key on cold-start renders an empty offline state (the spec accepts this; learners only see what they already loaded once).

---

### 2.2 Platform keystore items

Stored via `flutter_secure_storage` (Keychain on iOS, Android Keystore on Android):

| Key | Purpose |
|---|---|
| `offline.content_key` | The 256-bit AES-GCM content key used to encrypt all downloaded videos on this install. Generated on first download; never rotated automatically; cleared on full sign-out (which also wipes downloads). |
| `offline.boot_id` | A stable id for the current boot session, regenerated when the OS reports a reboot (detected via `device_info_plus` boot time delta). Used to invalidate `last_verified_at_uptime` reasoning across reboots. |

---

## 3. State transitions for `OfflineDownload` (client-side row in `offline_downloads`)

```text
                  user taps "Download"
   (no row) ─────────────────────────────► queued
                                              │
                                              │ network worker picks up
                                              ▼
                                         downloading
                                              │
            ┌───────────── failed ◄───────────┤
            │                                 │
            │ user retries                    │ all bytes received,
            │                                 │ AES-GCM finalizes
            ▼                                 ▼
         queued                            complete
                                              │
                              ┌───────────────┼─────────────────┐
                              │               │                 │
                user taps     │   server      │   14d offline   │   another device
                "Remove"      │   says        │   elapsed       │   claimed offline
                              │   revoked     │                 │
                              ▼               ▼                 ▼
                          (deleted)        revoked         needs_reverify  superseded
                                              │                 │                 │
                                              │ next reconnect  │ next online +   │ next reconnect:
                                              │ wipes ciphertext│ verify resets   │ sync-then-wipe
                                              ▼                 │ to complete     ▼
                                          (deleted)             │                 (deleted)
                                                                │
                                                                ▼
                                                            complete
```

**Invariants**:
- A row is `complete` iff `bytes_downloaded == bytes_total` and `auth_tag_base64` is not null.
- A `revoked` or `superseded` row's ciphertext file MUST be deleted before the row itself is deleted; deletion order is recorded so a crash mid-cleanup doesn't leak orphan ciphertext.
- `needs_reverify` blocks playback at the player layer; the row stays on disk and is recoverable on next successful verify.

---

## 4. Validation rules summary

| Rule | Where enforced |
|---|---|
| One `OfflineActiveDevice` per user | unique index + service-layer guard |
| `claim` requires authenticated user; targeted device must be `Device.isActive=true` | service guard |
| `release` is idempotent (no error if no doc) | service guard |
| `pendingWipe=true` ⇒ `previousDeviceId != null` | service guard |
| Batch progress event idempotency by `clientEventId` | service guard + DB ring-buffer |
| `POST /lesson-progress/batch` payload max 100 events / call | DTO `@ArrayMaxSize(100)` |
| Each download row's `bytes_total` matches `Content-Length` from server | client guard |
| AES-GCM auth tag must verify on every play; mismatch ⇒ row → `failed`, ciphertext deleted | client guard |
| 14-day grace check on every play attempt | `OfflinePlayerGuard` (Flutter) |

---

## 5. Relationships at a glance

```text
   ┌──────────┐   1     1   ┌────────────────────────┐
   │   User   │◄────────────┤  OfflineActiveDevice   │ (server)
   └──────────┘             └────────────────────────┘
        │ 1                          │ 1
        │                            │
        │ N                          │ N
   ┌──────────┐               ┌──────────────┐
   │  Device  │               │  Device      │ (referenced by deviceId/previousDeviceId)
   └──────────┘               └──────────────┘

   ┌──────────────────┐  N      1   ┌────────┐
   │ LessonProgress   │◄────────────┤  User  │ (server, existing)
   └──────────────────┘             └────────┘

   --- client-side (na_app local SQLite) ---
   ┌────────────────────┐    1     N    ┌──────────────────────────┐
   │ offline_downloads  │───────────────│ pending_progress_events  │ (loose ref by lesson_id)
   └────────────────────┘               └──────────────────────────┘
   ┌──────────────────────┐
   │ cached_snapshot_blobs│ (KV by key)
   └──────────────────────┘
```
