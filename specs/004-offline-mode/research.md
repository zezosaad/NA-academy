# Phase 0 — Research & Decisions: Offline Mode

This document resolves the open questions surfaced during planning and records the rationale behind each decision so downstream work (`/speckit.tasks`, implementation reviews) can rely on a single source of truth.

---

## Decision 1 — Active mobile surface: Flutter `na_app/`, not Expo `front/`

**Decision**: Implement v1 of offline mode in `na_app/` (Flutter). Do not modify `front/` (Expo) for this feature.

**Rationale**:
- The most recent feature branch (`003-mobile-app-redesign`) lived almost entirely in `na_app/`, including a redesign of the chat, exams, lessons, home, and onboarding modules. The active development surface for student-facing mobile work is Flutter today.
- The Expo `front/` codebase still exists, but recent commits show only narrowly-scoped chat-feature work there. Doubling the offline-mode build to cover both surfaces would roughly double the implementation effort without adding learner value because each student uses one surface, not both.
- The constitution names `front/` as "the flagship surface" but does not forbid landing a feature on `na_app/` first. Principle III ("Independent, Priority-Ordered Slices") explicitly favors slicing scope; "v1 = Flutter only, Expo follows in a later spec" is a valid slice.

**Alternatives considered**:
- *Build both surfaces in v1.* Rejected: doubles effort, doubles QA, doesn't change the per-learner outcome.
- *Build only on Expo `front/`.* Rejected: the active mobile surface for this product is Flutter today, and the recent UX redesign lives there.
- *Pick at /tasks time.* Rejected: this is a structural decision that affects every contract reference in this plan; ambiguity would propagate.

**Implications**:
- All Flutter-side functional requirements in `spec.md` are owned by `na_app/`.
- `front/` (Expo) is unchanged; if/when offline mode is wanted there, it gets its own spec, reusing the same backend contracts defined here.
- The Plan's Project Structure section reflects this scope explicitly.

---

## Decision 2 — At-rest encryption: AES-GCM, per-file random IV, content key wrapped by platform keystore

**Decision**: Each downloaded video is encrypted on disk using **AES-256-GCM** with a per-file random 96-bit IV. The content key is a per-app, per-install symmetric key generated at first download and stored in the platform keystore (Keychain on iOS via `flutter_secure_storage`, Android Keystore on Android via `flutter_secure_storage`). The content key never leaves the keystore; the streaming decryption pipeline reads it once at play time.

**Rationale**:
- The clarification (Q1) chose "consumer-grade content protection: encrypt-at-rest with an app-managed key, no external license server." AES-GCM is the standard authenticated-encryption choice for files-at-rest in mobile apps; it provides confidentiality + integrity in one primitive without a separate MAC.
- Wrapping the content key in the platform keystore (rather than storing it in `SharedPreferences`/`UserDefaults`) means an attacker who pulls a backup of the device must defeat the OS keystore to decrypt the videos — strictly stronger than rolling our own at-rest scheme.
- Per-file random IV avoids IV reuse, the principal pitfall of AES-GCM. Keeping a single content key (rather than per-file keys) keeps the keystore footprint small (one entry per install).
- No external license server means no per-playback round-trip; offline playback stays truly offline (FR-007, SC-002).

**Alternatives considered**:
- *AES-CBC + HMAC.* Rejected: more code, easy to get wrong, no advantage over AES-GCM here.
- *Per-file keys derived from a master key + file id (HKDF).* Considered; rejected for v1 because it adds complexity without a concrete threat model that the single-content-key scheme misses (rotation is still possible by re-encrypting all files on key rotation; rare).
- *No encryption at rest, rely solely on app-private storage.* Rejected: backup extraction (iTunes/iCloud encrypted backup, Android `adb backup`) would yield directly playable files, contradicting the spec's protection intent.
- *Studio-grade DRM (Widevine L1 / FairPlay).* Rejected by clarification Q1.

**Implications**:
- New Flutter package: `cryptography` (Dart-native, well-maintained) for AES-GCM. `pointycastle` is a viable fallback if `cryptography` proves problematic.
- A `SecureBox` abstraction in `lib/core/offline/secure_box.dart` encapsulates encrypt/decrypt; the offline player never touches raw key material.
- On uninstall, the platform-keystore entry disappears with the app, and the encrypted files on disk become permanently unrecoverable. This matches the spec's "downloads do not survive an uninstall" assumption.

---

## Decision 3 — Tamper-resistant time source for the 14-day grace counter

**Decision**: The 14-day offline grace is anchored to **`server_confirmed_at + (uptime_now − uptime_at_server_confirmation)`**, where `server_confirmed_at` is the most recent successful entitlement-verify response timestamp from the server, and `uptime_*` come from a monotonic clock that resets only on device reboot. Wall-clock (`DateTime.now()`) is **never** trusted to compute the grace.

**Rationale**:
- Clarification Q2 set the grace at 14 days; FR-013a and SC-009 require the counter to resist clock tampering.
- A learner who sets the system clock backward to "extend" their offline window would otherwise trivially bypass the grace; this is a known threat in offline media apps.
- Monotonic uptime (`Process.tickCount` / Android `SystemClock.uptimeMillis()` / iOS `mach_absolute_time`) advances only while the device is on, doesn't go backward, and is unaffected by user-settable clocks.
- Device reboot resets uptime to zero; when that happens, we must compare current time-since-reboot against a *recorded* boot-relative offset, OR fall back to "if you've rebooted since the last verify, you must reconnect to play." The simpler, safer choice for v1 is the latter: reboot triggers a "needs re-verify" state on the very next play attempt, which is conservative but correct. (We accept the inconvenience of "play after a flight + a reboot needs Wi-Fi" because it's the same UX a reconnect would deliver anyway.)

**Alternatives considered**:
- *Trust the device wall-clock.* Rejected: trivially bypassed.
- *Sign every play attempt with a server clock.* Rejected: requires online connectivity; defeats the entire point of offline mode.
- *Use a TEE-backed Trusted Time API.* Rejected: not portably available across Flutter on iOS+Android without significant native plumbing for v1.

**Implications**:
- A `MonotonicClock` abstraction in `lib/core/offline/monotonic_clock.dart` records `(server_confirmed_at_wall_clock, uptime_at_confirmation)` and computes `effective_now = server_confirmed_at_wall_clock + (uptime_now − uptime_at_confirmation)`.
- After reboot, the cached `uptime_at_confirmation` is invalid; the next play attempt forces a reconnect. The data-model documents this state.
- Acceptable false positive: a rebooted device that immediately reconnects continues seamlessly; the only painful path is "rebooted + still offline" → blocked. That's a deliberate tradeoff per the spec.

---

## Decision 4 — Single-active-offline-device vs. existing whole-account device lock

**Background**: The existing `back/src/devices/` module already enforces a *whole-account* single-device rule: an account is bound to one `hardwareId`, and any other device gets a `ForbiddenException` on login. This is **stricter** than what the offline-mode spec assumes in FR-012c (which says streaming/login should work on multiple devices simultaneously, with the single-device rule applying only to *offline downloads*).

**Decision**: **Keep the existing whole-account device lock unchanged.** Layer the offline-active-device tracking on top — it controls *which device's downloads are valid*, not *whether the user can sign in elsewhere*. Because the existing lock already prevents two simultaneous active sessions, the practical effect is: when an admin resets the device lock and the learner signs in on a new device, the previous device's offline downloads are invalidated on its next online check (sync-then-wipe, FR-012d).

**Rationale**:
- Loosening the existing whole-account lock is a separate, larger product decision that affects auth, audit, abuse prevention, and admin-tooling — well outside the scope of "offline mode."
- The spec's FR-012c was written assuming multi-device login as a baseline; the platform's actual baseline is *stricter*, so the spec's intent ("downloads only ever live on one active device") is satisfied automatically.
- Adding a parallel "offline active device" record (a new collection/document) keeps the offline-mode change surgical and reversible: if the platform later relaxes the whole-account device lock, this feature continues to work without code changes — the offline-active-device tracking already exists.

**Alternatives considered**:
- *Loosen the whole-account device lock as part of this feature.* Rejected: out of scope, broader product implications, requires its own spec.
- *Reuse the existing `Device` document instead of a new `OfflineActiveDevice` document.* Considered; rejected because the existing `Device` represents the auth-bound device and uses an `isActive` boolean that is already overloaded with auth meaning. A separate `OfflineActiveDevice` collection keeps concerns clean and makes the sync-then-wipe state machine easier to reason about (it has its own lifecycle: claimed → active → released → wiped).

**Implications**:
- Adjusts FR-012c's framing in practice: "streaming/login on multiple devices simultaneously" is *not* offered by the platform today, and this feature does not change that. The user-visible behavior is still consistent with the spec's intent (single-device for offline) — just delivered by a stricter substrate.
- The plan's data-model adds a new `offline_active_devices` collection (one document per user, capturing the current active offline device). The existing `Device` schema stays unchanged.
- A note will be added to `spec.md`'s Assumptions in a future clarify pass if the product owner wants FR-012c framed differently. For now, the spec's intent is satisfied.

---

## Decision 5 — Embedded local DB: Drift (sqflite-backed, code-generated)

**Decision**: Use `drift` (the modern successor to Moor) for the local SQLite database in the Flutter app, hosting three tables: `offline_downloads`, `pending_progress_events`, and `cached_snapshot_blobs`.

**Rationale**:
- The app needs queryable structured local storage for: which lessons are downloaded, their sizes/timestamps, queued progress events, and a JSON-blob cache of last-seen course/lesson lists.
- `flutter_secure_storage` and `shared_preferences` are too small/slow for this; raw `sqflite` lacks compile-time-checked queries and is awkward to share across Riverpod providers.
- Drift gives type-safe code-generated DAOs, integrates well with Freezed and Riverpod (both already in `pubspec.yaml`), and the `na_app` build pipeline already uses `build_runner` for `riverpod_generator` and `freezed`, so adding Drift's generator is incremental.

**Alternatives considered**:
- *`sqflite` directly.* Rejected: lacks compile-time query checks; manual schema management is error-prone for a feature with three correlated tables.
- *`hive` or `isar`.* Considered; rejected because relational queries on `pending_progress_events` (e.g., "all events for a given lesson, ordered by timestamp") and joins between downloads and cached snapshots are awkward in NoSQL local stores. SQLite is the right shape for this data.
- *Plain JSON files in app-private storage.* Rejected: the pending-progress queue needs atomic append + drain semantics on reconnect, which a flat file makes hard to do safely.

**Implications**:
- New `pubspec.yaml` dependency: `drift` + `drift_dev` (dev) + `sqlite3_flutter_libs`. All are mature, widely used.
- One DB file (`offline.db`) lives in the app-private docs dir, encrypted at the SQLCipher level only if the wrapping key model is extended later. For v1, the DB itself is plaintext (it contains *metadata* about downloads, not the videos themselves; the videos are encrypted separately on disk). This is consistent with consumer-grade protection.

---

## Decision 6 — Streaming vs. dedicated download URL: reuse `GET /media/:id/stream`

**Decision**: The Flutter client downloads each video by issuing `GET /media/:id/stream` (the existing endpoint, with byte-range support) until the full file is fetched, then encrypts the bytes via `SecureBox` and writes the ciphertext to app-private storage. **No new "download URL" endpoint is introduced.**

**Rationale**:
- The existing `GET /media/:id/stream` endpoint already enforces all the access checks (Activation Code, subject access, role guard) — duplicating them in a parallel "download" endpoint risks drift and is gratuitous.
- `expo-router`'s analogues notwithstanding, Flutter's `dio` supports byte-range and resumable transfers natively, so resumable downloads (FR-005) can be implemented purely client-side over the existing endpoint.
- Avoiding a new endpoint reduces backend change surface and keeps Swagger lean.

**Alternatives considered**:
- *Add a `GET /media/:id/download` that returns a presigned URL.* Rejected: GridFS-backed streaming via the existing endpoint already serves the bytes directly with byte-range support; presigned URLs add infrastructure (S3/CDN) that the project doesn't use today.
- *Stream-encrypted-on-the-server.* Rejected: requires per-device key delivery, which is exactly the "no external license server" thing Q1 excluded.

**Implications**:
- The download pipeline is fully client-side: dio-driven byte-range fetch → AES-GCM encrypt-on-write → atomic rename to final ciphertext path.
- An offline-mode feature **does** still need:
  - A `POST /media/entitlement/verify` endpoint (Decision 4 / FR-013) — entitlement check without streaming bytes (cheap, batch-friendly).
  - A `POST /lesson-progress/batch` endpoint — already not present, needed for FR-015.
  - The active-offline-device claim/release endpoints (Decision 4) — needed for FR-012a–d.

---

## Decision 7 — Conflict resolution policy ("further-along progress wins")

**Decision**: Server-side ingestion of batched progress events compares `(watchedSeconds, isCompleted, completedAt)` per `(userId, lessonId)` against the existing `LessonProgress` document. The incoming event wins iff its `watchedSeconds` is strictly greater, or it is `isCompleted=true` and the existing one is not. Otherwise the existing document is preserved.

**Rationale**:
- The clarification (and FR-016) specify "further-along wins" — learner-favorable, consistent with the existing platform behavior, and avoids having to reason about clock skew across devices.
- This rule is order-independent: replaying batched events in any order produces the same final state. Combined with idempotent-by-client-event-id deduplication on the server, it's safe to retry.

**Alternatives considered**:
- *Strict last-write-wins by timestamp.* Rejected: clock-skew between devices makes this fragile and learner-hostile (a slightly-behind clock erases legitimate progress).
- *Per-event append-only log.* Rejected: requires schema changes and offers no learner-visible benefit beyond what "further-along wins" already provides.

**Implications**:
- The batched-progress endpoint accepts `clientEventId` per event so the server can dedupe replays.
- The existing `lesson-progress.service.ts` gets a `mergeBatch(...)` method that runs the comparison atomically per lesson.

---

## Open items (none blocking)

All Phase-0 questions are resolved. No outstanding `NEEDS CLARIFICATION` markers carry forward into Phase 1.
