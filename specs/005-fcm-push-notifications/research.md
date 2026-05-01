# Phase 0 Research — Push Notifications & In-App Inbox (FCM)

**Date**: 2026-05-01
**Feature**: `005-fcm-push-notifications`
**Companion**: [spec.md](./spec.md), [plan.md](./plan.md)

This document resolves the cross-cutting decisions that the spec and plan deliberately deferred. Each decision lists what was chosen, why, and the alternatives considered.

---

## Decision 1 — Active mobile surface: Flutter `na_app/`, not Expo `front/`

**Decision**: Implement the FCM client in the Flutter app (`na_app/`) only. The Expo app (`front/`) is **not** modified in v1.

**Rationale**:

- The user explicitly chose Flutter in the feature input ("Mobile integration example (Flutter preferred)").
- Recent feature work in this repo (003-mobile-app-redesign and 004-offline-mode) targeted `na_app/` exclusively, establishing precedent that the Flutter app is the active student-facing surface.
- `na_app/` already integrates the relevant infrastructure for an inbox: `drift` SQLite (introduced in 004 for offline storage), `flutter_riverpod`, `go_router`, `easy_localization`, `flutter_secure_storage`. Adding `firebase_messaging` here is the smallest integration delta; doing it in Expo would require a parallel rebuild of the same client logic.
- Constitution Principle V designates Expo as the "flagship surface" but does not forbid feature work landing in another mobile surface first; 004's surface scope is the precedent we follow.

**Alternatives considered**:

- *Both surfaces simultaneously*: Doubles the implementation cost, requires a second platform-config setup (separate Firebase iOS/Android app entries), and the Expo app is currently behind on other features. Defer to a follow-up feature once `front/` parity is on the roadmap.
- *Expo only*: Contradicts the explicit Flutter request and abandons the inbox storage already paid for by 004's `drift` integration.

**Implication**: Expo `front/` parity is a follow-up feature. We will register a TODO in `na_app/`'s `core/notifications/firebase_bootstrap.dart` referencing this gap so it is rediscovered when parity work begins.

---

## Decision 2 — Server SDK: `firebase-admin` against the v1 HTTP API

**Decision**: Use the official `firebase-admin` Node SDK (v12+) and call `messaging().sendEachForMulticast()` (or `sendEach()` for ≤500 tokens at a time) for fan-out. No legacy server keys; service-account auth only.

**Rationale**:

- The legacy FCM HTTP API (server keys) is deprecated by Google as of 2024-06-20; only the v1 API (OAuth 2.0 service-account access tokens) is supported. `firebase-admin` handles token minting, refresh, and request signing automatically.
- The SDK supports per-token error reporting: each entry in the `BatchResponse.responses[]` array carries a `success: boolean` and an `error.code` (e.g., `messaging/registration-token-not-registered`, `messaging/invalid-argument`). We map this directly onto our `NotificationRecipient` row's `failureReason` field.
- The SDK supports both the `multicast` shape (one message → many tokens, capped at 500/call) and `topic` (broadcast). We deliberately use multicast even for "all users" sends so per-recipient state is recordable; topics give us no per-user delivery state.
- `firebase-admin` is the same SDK used by virtually every Node-on-FCM tutorial and is well-maintained.

**Alternatives considered**:

- *Topic-based "all users" send*: Cheaper at scale (one HTTP call) but loses per-recipient state, and requires every device to subscribe to the topic at boot. Rejected: per-recipient delivery tracking is in the spec (FR-011) and is the basis of SC-005, SC-007, and the history detail view. We can revisit topics for very-large-broadcast efficiency in a future optimization without changing the spec.
- *Direct HTTP calls without the SDK*: Forces us to implement OAuth 2.0 token exchange, retry logic, and error parsing ourselves. No upside.
- *A third-party push aggregator (e.g., OneSignal, Pusher)*: Requires an extra vendor account, an extra contract, and extra failure modes for no marginal value over FCM-direct in our setup.

---

## Decision 3 — "Course" vs "Subject" terminology

**Decision**: At the **wire and storage layer**, the audience kind for groups is named `"subject"` and references the existing `Subject` collection (the canonical academic-content entity in this codebase). At the **user-facing layer** (composer label, inbox metadata pill), we keep the natural-language word the user reads ("Subject" since `Subject` is what NA-Academy calls a course-like unit; the dashboard already has a "Subjects" page).

**Rationale**:

- The spec was written in generic ed-tech vocabulary ("course") because that's the most common term across academies. The codebase reality is that NA-Academy already models the same concept under the `Subject` entity (with `category`, `level`, `createdBy`, and `assignedSubjects` on `User`).
- Aligning the contract with the existing entity name avoids spawning a parallel "Course" model that would be a synonym for `Subject` — a clear violation of constitution Principle IV (single source of truth) and a future maintenance trap.
- The dashboard navigation already calls this entity "Subjects". Calling the targeting axis "Subject" in the composer is consistent with what admins already see.

**Alternatives considered**:

- *Introduce a new `Course` entity that wraps `Subject`*: Wholly redundant. Rejected — explicit constitution violation.
- *Use `"course"` as the wire enum, with a comment that it maps to Subject*: Lying to the API consumer. Rejected.
- *Rename `Subject` → `Course` repo-wide*: Way out of scope of this feature.

**Implication**: Spec text under `## Clarifications` and the user stories use the word "course" because that's the language the user spoke; this is preserved verbatim. The `data-model.md`, `contracts/`, schemas, controller, DTO, and admin dashboard label use "Subject". One sentence in `quickstart.md` calls out the bridge so a reader who came in via the spec is not surprised.

---

## Decision 4 — Push token model: separate from `Device` schema

**Decision**: Introduce a new `push_tokens` collection. The existing `devices` collection is unchanged in shape. The two are **linked** but **independent** — a device-binding event (registration / reset / handoff) cascades to a push-token tombstoning, but the FCM token itself lives in its own row.

**Rationale**:

- `Device` is a *security* primitive (one hardware ID per account, used to detect account sharing). Its `hardwareId` is platform-derived and stable. FCM tokens are *delivery* primitives — they rotate (Google rotates them silently for various reasons), they are 200+ characters of opaque base64, and they have no security meaning by themselves.
- Mixing the two would require either widening `Device.hardwareId` to also store rotating tokens (which breaks the device-mismatch detection that 003/004 depend on) or stuffing FCM tokens into a side field on `Device` (which fails when the OS rotates the FCM token without changing the hardware).
- A separate `push_tokens` collection lets us index by `userId` for fast send-fan-out and by `tokenHash` for upsert-by-rotation, without touching the `devices` collection's hot path.

**Concurrency rule**:

- One **active** push token per user at a time (consistent with the single-device-binding rule). When a new token is registered for the same user, the prior active token is marked `tombstonedAt = now()` in the same write. Tombstoned tokens are kept for 30 days for diagnostic purposes, then deleted by the same retention cron.

**Alternatives considered**:

- *Embed `pushToken` field on `Device`*: rejected as above.
- *Embed array of tokens on `User`*: same problem; user document becomes hot for every push send.
- *Allow multiple active tokens per user*: contradicts the existing single-device-binding rule, and the spec's multi-device edge case is already scoped down by the constraint section of the plan.

---

## Decision 5 — RBAC enforcement strategy

**Decision**: Reuse the existing `RolesGuard` in `back/src/common/guards/`. Augment the controller with a `@Roles(UserRole.ADMIN, UserRole.TEACHER)` decorator for `POST /notifications`. **Audience-level** authorization (teacher can only target subjects they own) is enforced **inside the service** during audience resolution: the resolver loads the requested subject, checks `subject.createdBy === currentUser._id` for the teacher path, and rejects with `ForbiddenException` if not.

**Rationale**:

- Layer-1 (`@Roles`) prevents unauthorized roles (e.g., `student`) from reaching the controller at all — the cheap, declarative check.
- Layer-2 (audience check inside the service) is the *only* place that has the resolved audience identity (subject id) in hand and can compare it to the current user. Doing it in a guard would require the guard to parse the request body, which mixes concerns and bypasses DTO validation.
- This is the same two-layer pattern already used by `back/src/exams/` (role decorator at controller, ownership check at service).

**Alternatives considered**:

- *CASL or similar policy library*: more machinery than this feature warrants; we have one role transition (admin vs teacher) and one ownership rule.
- *A new "send-permissions" guard*: would require a custom factory provider per audience kind. Disproportionate.

---

## Decision 6 — Idempotency for send submissions

**Decision**: The `POST /notifications` endpoint accepts an `Idempotency-Key` header (UUID). The service writes the resolved `Notification` document with that key as a unique index; if the index hits a duplicate, the service returns the previously-created notification's response unchanged (200 OK with the original ID), without re-fanning-out to FCM.

**Rationale**:

- The dashboard's "Send" button could be double-clicked, the network could retry on a transient 5xx, etc. Without idempotency the spec's FR-007 requirement ("send submission MUST be idempotent") is impossible to satisfy.
- A unique index on `(senderId, idempotencyKey)` is the simplest correct implementation and costs us one Mongoose index.
- Keys are generated client-side (the dashboard's `react-hook-form` submit handler creates a UUID v4 the first time the user clicks Send, and reuses it for any retries).

**Alternatives considered**:

- *Server-only deduplication by hashing (sender, audience, title, body)*: false positives when an admin legitimately sends the same announcement twice. Rejected.
- *No idempotency at all*: violates FR-007.

---

## Decision 7 — Inbox storage on mobile: extend the existing `drift` DB

**Decision**: Add two tables to the existing `drift` SQLite database 004 introduced — `notifications_inbox` (one row per cached server notification) and `notifications_unread_index` (a single-row denormalized count per user, kept in sync via triggers in code). No new database file.

**Rationale**:

- 004 already paid the cost of a `drift` migration step. Adding one migration on top is essentially free.
- The inbox needs offline reads (FR-019) and the same DB already supports that pattern for downloaded videos and pending progress.
- A single counter row gives us O(1) badge updates instead of `COUNT(*)` on every home-screen render.

**Alternatives considered**:

- *Hive / shared_preferences / a new SQLite file*: another migration story to maintain. Rejected.
- *In-memory cache only, refetch from server on every open*: violates FR-019 (inbox MUST work offline).

---

## Decision 8 — Foreground notification UX: in-app banner, not a system banner

**Decision**: When the app is in the foreground, suppress the OS-level notification banner (`firebase_messaging` does this by default on Android; on iOS we explicitly return `presentationOptions: []` from the foreground delegate) and instead render an **in-app parchment-palette banner** at the top of the current screen via `flutter_local_notifications`-rendered overlay or a custom `OverlayEntry`. The banner shows title + body and auto-dismisses after 5 s, or until tapped.

**Rationale**:

- A duplicate OS banner stacked on top of the user's current screen is jarring and breaks the spec's acceptance scenario US1#3 ("…without disrupting their current screen with a system banner duplicate").
- The in-app banner can use the parchment palette and Fraunces/Inter typography, satisfying constitution Principle I (no generic-SaaS notification toast).
- `prefers-reduced-motion`: when the OS reports reduced-motion, the banner appears with a fade-only (no slide), consistent with Principle V.

**Alternatives considered**:

- *Just let the OS banner show*: jarring + off-brand.
- *Silently update the inbox without any visible cue*: the user doesn't realize a new message has arrived if their app is currently open.

---

## Decision 9 — Audience snapshot vs live evaluation

**Decision**: When a notification is sent to a `subject` audience, the audience-resolver expands the subject to its current enrolled-students list **at send time** and snapshots the resolved user IDs into the `Notification.audience.resolvedUserIds` field. Future `NotificationRecipient` rows are written exactly for those IDs, regardless of subsequent enrollment changes.

**Rationale**:

- A student who unenrolls between send and delivery should still receive the message (it was already on its way to them). A student who enrolls after the send shouldn't suddenly start seeing an old announcement.
- Snapshotting also makes the history view auditable: "who got this message" is a frozen answer, not a live re-query.
- Snapshot size is bounded — a single subject typically has hundreds of students, not hundreds of thousands.

**Alternatives considered**:

- *Live re-evaluation on every recipient query*: makes "delivered count" meaningless (it would change as enrollments change). Rejected.

---

## Best-practice notes (consolidated)

- **Service-account file**: deploy via secret manager; mount as a file at a path declared in `FIREBASE_SERVICE_ACCOUNT_PATH`, or pass the JSON in `FIREBASE_SERVICE_ACCOUNT_JSON`. Backend chooses between the two on boot. Both paths are covered by `back/src/config/configuration.ts` extensions.
- **APNs key**: configure once in the Firebase console (iOS app entry), no backend code change. Document in `quickstart.md`.
- **Android channel**: `flutter_local_notifications` requires a named channel on Android 8+. We register `na_academy_default` with importance `high` at app boot.
- **iOS provisional authorization**: skip — we explicitly request `alert + badge + sound` so the user sees the OS prompt. Provisional (silent) authorization is a UX trap for an academy app where students need to actively opt in.
- **Token rotation**: subscribe to `FirebaseMessaging.instance.onTokenRefresh` and call `PATCH /me/push-tokens/:id` from `push_token_registrar.dart`. The backend treats this as "tombstone old, insert new" atomically.
- **Background isolate**: the top-level `_firebaseMessagingBackgroundHandler` function in `push_message_handler.dart` is registered before `runApp()` per the `firebase_messaging` requirement. It performs a single `drift` upsert into `notifications_inbox` and exits.
- **Deep-link payload schema**: `data: { type: "exam" | "subject" | "lesson" | "url", id?: string, url?: string }`. Documented in `contracts/notifications.md`.
- **Logging**: `logger` (existing dep) used on the Flutter side for all FCM lifecycle events, gated to non-release builds. Server-side, a new `notifications.send` audit log row is written via the existing logging interceptor.

---

## Open follow-ups (out of scope for v1)

These are explicitly deferred and tracked here so they aren't lost:

1. **Expo `front/` parity** — ship the same client logic on the Expo app. New feature, not a sub-task of this one.
2. **Web push for the admin dashboard itself** — admins receiving notifications about, e.g., student help requests. Not in this spec.
3. **Topic-based broadcast optimization** — replace multicast with FCM topics for very-large all-users sends once we exceed ~50,000 users.
4. **Per-category preferences in the mobile app** — currently a single global on/off. Wait until users actually ask.
5. **Scheduled / recurring sends** — admins compose now-but-deliver-later. Deferred.
6. **Rich media (images, action buttons)** — deferred.
