# Tasks: Offline Mode (Downloaded Videos & Offline App Access)

**Input**: Design documents from `/specs/004-offline-mode/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: NOT requested in the spec or by the user. No explicit test tasks are generated. The constitution still requires `flutter analyze` and `npm run lint` to pass — covered in the Polish phase.

**Organization**: Tasks are grouped by user story (US1 = play downloaded video offline, US2 = open app & browse offline, US3 = manage downloads). US1 and US2 are both **P1** and together form the offline MVP; US3 is **P2**.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel — different files, no dependency on incomplete tasks in the same phase.
- **[Story]**: Maps the task to its user story (US1, US2, US3). Setup, Foundational, and Polish phases carry no story label.

## Path Conventions

- Backend: `back/src/...` (NestJS 11)
- Mobile: `na_app/lib/...` (Flutter 3.24+ / Dart 3.11+)
- New documentation: `specs/004-offline-mode/...` (already generated)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Bring in the new dependencies and create the empty module directories so foundational and story work can proceed without scaffolding interruptions.

- [ ] T001 [P] Add Flutter dependencies in `na_app/pubspec.yaml`: `drift: ^2.18.0`, `drift_dev: ^2.18.0` (dev), `sqlite3_flutter_libs: ^0.5.24`, `cryptography: ^2.7.0`, `path_provider: ^2.1.4`, `connectivity_plus: ^6.0.5`. Run `flutter pub get`.
- [ ] T002 [P] Add backend dependencies (verify only — no new packages expected) by inspecting `back/package.json` for existing `class-validator`, `class-transformer`, `@nestjs/swagger`, `@nestjs/throttler`. Document any missing piece in this task's description and add as needed.
- [ ] T003 [P] Create empty Flutter module directories: `na_app/lib/core/offline/` and `na_app/lib/features/offline_downloads/{data,domain,presentation/{controllers,pages,widgets}}/`. Add a top-level `barrel.dart` only if the codebase already uses barrel files (it does not — leave as plain dirs).
- [ ] T004 [P] Create empty backend DTO directories if missing: `back/src/devices/dto/` and `back/src/media/dto/` and `back/src/lesson-progress/dto/`. Each `dto/` should be a directory; no index file is required since NestJS modules import individual files.
- [ ] T005 Wire Drift's build runner: confirm `na_app/build.yaml` (create if missing) lists `drift_dev:preserve_include_imports: true` and that `flutter packages pub run build_runner build --delete-conflicting-outputs` completes cleanly with no Drift sources yet (smoke check). If a `build.yaml` already exists for `riverpod_generator` / `freezed`, **add** Drift to it — do not overwrite.
- [ ] T006 [P] Verify Swagger UI is enabled in dev for `back/`: hit `http://localhost:3000/api` (or whatever the existing `SwaggerModule.setup(...)` path is in `back/src/main.ts`) and confirm the existing `Devices`, `Media`, and `Lesson Progress` tags render. No code change unless Swagger is currently disabled.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build the cross-cutting plumbing every user story depends on (encryption, monotonic clock, local DB, connectivity, server-side offline-active-device collection, base DTOs). Until this phase is done, no user story can be wired up end-to-end.

**⚠️ CRITICAL**: No user-story phase work may start until Phase 2 is complete.

### Backend foundational

- [ ] T007 Create `OfflineActiveDevice` Mongoose schema in `back/src/devices/schemas/offline-active-device.schema.ts` with the fields and indexes documented in `data-model.md §1.1` (`userId` unique, `deviceId`, `hardwareId`, `claimedAt`, `lastVerifiedAt`, `pendingWipe`, `previousDeviceId`, timestamps).
- [ ] T008 Register the schema in `back/src/devices/devices.module.ts`: add `MongooseModule.forFeature([{ name: OfflineActiveDevice.name, schema: OfflineActiveDeviceSchema }])` and export the model so the service can inject it.
- [ ] T009 Add a thin `DevicesController` skeleton at `back/src/devices/devices.controller.ts` (file does not exist yet — verified via `ls`). Wire `@ApiTags('Devices')`, `@ApiBearerAuth()`, the existing `JwtAuthGuard` / `RolesGuard`, and a constructor that injects `DevicesService`. Do **not** add routes yet — they come in US1.
- [ ] T010 Register the new `DevicesController` in `back/src/devices/devices.module.ts` `controllers: [...]` array. Run `npm run start:dev` once and confirm the app boots without errors and the `Devices` Swagger tag now exists.

### Mobile foundational

- [ ] T011 Implement `na_app/lib/core/offline/secure_box.dart`: a `SecureBox` class wrapping `package:cryptography`'s `AesGcm.with256bits()`. Public surface: `encryptStream(input, sink)` and `decryptStream(input, sink)` plus `Future<void> ensureContentKey()` which generates a 256-bit key on first call and stores it in `flutter_secure_storage` under key `offline.content_key`. Include a per-call random 96-bit IV stored alongside the ciphertext. No file I/O here — operate on streams the caller provides.
- [ ] T012 [P] Implement `na_app/lib/core/offline/monotonic_clock.dart`: a `MonotonicClock` class. Public surface: `Future<void> recordServerConfirmation(DateTime serverTime)`, `Future<DateTime> effectiveNow()`, `Future<Duration> sinceLastConfirmation()`. Internally persists `(server_confirmed_at_wall, uptime_at_confirmation_ms, boot_id)` to the offline DB (table `offline_meta` — defined in T015). On boot id change, `effectiveNow()` returns "needs reverify" sentinel. Use `device_info_plus` to derive a stable boot id (e.g., Android `bootTime`, iOS `uptime` rounded).
- [ ] T013 [P] Implement `na_app/lib/core/offline/connectivity_observer.dart`: a Riverpod `StreamProvider<ConnectivityStatus>` wrapping `connectivity_plus`. Status values: `online`, `offline`. Coalesce duplicate transitions; emit only on actual change.
- [ ] T014 [P] Define the Drift schema in `na_app/lib/core/offline/offline_db.dart`. Tables per `data-model.md §2.1`: `OfflineDownloads`, `PendingProgressEvents`, `CachedSnapshotBlobs`, plus a tiny `OfflineMeta` key/value table for `MonotonicClock`'s persisted state. Use Drift's `@DriftDatabase(tables: [...])` annotation. Provide DAOs for each table.
- [ ] T015 Run `flutter packages pub run build_runner build --delete-conflicting-outputs` to generate `offline_db.g.dart`. Commit both the source and the generated file (matches existing project convention for generated Riverpod / Freezed files).
- [ ] T016 [P] Add a Riverpod provider exposing the Drift database in `na_app/lib/core/offline/offline_db.dart` (same file). Provider lifecycle: app-singleton, opens the DB at app start, closes on dispose. Use the existing project pattern (e.g., `chat_socket.dart` style provider exposure).
- [ ] T017 [P] Extend `na_app/lib/core/storage/prefs_store.dart` with two new keys: `offline.bootId` (current boot session id) and `offline.activeOfflineDeviceClaimed` (bool — has this device claimed offline-active status with the server yet?). Add typed getters/setters; do not break existing keys.
- [ ] T018 [P] Add the new offline endpoints to `na_app/lib/core/api/endpoints.dart`: constants `mediaEntitlementVerify` (`/media/entitlement/verify`), `lessonProgressBatch` (`/lesson-progress/batch`), `devicesOfflineClaim` (`/devices/offline/claim`), `devicesOfflineStatus` (`/devices/offline/status`), `devicesOfflineRelease` (`/devices/offline/release`). Match the existing constant-naming style in this file.
- [ ] T019 Generate the offline content key on first app launch after sign-in: in `na_app/lib/features/auth/presentation/controllers/auth_controller.dart`, after a successful sign-in, call `SecureBox.ensureContentKey()` once. Do **not** delete the key on sign-out yet (US3 will add the "remove all downloads" path that wipes it).
- [ ] T020 Add a developer-only DEBUG menu hook (gated by `kDebugMode`) at `na_app/lib/features/profile/presentation/pages/profile_page.dart` (or the closest existing developer settings location) exposing two actions: "rewind last_verified_at by 14 days" and "force boot id change". These power Quickstart Steps 7 and 8. Hidden behind a long-press on the version label.

**Checkpoint**: Foundation ready. Encryption, monotonic clock, local DB, connectivity, the `OfflineActiveDevice` schema, and the empty `DevicesController` are all in place. User-story phases can proceed in parallel.

---

## Phase 3: User Story 1 — Watch a downloaded lesson video without internet (Priority: P1) 🎯 MVP

**Goal**: A learner can mark a specific lesson video for download while online; the file is encrypted at rest in app-private storage; the learner can play it end-to-end offline with zero network calls; offline progress is buffered and synced on reconnect; entitlement is verified on reconnect (with the 14-day grace and tamper-resistant clock); and the single-active-offline-device handoff (sync-then-wipe) works between two devices.

**Independent Test**: Quickstart Steps 1, 2, 4, 6, 7, 8 (`specs/004-offline-mode/quickstart.md`). Specifically: download a video while online → enable airplane mode → play end-to-end → reconnect → observe progress synced and entitlement verified → handoff to a second device → original device sync-then-wipes correctly.

### Backend — endpoint contracts (US1)

- [ ] T021 [P] [US1] Implement `back/src/media/dto/verify-entitlement.dto.ts` per `contracts/entitlement.md`. Two classes: `VerifyEntitlementDto` and `VerifyEntitlementItemDto` with `class-validator` annotations (`@ArrayMinSize(1)`, `@ArrayMaxSize(100)`, `@IsArray()`, `@ValidateNested({each:true})`, `@Type(...)`, `@IsMongoId()`).
- [ ] T022 [P] [US1] Implement `back/src/media/dto/entitlement-verification-result.dto.ts` (response DTO + per-item DTO with `decision: 'allowed' | 'revoked' | 'superseded'`, `currentContentVersion`, `reason?`, plus the top-level `serverTimestamp`).
- [ ] T023 [US1] Add `MediaService.verifyEntitlements(userId: string, items: VerifyEntitlementItemDto[])` in `back/src/media/media.service.ts`. Reuse the existing `LessonsService.canAccessMediaContent(userId, subjectId, mediaId)` (already injected per `media.controller.ts:33`). Compute `currentContentVersion = asset.updatedAt.getTime().toString()`. Return supersession when the request's `knownContentVersion` differs.
- [ ] T024 [US1] Add `POST /media/entitlement/verify` in `back/src/media/media.controller.ts` per `contracts/entitlement.md`: `@Roles('student','teacher')`, `@ApiOperation({...})`, `@ApiOkResponse(...)`. Wire to `MediaService.verifyEntitlements`. Use the existing `JwtAuthGuard`/`RolesGuard` setup.
- [ ] T025 [P] [US1] Implement `back/src/devices/dto/claim-active-offline-device.dto.ts`, `back/src/devices/dto/release-offline-device.dto.ts`, and the result DTOs (`ClaimActiveOfflineDeviceResultDto`, `ReleaseOfflineDeviceResultDto`, `OfflineDeviceStatusDto`) per `contracts/active-offline-device.md`.
- [ ] T026 [US1] Add `claimOfflineActive`, `statusForCallingDevice`, `releasePreviousOffline` methods to `DevicesService` in `back/src/devices/devices.service.ts`, implementing the state machine in `data-model.md §1.1`. Use `findOneAndUpdate({userId},{...},{upsert:true,new:true})` and a Mongoose transaction where two-document atomicity is needed.
- [ ] T027 [US1] Add the three routes to `DevicesController` (created empty in T009): `POST /devices/offline/claim`, `GET /devices/offline/status`, `POST /devices/offline/release`. Wire DTOs from T025 and the service methods from T026. Include `@ApiOperation` summaries from `contracts/active-offline-device.md`.
- [ ] T028 [P] [US1] Implement `back/src/lesson-progress/dto/batch-progress-events.dto.ts` per `contracts/offline-progress.md`. Top-level `BatchProgressEventsDto` (with `@ArrayMaxSize(100)`) and per-event `ProgressEventDto`.
- [ ] T029 [P] [US1] Implement `back/src/lesson-progress/dto/batch-progress-events-result.dto.ts` (response shape with `acceptedClientEventIds`, `rejectedClientEventIds: {clientEventId, reason}[]`, `serverTimestamp`).
- [ ] T030 [US1] Add `LessonProgressService.mergeBatch(userId, events)` in `back/src/lesson-progress/lesson-progress.service.ts` implementing the "further-along wins" rules from `data-model.md §1.3` and `contracts/offline-progress.md`. Group by `lessonId`, single load + single upsert per group. Add an in-memory `Set<clientEventId>` cache (size-capped, e.g., 1000 ids per active session) for dedup.
- [ ] T031 [US1] Add `POST /lesson-progress/batch` in `back/src/lesson-progress/lesson-progress.controller.ts`. `@Roles('student','teacher')`, full Swagger annotations.

### Mobile — domain & data layer (US1)

- [ ] T032 [P] [US1] Define the Freezed model `OfflineDownload` in `na_app/lib/features/offline_downloads/domain/offline_download.dart` with fields mirroring the Drift `OfflineDownloads` row (`lessonId`, `subjectId`, `mediaId`, `lessonTitle`, `courseTitle`, `bytesDownloaded`, `bytesTotal`, `status` as a Dart enum, `quality`, `ivBase64`, `authTagBase64?`, `ciphertextPath`, `contentVersion?`, `lastVerifiedAt?`, `downloadedAt`). Run build_runner.
- [ ] T033 [P] [US1] Define the request/response DTOs as Freezed classes in `na_app/lib/features/offline_downloads/data/dto/`: `EntitlementVerifyRequest`, `EntitlementVerifyResponse`, `ClaimRequest`, `ClaimResponse`, `OfflineStatusResponse`, `BatchProgressRequest`, `BatchProgressResponse`. Mirror exactly the JSON shapes in the contracts.
- [ ] T034 [US1] Implement `na_app/lib/features/offline_downloads/data/offline_downloads_repository.dart`. Public surface:
  - `Stream<List<OfflineDownload>> watchAll()`
  - `Future<OfflineDownload?> findByLessonId(String lessonId)`
  - `Future<void> upsert(OfflineDownload d)`
  - `Future<void> updateStatus(String lessonId, OfflineDownloadStatus status)`
  - `Future<void> delete(String lessonId)` — also deletes the ciphertext file.
  Reads/writes via the Drift DAOs; deletes the on-disk ciphertext file via `File(d.ciphertextPath).delete()`.
- [ ] T035 [US1] Implement the download engine in `na_app/lib/features/offline_downloads/data/download_engine.dart`. Uses `dio` byte-range GET against the existing `GET /media/:id/stream` endpoint (no new endpoint). On each chunk: pipe through `SecureBox.encryptStream(...)` → write to `<docs>/offline/<lessonId>.bin.tmp`. On completion: finalize AES-GCM tag, atomic rename to `.bin`, write `authTagBase64` to the row. Resumable by reading current `bytesDownloaded` and issuing `Range: bytes=N-`. Emits a `Stream<DownloadProgress>` for the UI.
- [ ] T036 [US1] Implement the offline player in `na_app/lib/features/offline_downloads/data/offline_video_player.dart`. Wraps `video_player`/`chewie` with a `decrypt-on-read` wrapper: stream the ciphertext through `SecureBox.decryptStream(...)` into a temporary in-memory buffer or temp plaintext file, hand to `video_player`. On Android, prefer `package:video_player` with a `data:` URI from a memory pipe; if Chewie can't accept that, fall back to writing a temp plaintext file in app cache and deleting on dispose.
- [ ] T037 [US1] Implement `na_app/lib/features/offline_downloads/data/pending_progress_writer.dart`: `recordProgress({lessonId, subjectId, watchedSeconds, isCompleted})` → inserts a row into `pending_progress_events` with a freshly generated ULID and the current monotonic clock state. Wire this into the offline player so progress events fire every 5 seconds during playback and on completion.
- [ ] T038 [US1] Implement `na_app/lib/features/offline_downloads/data/sync_worker.dart`: on `ConnectivityObserver` `online` transition and on app resume, drain `pending_progress_events` in batches of up to 100 → `POST /lesson-progress/batch`. Delete accepted and rejected rows; retain on network errors with exponential backoff (capped at 5 min).
- [ ] T039 [US1] Implement `na_app/lib/features/offline_downloads/data/entitlement_client.dart`: `Future<EntitlementVerifyResponse> verifyAll()` — collects all `OfflineDownloads` rows, calls `POST /media/entitlement/verify` in batches of 100, applies per-item decisions: `allowed` → update `last_verified_*` fields and bump `MonotonicClock.recordServerConfirmation(response.serverTimestamp)`; `revoked` → call `OfflineDownloadsRepository.delete(lessonId)`; `superseded` → keep the row but flag a "newer version" indicator.
- [ ] T040 [US1] Implement `na_app/lib/features/offline_downloads/data/active_offline_device_client.dart`: thin wrappers around `POST /devices/offline/claim`, `GET /devices/offline/status`, `POST /devices/offline/release`. Used by the claim-on-first-download flow and the sync-then-wipe handoff.
- [ ] T041 [US1] Implement `na_app/lib/features/offline_downloads/data/handoff_orchestrator.dart`: on `online` transition, call `GET /devices/offline/status`. If `pendingWipeForThisDevice == true`: (1) await `SyncWorker.drainAll()`, (2) show the in-app notification ("Your offline downloads moved to <new device>"), (3) delete every row in `offline_downloads` (including ciphertext files), (4) call `POST /devices/offline/release`. If any step fails, abort the cycle and retain local files for the next reconnect (FR-012d).

### Mobile — presentation layer (US1)

- [ ] T042 [P] [US1] Riverpod controller `na_app/lib/features/offline_downloads/presentation/controllers/download_controller.dart`: exposes per-lesson download state (`notDownloaded | downloading(progress) | downloaded | failed | needsReverify | superseded`), `startDownload(lessonId)`, `removeDownload(lessonId)`. Composes `OfflineDownloadsRepository`, `DownloadEngine`, `ActiveOfflineDeviceClient` (calls `claim` on first-ever download for this device).
- [ ] T043 [P] [US1] Build the per-lesson download UI in `na_app/lib/features/offline_downloads/presentation/widgets/download_button.dart`. Honors the design system per Constitution Principle I: parchment surface, pill-shape, Sage-Teal only as a small accent on the active "downloaded" check icon, ≥44×44pt touch target. States: idle (download icon), downloading (progress pill), done (small check + "Available offline"), failed (retry pill).
- [ ] T044 [P] [US1] Build `na_app/lib/features/offline_downloads/presentation/widgets/offline_lock_banner.dart` covering two states: "Offline > 14 days — connect to re-verify" (FR-013a) and "This device's offline downloads were moved to another device" (FR-012b previous-device side). Parchment-tone surfaces, no Sage-Teal here, ≤44pt-tall banner that doesn't shove other content.
- [ ] T045 [US1] Wire the `download_button` into the existing lesson screen at `na_app/lib/features/lessons/presentation/pages/` (find the lesson-detail page and place the button next to the video player). When the lesson has a downloaded copy, swap `chewie` for `OfflineVideoPlayer` so playback decrypts from the local file. When `OfflinePlayerGuard` reports a lock, render `offline_lock_banner` instead of the player.

**Checkpoint**: At this point, US1 is fully functional end-to-end. A learner can download, play offline, sync on reconnect, and the device handoff works. Quickstart Steps 1, 2, 4, 6, 7, 8 should all pass.

---

## Phase 4: User Story 2 — Open the app and browse already-loaded content with no internet (Priority: P1)

**Goal**: The app cold-starts in airplane mode, keeps the learner signed in, and renders enrolled courses, lesson lists, lesson text, and progress from a local cache — without any network call. Network-required surfaces (chat, exam, uncached content) show clear in-context offline states instead of crashing or blocking with a full-screen error.

**Independent Test**: Quickstart Step 3.

### Cached snapshot plumbing (US2)

- [ ] T046 [US2] Implement `na_app/lib/core/offline/cached_snapshot_writer.dart`: a Dio `Interceptor` that, on every successful 2xx response for whitelisted endpoints (enrolled courses list, course → lesson list, lesson text, profile), writes the JSON payload to the `cached_snapshot_blobs` table keyed by `<endpointKey>`. Register the interceptor in the existing dio provider in `na_app/lib/core/api/`.
- [ ] T047 [US2] Implement `na_app/lib/core/offline/cached_snapshot_reader.dart`: helpers `Future<T?> read<T>(String key, T Function(Map<String,dynamic>) decoder)`. Riverpod providers in the home, courses, and lessons features call this as a fallback when the network call throws (offline) — re-read the most recent cached blob and decode.

### Auth & cold-start path (US2)

- [ ] T048 [US2] Modify `na_app/lib/features/auth/presentation/controllers/auth_controller.dart` to support a "signed-in offline" state. When app starts offline but a JWT exists in `flutter_secure_storage`, do **not** force a network call to validate; treat the cached identity as authoritative, attach the existing token to outbound dio calls (they will fail offline, but UI falls back to cache via T047), and trigger silent refresh on next `online` transition.
- [ ] T049 [US2] Adjust the app router at `na_app/lib/core/router/app_router.dart` so the initial route is determined from local state only (cached identity + cached enrolled courses) when offline. Do not hit any network endpoint during cold-start. Confirm SC-001 (cold-start to lessons list < 5 s) holds in airplane mode by manual measurement.
- [ ] T050 [P] [US2] Update home/courses screens (`na_app/lib/features/home/presentation/pages/`) to call the cache reader (T047) when the network call throws. Render the cached list; show a small unobtrusive "Offline" pill in the app bar (parchment-tone, no full-screen blocker).

### Offline lesson view (US2)

- [ ] T051 [US2] Update the lessons feature pages at `na_app/lib/features/lessons/presentation/pages/` to: (a) read lesson text from cached snapshots when offline; (b) when the lesson video is *not* downloaded and we are offline, show the player area as "Not downloaded — connect to watch or download" (FR-012, AS4) — no crash, no blocking modal.
- [ ] T052 [P] [US2] Add an offline state to the chat list/thread pages at `na_app/lib/features/chat/presentation/pages/`: a calm "You're offline — chat needs a connection" panel replacing the input area, leaving any cached message history visible. Do not delete cached messages.
- [ ] T053 [P] [US2] Add an offline state to the exams feature at `na_app/lib/features/exams/presentation/pages/`: when offline, exam-start CTAs show a "You're offline — exam requires a connection" tooltip/banner and do not proceed. (Exams remain online-only per Out of Scope.)

### Reconnect sync glue for US2

- [ ] T054 [US2] On `online` transition (handled by `ConnectivityObserver`), trigger a **single** orchestrated refresh in `na_app/lib/core/offline/online_resume_orchestrator.dart`: in order, run `HandoffOrchestrator.run()` (US1, T041) → `SyncWorker.drainAll()` (US1, T038) → `EntitlementClient.verifyAll()` (US1, T039) → `CachedSnapshotWriter`-driven foreground refresh of the home/courses snapshots. This file is created here in US2 because US2 is when the cache becomes a first-class consumer.
- [ ] T055 [P] [US2] Add the small "Offline" indicator chip to the global app shell (likely `na_app/lib/core/widgets/`) that shows whenever `ConnectivityObserver` reports `offline`. Hide on `online`. Parchment palette, Inter body weight, no Sage-Teal.
- [ ] T056 [US2] Verify the cold-start path (T049) does not accidentally re-introduce a network call by adding a `kDebugMode`-only assertion in the dio interceptor that throws if a request fires before the first frame settles in offline cold-start. Remove the assertion before merge if the team prefers a softer approach (log-only).

**Checkpoint**: US1 and US2 are both functional. The offline MVP is complete. Quickstart Steps 1–4, 6–8 should all pass.

---

## Phase 5: User Story 3 — Manage offline downloads and storage (Priority: P2)

**Goal**: A learner can see what's downloaded, how much storage it uses, remove individual or bulk downloads, and choose a default download quality.

**Independent Test**: Quickstart Step 5.

### Manage Downloads page (US3)

- [ ] T057 [US3] Build the page scaffold at `na_app/lib/features/offline_downloads/presentation/pages/manage_downloads_page.dart`: groups items by course, each item shows lesson title, file size (human-readable), download date; the screen header shows total storage used. Layout follows DESIGN.md (parchment, Fraunces title, Inter body, ≤10% Sage-Teal — applied to the "Remove all" CTA only). One-handed reach for per-item Remove.
- [ ] T058 [P] [US3] Riverpod controller `na_app/lib/features/offline_downloads/presentation/controllers/manage_downloads_controller.dart`: streams the `OfflineDownloads` table grouped by `subjectId`, exposes `removeOne(lessonId)`, `removeCourse(subjectId)`, `removeAll()`. Each delete cascades to ciphertext file deletion via `OfflineDownloadsRepository.delete(...)`.
- [ ] T059 [US3] Wire navigation from the existing profile page (`na_app/lib/features/profile/presentation/pages/profile_page.dart`) to the new manage-downloads page via `go_router`. Add the route in `na_app/lib/core/router/app_router.dart`.

### Storage size accounting (US3)

- [ ] T060 [US3] In `manage_downloads_controller.dart`, compute the total via `SUM(bytes_downloaded)` from the `offline_downloads` table. Validate against actual on-disk size for one item per page open (cheap spot-check) to satisfy SC-005's ±5% accuracy goal; log a warning if mismatch is large.

### Quality picker (US3)

- [ ] T061 [P] [US3] Add a `download.quality` preference to `na_app/lib/core/storage/prefs_store.dart` with values `standard` and `high`. Default `standard`.
- [ ] T062 [P] [US3] Add a quality picker to the manage-downloads screen (T057): a small "Default download quality" row with a segmented control. Persists via `prefs_store`. Apply on the **next** download, not retroactively.
- [ ] T063 [US3] Update `download_engine.dart` (T035) to read `prefs_store.download.quality` when starting a download and pass the selected quality to the server stream URL (e.g., `?quality=standard|high` query param if the existing media stream supports it; if not, document this as a future-server enhancement and use `standard` only for v1 — quality is then a forward-compatibility hook in the data model).

### Free-space guard refinement (US3)

- [ ] T064 [US3] Strengthen the free-space guard in `download_engine.dart`: before starting, check `Directory(...).statSync()` on the docs dir parent and refuse downloads whose `bytes_total` exceeds available free space minus a 200 MB safety margin. Surface a calm error in the UI ("Not enough storage — free up space and try again").

**Checkpoint**: US1, US2, and US3 are all complete. All Quickstart steps should pass.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Quality, localization, accessibility, performance, and final validation.

- [ ] T065 [P] Add Arabic + English localization strings for every new user-facing string introduced by US1/US2/US3 to `na_app/assets/translations/ar.json` and `na_app/assets/translations/en.json`. Cover: download/downloading/downloaded states, "Available offline", offline cold-start indicator, manage-downloads labels and totals, 14-day re-verify banner, device-handoff notifications, "You're offline" states for chat/exam/lesson pages.
- [ ] T066 [P] Honor `prefers-reduced-motion` on the download progress pill (T043), the offline lock banner (T044), and the offline indicator chip (T055): if the platform reports reduced-motion preference, replace any spin/pulse animations with static states. Use Flutter's `MediaQuery.disableAnimationsOf(context)` (Flutter 3.13+).
- [ ] T067 Run a manual cold-start performance pass on a mid-range Android device and an older iPhone in airplane mode (after one prior signed-in launch). Confirm "lessons list visible in < 5 s" (SC-001). If exceeded, profile and address the slowest path; document the result in this task's PR description.
- [ ] T068 [P] Run `flutter analyze` in `na_app/` and fix every warning/error introduced by this feature (per Constitution: must pass before merge).
- [ ] T069 [P] Run `npm run lint` in `back/` and fix every warning/error introduced by this feature (per Constitution).
- [ ] T070 [P] Confirm Swagger renders all three new endpoints (`POST /media/entitlement/verify`, `POST /lesson-progress/batch`, `POST/GET/POST /devices/offline/{claim,status,release}`) with full request/response examples and proper tags. Cross-check against `contracts/*.md`.
- [ ] T071 Walk through every step of `specs/004-offline-mode/quickstart.md` end-to-end on a real device. Capture pass/fail per Step in the PR description, attaching screenshots / a short screen recording for Steps 2 and 3 (per Constitution Principle I: UI-touching PRs must include a mobile-viewport screen capture).
- [ ] T072 Update agent context if any new tech entered the picture during implementation (e.g., a different DB / encryption library) by re-running `.specify/scripts/powershell/update-agent-context.ps1 -AgentType claude`. If the script's output already matches reality, skip.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: no dependencies; can start immediately.
- **Phase 2 (Foundational)**: depends on Phase 1; **blocks all user stories**.
- **Phase 3 (US1)**: depends on Phase 2.
- **Phase 4 (US2)**: depends on Phase 2; can run in parallel with Phase 3 if staffed by a separate developer (different files/screens). One handoff point: T054 (`online_resume_orchestrator.dart`) consumes US1's `HandoffOrchestrator`/`SyncWorker`/`EntitlementClient` — if US2 starts before those are ready, T054 should be deferred until US1's data layer (T038–T041) is in.
- **Phase 5 (US3)**: depends on Phase 2 and on US1's domain layer (it reuses `OfflineDownloadsRepository` and the `offline_downloads` table). Can be developed in parallel with US2.
- **Phase 6 (Polish)**: depends on US1+US2 complete (US3 optional for MVP). Quickstart walkthrough (T071) requires whichever stories are intended for the deployment.

### Within Each User Story

- Models / DTOs before services.
- Services before endpoints.
- Backend endpoints before mobile clients that consume them (US1: T021–T031 before T039–T041).
- Repository before controllers; controllers before widgets; widgets before screen integration.

### Parallel Opportunities

- All `[P]` tasks within a phase can run in parallel if assigned to different developers (different files, no shared state).
- Phase 1: T001, T003, T004, T006 in parallel (all different files / verify-only).
- Phase 2: T011, T012, T013, T014, T016, T017, T018 in parallel after T007–T010 land for the backend side. T015 must wait on T014.
- Phase 3 (US1): T021, T022 || T025 || T028, T029 in parallel (DTO files); after services land (T023, T026, T030), endpoints (T024, T027, T031) can run in parallel; on the mobile side, T032, T033 can run in parallel and unblock the rest.
- Phase 4 (US2): T046 || T048 || T050 || T052 || T053 || T055 — most files are independent.
- Phase 5 (US3): T058, T061, T062 in parallel.
- Phase 6: T065, T066, T068, T069, T070 in parallel; T067 and T071 are manual-device steps that should run last.

---

## Parallel Example: Foundational Phase

```bash
# After T007–T010 land (backend OfflineActiveDevice schema + module), the
# following Mobile foundational tasks can run in parallel:
Task: "T011 Implement secure_box.dart in na_app/lib/core/offline/"
Task: "T012 Implement monotonic_clock.dart in na_app/lib/core/offline/"
Task: "T013 Implement connectivity_observer.dart in na_app/lib/core/offline/"
Task: "T014 Define Drift schema in na_app/lib/core/offline/offline_db.dart"
Task: "T017 Extend prefs_store.dart with offline.bootId / offline.activeOfflineDeviceClaimed"
Task: "T018 Add new endpoint constants to na_app/lib/core/api/endpoints.dart"
```

## Parallel Example: User Story 1 (DTO layer)

```bash
# Backend DTOs are fully independent files:
Task: "T021 Implement verify-entitlement.dto.ts"
Task: "T022 Implement entitlement-verification-result.dto.ts"
Task: "T025 Implement claim-active-offline-device.dto.ts and release/result DTOs"
Task: "T028 Implement batch-progress-events.dto.ts"
Task: "T029 Implement batch-progress-events-result.dto.ts"
```

---

## Implementation Strategy

### MVP (US1 + US2)

The spec lists US1 and US2 both as P1 — together they form the offline MVP. Either alone is incomplete: a learner who can't open the app offline can't use downloaded videos; a learner who can open the app offline but has no downloads has nothing to do.

1. Complete Phase 1 (Setup) and Phase 2 (Foundational).
2. Complete Phase 3 (US1) and Phase 4 (US2). If staffed by one developer, do US1 first (the harder, more-architectural slice), then US2 — most of US2 reuses US1's foundation.
3. Run Quickstart Steps 1–4, 6, 7, 8.
4. **STOP and VALIDATE**: this is the MVP. Ship to a small cohort (e.g., one course's students) before US3.

### Incremental Delivery

- After MVP ships, add US3 (manage downloads) — incrementally adds the management screen and the quality picker.
- Polish phase runs across all stories that ship.

### Parallel Team Strategy

With two developers:

1. Both pair on Phase 1 + Phase 2.
2. Once Foundational is done:
   - Developer A: Phase 3 (US1) — the bulk of new architecture.
   - Developer B: Phase 4 (US2) — caching layer and offline UI states.
   - Sync at T054 (`online_resume_orchestrator.dart`) once US1's data layer is in.
3. After MVP ships, either developer picks up Phase 5 (US3); they're small.

---

## Notes

- `[P]` tasks = different files, no dependency on incomplete tasks in the same phase.
- `[Story]` label maps each task back to its user story for traceability.
- Each user story should be independently completable and testable per its **Independent Test** in `spec.md`.
- Test tasks were **not requested** by the user. The Polish phase relies on `flutter analyze`, `npm run lint`, Swagger validation, and the manual Quickstart walkthrough for verification.
- Commit after each task or logical group. Avoid same-file conflicts when running `[P]` tasks in parallel.
- Stop at any Checkpoint to validate stories independently.
