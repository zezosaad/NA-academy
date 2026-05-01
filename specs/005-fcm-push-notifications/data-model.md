# Phase 1 Data Model — Push Notifications & In-App Inbox

**Date**: 2026-05-01
**Feature**: `005-fcm-push-notifications`
**Companion**: [spec.md](./spec.md), [plan.md](./plan.md), [research.md](./research.md)

This document defines the canonical entities, fields, indexes, and lifecycle rules introduced by this feature. The server side is the source of truth (Constitution Principle IV); client-side caches mirror these shapes.

---

## Server (MongoDB / Mongoose)

### 1. `notifications` collection — `Notification`

One document per send. Retained **indefinitely** (FR-029).

| Field | Type | Required | Description |
|---|---|---|---|
| `_id` | `ObjectId` | yes | Mongo-generated. The notification's stable identifier across surfaces. |
| `title` | `string` | yes | 1–100 chars. Plaintext, no markdown. Surfaces in OS push alert title. |
| `body` | `string` | yes | 1–1000 chars. Plaintext. Surfaces in OS push alert body and inbox. |
| `data` | `Record<string, string>` | no | Optional structured payload, all values cast to string (FCM `data:` requires strings). Schema for known keys defined below. |
| `senderId` | `ObjectId` (ref `User`) | yes | The admin or teacher who sent this. |
| `senderRole` | `enum: 'admin' \| 'teacher'` | yes | Snapshotted at send time; useful for auditing if a user's role later changes. |
| `audience` | `AudienceDescriptor` | yes | See sub-document below. Frozen at send time. |
| `idempotencyKey` | `string` | yes | UUID v4 supplied by client; (`senderId` + `idempotencyKey`) is uniquely indexed. |
| `stats` | `NotificationStats` | yes | Aggregate counts; updated as per-recipient state changes. See sub-document. |
| `createdAt` | `Date` | yes | Mongoose timestamp. The notification's send time. |
| `updatedAt` | `Date` | yes | Mongoose timestamp. |

#### Sub-document: `AudienceDescriptor`

| Field | Type | When |
|---|---|---|
| `kind` | `enum: 'all' \| 'user-list' \| 'subject'` | always |
| `userIds` | `ObjectId[]` | only when `kind === 'user-list'` |
| `subjectId` | `ObjectId` (ref `Subject`) | only when `kind === 'subject'` |
| `resolvedUserIds` | `ObjectId[]` | always — the snapshot of every user this notification was actually targeted at |
| `resolvedRecipientCount` | `number` | always — `resolvedUserIds.length` denormalized for fast list rendering |

#### Sub-document: `NotificationStats`

| Field | Type | Description |
|---|---|---|
| `total` | `number` | Equals `audience.resolvedRecipientCount`. |
| `delivered` | `number` | Count of `NotificationRecipient` rows in state `delivered`. |
| `failed` | `number` | Count in state `failed`. |
| `read` | `number` | Count with `readAt != null`. |

#### Indexes

- `{ senderId: 1, idempotencyKey: 1 }` **unique** — enforces FR-007 idempotency.
- `{ createdAt: -1 }` — supports the dashboard history list (reverse-chrono pagination).
- `{ "audience.kind": 1, "audience.subjectId": 1, createdAt: -1 }` — supports "show all notifications I, as a teacher, sent for this subject".
- `{ title: 'text', body: 'text' }` — supports keyword search in history (FR-027).

#### Validation rules (DTO + schema)

- `title.length ∈ [1, 100]`, trimmed.
- `body.length ∈ [1, 1000]`, trimmed.
- `data` keys must match `/^[a-zA-Z][a-zA-Z0-9_]{0,31}$/` (FCM data-key constraint; we tighten further to match our codebase conventions).
- `data` values are all strings; total payload (keys + values) ≤ 4 KB to leave headroom under FCM's 4 KB limit.
- `audience.kind = 'user-list'` ⇒ `userIds.length ∈ [1, 1000]` (above 1000, the admin should use a `subject` or `all` audience).
- `audience.kind = 'subject'` ⇒ `subjectId` exists and the sender is authorized for it (admin always; teacher only if `Subject.createdBy === senderId`).
- Body MUST NOT match a regex of common credential patterns (OTP-like, JWT-like, common secret prefixes); the validator emits a `ForbiddenException` if it does (FR-033 hardening).

---

### 2. `notification_recipients` collection — `NotificationRecipient`

One document per (notification, target user). Auto-pruned **365 days** after the parent notification's `createdAt` (FR-029).

| Field | Type | Required | Description |
|---|---|---|---|
| `_id` | `ObjectId` | yes | |
| `notificationId` | `ObjectId` (ref `Notification`) | yes | |
| `userId` | `ObjectId` (ref `User`) | yes | The recipient. |
| `state` | `enum: 'pending' \| 'delivered' \| 'failed'` | yes | Initial value `pending` (set during fan-out). |
| `failureReason` | `string` | no | FCM error code mapped to a stable string when `state = 'failed'` — e.g., `unregistered`, `invalid-token`, `quota-exceeded`, `unknown`. |
| `pushTokenId` | `ObjectId` (ref `PushToken`) | no | The token that was used for the send attempt; null if the user had no active token (state = `failed`, reason = `no-active-token`). |
| `deliveredAt` | `Date` | no | Set when FCM accepts the message. |
| `readAt` | `Date` | no | Set when the user opens the notification on any device. Triggers a recompute of `Notification.stats.read`. |
| `createdAt` | `Date` | yes | Mongoose timestamp. |
| `updatedAt` | `Date` | yes | Mongoose timestamp. |

#### Indexes

- `{ notificationId: 1, userId: 1 }` **unique** — one row per recipient per notification.
- `{ userId: 1, createdAt: -1 }` — primary index for `GET /notifications/me` (the inbox list).
- `{ userId: 1, readAt: 1 }` — fast unread-count queries.
- `{ createdAt: 1 }` — used by the daily retention sweep (`createdAt < now - 365d`).

#### State transitions

```text
                    +-------------+
                    |  pending    |
                    +------+------+
                           |
              FCM accept   |   FCM reject (terminal)
              ↙            |            ↘
       +-----------+               +-----------+
       | delivered |               |  failed   |
       +----+------+               +-----------+
            |
   user opens (any device)
            ↓
        readAt set
```

`failed` is terminal — no retries on the server side (FCM has its own retry mechanism for transient errors before reporting back). `delivered → failed` and `readAt → null` are not allowed transitions.

---

### 3. `push_tokens` collection — `PushToken`

One document per registered FCM token. Lifecycle is independent of `Device` but coordinates with it.

| Field | Type | Required | Description |
|---|---|---|---|
| `_id` | `ObjectId` | yes | |
| `userId` | `ObjectId` (ref `User`) | yes | The owning account. |
| `token` | `string` | yes | The opaque FCM token string. Hashed for index lookup but stored in cleartext (FCM expects cleartext on send). |
| `tokenHash` | `string` | yes | SHA-256 of `token`; uniquely indexed; used for upsert-on-rotate. |
| `platform` | `enum: 'ios' \| 'android'` | yes | Reported by client. Drives APNs vs Android channel selection if needed in future. |
| `deviceId` | `ObjectId` (ref `Device`) | no | The hardware-bound device this token belongs to, when known. Allows the device-reset flow to find and tombstone the token. |
| `appVersion` | `string` | no | Reported at registration; useful for diagnostics. |
| `lastSeenAt` | `Date` | yes | Updated on every successful refresh. |
| `tombstonedAt` | `Date` | no | When set, the token is no longer used for delivery. Tombstoned rows are auto-deleted 30 days after `tombstonedAt`. |
| `createdAt` | `Date` | yes | Mongoose timestamp. |
| `updatedAt` | `Date` | yes | Mongoose timestamp. |

#### Invariants

- **At most one** active (non-tombstoned) `PushToken` per `userId` at any time. Enforced by a partial unique index: `{ userId: 1 }` **unique** with filter `{ tombstonedAt: { $exists: false } }`.
- When a new token is registered for a user with an existing active token, the existing one is set `tombstonedAt = now()` in the same `findOneAndUpdate` operation as the upsert of the new one (using a small transaction or a two-step write inside the same service method).
- When `DevicesService.resetDevice(userId)` runs, it MUST also tombstone the user's active push token (cross-module call into `PushTokensService.tombstoneActiveForUser(userId)`).

#### Indexes

- `{ tokenHash: 1 }` **unique** — supports upsert-by-token (rotate-in-place).
- `{ userId: 1 }` **unique** with partial filter `{ tombstonedAt: { $exists: false } }` — enforces single-active invariant.
- `{ tombstonedAt: 1 }` — sweeper finds rows older than 30d.

---

## Data integrity rules

1. **Audience snapshot is immutable.** Once a `Notification` is written, its `audience.resolvedUserIds` is never modified. Late enrollments do not retroactively receive past notifications (Decision 9 in `research.md`).
2. **No stale per-recipient writes.** A `NotificationRecipient` row is only inserted at send time. If a sweep finds orphaned rows (notification deleted but rows remain), they are removed. (Notifications are not deleted in v1, so this is a defensive guard.)
3. **One source of truth for "read"**. Read state lives only on `NotificationRecipient.readAt`. The `Notification.stats.read` aggregate is denormalized for read-heavy queries and updated by the same service method that flips `readAt`.
4. **Soft-archived recipient view.** When the retention sweep prunes `NotificationRecipient` rows older than 365 days, the parent `Notification.stats` is **frozen** — the existing aggregate counts (delivered / failed / read) remain in the document and are returned by the history detail view, but the per-recipient list endpoint returns `{ archived: true, archivedAt: <prune timestamp> }` instead of an empty list.

---

## Client-side cache (Flutter `na_app/`, `drift` SQLite)

Two new tables, on top of the existing `drift` DB introduced in 004.

### Table `notifications_inbox`

| Column | Type | Notes |
|---|---|---|
| `id` | `TEXT PRIMARY KEY` | Mirrors `Notification._id` as hex string. |
| `title` | `TEXT NOT NULL` | |
| `body` | `TEXT NOT NULL` | |
| `data` | `TEXT` | JSON-encoded, may be null. |
| `senderName` | `TEXT` | Human-readable; cached for display when offline. |
| `createdAt` | `INTEGER NOT NULL` | Unix millis. |
| `readAt` | `INTEGER` | Unix millis or null. |
| `lastSyncedAt` | `INTEGER NOT NULL` | When this row was last refreshed from the server. |

Index: `(readAt IS NULL, createdAt DESC)` for fast inbox list / unread count.

### Table `notifications_unread_index`

A single-row table holding the cached unread count. Updated by triggers in code whenever `readAt` is set / a new row is inserted. The home-screen bell-icon badge reads from this.

| Column | Type |
|---|---|
| `id` | `INTEGER PRIMARY KEY CHECK (id = 1)` |
| `count` | `INTEGER NOT NULL DEFAULT 0` |

### Sync protocol

- **On app launch (online)**: `GET /notifications/me?since=<lastSyncedAtMax>&limit=50`. Upsert by `id`. Recompute the unread count from a single SQL aggregate.
- **On push arrival (foreground / background isolate)**: insert or update the row immediately from the FCM payload. `lastSyncedAt = now()`.
- **On user opening the inbox (online)**: refresh as in launch.
- **On user marking-as-read**: optimistic update locally; `PATCH /notifications/:id/read` queued through the existing pending-sync infrastructure from 004 if offline.

The sync protocol is intentionally similar to 004's offline-progress queue so the existing patterns are reused (constitution Principle IV — consistent multi-feature shape).

---

## Migration plan

Backend (Mongoose) — no breaking changes to existing collections. The new collections are introduced cleanly. The `Device` schema is **not modified**; only `DevicesService.resetDevice` gains an extra cross-module call.

Flutter (`drift`) — one schema-version bump on the existing DB. The migration adds the two new tables; no existing data is touched.

Admin dashboard — no schema concerns; the dashboard is purely client-of-API.
