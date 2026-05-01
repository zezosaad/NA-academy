# Tasks: Push Notifications & In-App Inbox (FCM)

**Input**: Design documents from `/specs/005-fcm-push-notifications/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: The spec did not request a TDD approach. Tests are not generated as separate task units; instead, every implementation task that introduces a contract endpoint, validator, or invariant has the contract assertion folded into its acceptance criteria. Add explicit test tasks later if the team decides to backfill.

**Organization**: Tasks are grouped by user story so each priority slice can be implemented, tested, and demoed independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- All file paths are absolute from repo root: `back/`, `admin-dashboard/`, `na_app/`

## Path Conventions

- **Backend (NestJS)**: `back/src/`
- **Admin dashboard (React/Vite)**: `admin-dashboard/src/`
- **Flutter mobile**: `na_app/lib/`

User-story map (priorities from spec.md):

- **US1 — Admin broadcast to all** (P1, MVP half 1)
- **US2 — Student in-app inbox** (P1, MVP half 2; US1+US2 together = MVP)
- **US3 — Targeted send (specific users / subject)** (P2)
- **US4 — Admin send history & detail** (P3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Get Firebase + new dependencies in place across all three surfaces. No application logic yet.

- [X] T001 Add `firebase-admin` and `@nestjs/schedule` to `back/package.json` (`npm install firebase-admin @nestjs/schedule`); commit lockfile.
- [X] T002 [P] Add `firebase_core`, `firebase_messaging`, `flutter_local_notifications` to `na_app/pubspec.yaml`; run `flutter pub get`; commit lockfile.
- [X] T003 [P] Add Firebase service-account env vars to `back/src/config/configuration.ts`: `firebase.projectId`, `firebase.serviceAccountPath`, `firebase.serviceAccountJson`. Document required `.env` keys in `back/README.md`.
- [X] T004 [P] Document Firebase Console setup (Android `package_name`, iOS `bundle_id`, APNs key upload, gitignored config files) in `specs/005-fcm-push-notifications/quickstart.md` (already drafted) — verify it stays accurate after T001–T003.
- [X] T005 [P] Add `na_app/android/app/google-services.json` and `na_app/ios/Runner/GoogleService-Info.plist` to `.gitignore` (and commit `.example` placeholders documenting the expected fields).
- [X] T006 [P] Apply `com.google.gms.google-services` Gradle plugin in `na_app/android/app/build.gradle` and bump Gradle classpath in `na_app/android/build.gradle` per `firebase_core` setup docs.
- [X] T007 [P] In `na_app/ios/Runner.xcodeproj` (via `na_app/ios/Podfile` + Xcode project edit), enable **Push Notifications** and **Background Modes → Remote notifications** capabilities for the `Runner` target.

**Checkpoint**: All four surfaces compile, Firebase SDKs are present but unused.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Wire the schemas, modules, DTOs, and Firebase bootstraps that **every** user story depends on. After Phase 2, parallel work on US1 and US2 becomes safe.

**⚠️ CRITICAL**: No US1/US2/US3/US4 work begins until this phase is complete.

### Backend foundations

- [X] T008 Create `back/src/notifications/schemas/notification.schema.ts` defining the `Notification` Mongoose schema per `data-model.md` §1, including `AudienceDescriptor` and `NotificationStats` sub-documents and the four indexes (unique idempotency, createdAt, audience-kind/subjectId/createdAt, text on title+body).
- [X] T009 [P] Create `back/src/notifications/schemas/notification-recipient.schema.ts` defining the `NotificationRecipient` schema per `data-model.md` §2 with the four indexes (unique notification+user, user+createdAt, user+readAt, createdAt).
- [X] T010 [P] Create `back/src/push-tokens/schemas/push-token.schema.ts` defining the `PushToken` schema per `data-model.md` §3 with the unique `tokenHash` index and partial-unique `userId` (`tombstonedAt` $exists false) index.
- [X] T011 Create `back/src/notifications/dto/audience.dto.ts` (`AudienceDto` with `kind` enum + conditional `userIds`/`subjectId` validators per `contracts/notifications.md`).
- [X] T012 [P] Create `back/src/notifications/dto/create-notification.dto.ts` with `class-validator` rules per contract (length bounds, custom `@ValidateData()` decorator). Implement `@ValidateData()` in `back/src/notifications/dto/validators/data-payload.validator.ts` enforcing key regex + 4 KB total size.
- [X] T013 [P] Create `back/src/notifications/dto/notification-response.dto.ts` (`NotificationResponseDto`, `NotificationStatsDto`, `AudienceResponseDto`).
- [X] T014 [P] Create `back/src/notifications/dto/recipient-state.dto.ts` (`RecipientStateDto`, `NotificationDetailResponseDto`, `InboxItemDto`, `InboxResponseDto`).
- [X] T015 [P] Create `back/src/notifications/dto/notification-list-query.dto.ts` (`NotificationListQueryDto`).
- [X] T016 [P] Create `back/src/push-tokens/dto/register-token.dto.ts` and `back/src/push-tokens/dto/token-response.dto.ts` per `contracts/push-tokens.md`.
- [X] T017 Create `back/src/notifications/fcm.service.ts`: thin wrapper around `firebase-admin` `messaging().sendEachForMulticast()`, with batching (≤500 tokens/call), per-token error mapping (`unregistered`, `invalid-token`, `quota-exceeded`, `unknown`), and a typed `BatchSendResult` return shape. Initialize the SDK once on module bootstrap from `firebase.serviceAccountPath` or `firebase.serviceAccountJson`; fail fast with a clear log if neither is set.
- [X] T018 Create `back/src/push-tokens/push-tokens.service.ts` enforcing the single-active-token-per-user invariant: `register(userId, dto)`, `refresh(id, userId, dto)`, `tombstone(id, userId)`, `tombstoneActiveForUser(userId)`, `findActiveForUserIds(userIds)`. Hashing via `crypto.createHash('sha256')`.
- [X] T019 [P] Create `back/src/push-tokens/push-tokens.controller.ts` exposing `POST/PATCH/DELETE/GET /me/push-tokens` per `contracts/push-tokens.md`. All endpoints `@UseGuards(JwtAuthGuard)`; no role guard (always self-scoped). Register `@ApiTags('Push Tokens')`.
- [X] T020 [P] Create `back/src/push-tokens/push-tokens.module.ts` registering schema, service, controller, and exporting `PushTokensService` (so `DevicesService` and `NotificationsService` can import it).
- [X] T021 Create `back/src/notifications/notifications.module.ts`: register schemas, import `PushTokensModule`, declare service/controller stubs (will be filled in US1+ phases), export `NotificationsService`.
- [X] T022 Edit `back/src/app.module.ts`: add `NotificationsModule` and `PushTokensModule` to `imports`. Confirm Swagger picks them up at `/api`.
- [X] T023 Edit `back/src/devices/devices.service.ts::resetDevice(userId)` per `contracts/push-tokens.md` "Cross-module coordination": after the existing `findOneAndUpdate` on `deviceModel`, call `this.pushTokensService.tombstoneActiveForUser(userId)`. Add `PushTokensService` constructor injection. Update `back/src/devices/devices.module.ts` to import `PushTokensModule`.

### Flutter foundations

- [X] T024 Create `na_app/lib/core/notifications/firebase_bootstrap.dart`: `Future<void> initialize()` that calls `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` and registers the iOS-specific foreground presentation options to suppress the OS-level banner. Insert call into `na_app/lib/main.dart` **before** `runApp()`.
- [X] T025 [P] Create top-level function `_firebaseMessagingBackgroundHandler(RemoteMessage message)` in `na_app/lib/core/notifications/push_message_handler.dart` and register it via `FirebaseMessaging.onBackgroundMessage(...)` inside `firebase_bootstrap.dart`. The handler does a single `drift` upsert into `notifications_inbox` and returns; no other side effects.
- [X] T026 [P] Add two new `drift` tables `NotificationsInbox` and `NotificationsUnreadIndex` to `na_app/lib/core/storage/app_database.dart` (or wherever 004's drift database lives) per `data-model.md` "Client-side cache" section. Bump the schema version and add a migration step that creates the tables with their indexes. Run `dart run build_runner build --delete-conflicting-outputs`.
- [X] T027 Create `na_app/lib/core/notifications/local_notifications.dart`: register the Android channel `na_academy_default` (importance high), expose `showForegroundBanner(title, body)` that uses `flutter_local_notifications` for Android in-foreground and a custom `OverlayEntry` for iOS (parchment palette, fade-in if `MediaQuery.disableAnimations`).
- [X] T028 Create `na_app/lib/core/notifications/push_token_registrar.dart`: methods `registerOnLogin()`, `refreshToken(String newToken)`, `unregisterOnLogout()`. Wires `FirebaseMessaging.instance.onTokenRefresh` listener; persists the server-returned token id in `flutter_secure_storage` under key `push_token_id`. Calls into a new `PushTokensApi` client (T029).
- [X] T029 [P] Create `na_app/lib/core/notifications/push_tokens_api.dart` (dio client over `/me/push-tokens`) with typed methods matching `contracts/push-tokens.md`. Use existing dio instance from `na_app/lib/core/api/` (or wherever the project's dio singleton lives).
- [X] T030 Create `na_app/lib/features/notifications/data/models/notification_dto.dart` and `notification_recipient_dto.dart` as `freezed` classes mirroring `InboxItemDto` and `RecipientStateDto` from `contracts/notifications.md`. Run `build_runner` codegen.
- [X] T031 [P] Create `na_app/lib/features/notifications/data/notifications_local_data_source.dart` exposing drift DAO: `upsert(Notification)`, `markRead(id)`, `markAllRead()`, `getInboxStream()`, `getUnreadCountStream()`, `getById(id)`.
- [X] T032 [P] Create `na_app/lib/features/notifications/data/notifications_remote_data_source.dart` (dio over `/notifications/me`, `/notifications/me/:id/read`, `/notifications/me/read-all`).
- [X] T033 Create `na_app/lib/features/notifications/data/notifications_repository.dart`: offline-first read (drift), background refresh (network), merge by `id`. Includes a `pendingReadAcks` queue (reuse 004's pending-sync infra) so mark-as-read survives offline.
- [X] T034 [P] Create `na_app/lib/features/notifications/domain/entities/notification.dart` (Dart entity, not freezed) and `domain/usecases/{load_inbox, mark_as_read, mark_all_as_read, observe_unread_count}.dart`.

### Cross-cutting

- [X] T035 [P] Create `back/src/notifications/dto/validators/no-secrets.validator.ts`: `@NoSecretsInBody()` decorator that fails the body validation if it matches credential-shaped patterns (OTP-like 6-digit codes adjacent to "code"/"OTP", JWT-like `eyJ...`, `Bearer `, `password=`). Used by `CreateNotificationDto`.
- [X] T036 [P] Add localization strings for the inbox and foreground banner to `na_app/assets/translations/en.json` and `na_app/assets/translations/ar.json` under a new `notifications.*` namespace (`inbox_title`, `empty_state`, `mark_all_read`, `now`, `mins_ago`, `today`, `yesterday`, `permission_denied_explainer`).

**Checkpoint**: Foundation ready. The backend schemas + push-token endpoints are live (so a Flutter dev can register tokens). The Flutter Firebase bootstrap is wired so push messages can arrive (but no inbox UI yet). US1 (admin send) and US2 (inbox UI) can now proceed in parallel.

---

## Phase 3: User Story 1 — Admin broadcasts to all students (Priority: P1) 🎯 MVP-half-1

**Goal**: An admin opens the dashboard, composes a notification with audience = "All users", clicks Send, and within 5 seconds every connected student device receives an OS-level push.

**Independent Test**: With one admin user and one logged-in student device, an admin-side `POST /notifications` with `audience.kind = 'all'` results in (a) the admin getting `201 Created` with the notification id, (b) the student device getting an OS push within ~5 s, (c) the `Notification.stats.delivered` counter incrementing for that user.

### Backend

- [X] T037 [US1] Create `back/src/notifications/audience-resolver.service.ts` with method `resolveAll(currentUserRole)`: returns `User._id[]` of every active student. Stub `resolveUserList()` and `resolveSubject()` to throw `NotImplementedException` for now (filled in US3). Inject `UsersService` to query `User.find({ status: 'active', role: 'student' })`.
- [X] T038 [US1] Implement `back/src/notifications/notifications.service.ts::send(senderId, senderRole, dto, idempotencyKey)`:
  1. Look up by `(senderId, idempotencyKey)`; if found, return existing notification (idempotent replay).
  2. RBAC: admin → any kind; teacher → only kind `subject` (raise `ForbiddenException` for kind=all here).
  3. Resolve audience → `resolvedUserIds`. Reject `422 audience-empty` if empty.
  4. Insert `Notification` document (snapshot audience, idempotency key, sender info, initial stats).
  5. Bulk-insert `NotificationRecipient` rows (state=`pending`).
  6. Look up active push tokens via `PushTokensService.findActiveForUserIds(resolvedUserIds)`. Mark recipients with no active token as `failed` / `no-active-token`.
  7. Call `FcmService.sendBatch(tokens, { title, body, data })`. Map per-token success → `delivered`; per-token error code → `failed` + `failureReason`.
  8. Recompute `Notification.stats` and persist.
  9. Return the populated `NotificationResponseDto`.
- [X] T039 [US1] Create `back/src/notifications/notifications.controller.ts::POST /notifications`: `@Roles(UserRole.ADMIN, UserRole.TEACHER)`, `@UseGuards(JwtAuthGuard, RolesGuard)`. Read `Idempotency-Key` header (validate UUID v4; 400 on missing/malformed). Pass through to `NotificationsService.send`. Async branch: respond `202 Accepted` after step 5 if `resolvedRecipientCount > 1000`; otherwise `201 Created` after step 8. Register `@ApiTags('Notifications')`, `@ApiOperation`, `@ApiHeader('Idempotency-Key')`.
- [X] T040 [US1] Add Swagger schemas for the four DTOs created in Phase 2 (`@ApiProperty` decorators) on the response/request types so `/api` shows the full shape.
- [X] T041 [US1] Wire audit log in `notifications.service.ts::send`: on success, write `notifications.send` row with `{ senderId, audienceDescriptor, titleHash, bodyHash, idempotencyKey, resolvedRecipientCount }` via the existing logging interceptor / Logger pattern used by `back/src/exams/`.
- [X] T042 [US1] Add per-route throttler override `@Throttle({ default: { limit: 30, ttl: 60_000 } })` on `POST /notifications`.

### Admin dashboard (US1 surface = composer with audience=all only)

- [X] T043 [P] [US1] Create `admin-dashboard/src/services/notifications.api.ts`: typed client with `sendNotification(dto, idempotencyKey)` returning `NotificationResponseDto`. Generates a UUID v4 per submit. Uses the existing `axios` instance from `admin-dashboard/src/services/api.ts`.
- [X] T044 [P] [US1] Create `admin-dashboard/src/types/notifications.ts` with TypeScript mirrors of all DTOs from `contracts/notifications.md` (`AudienceKind`, `AudienceDto`, `CreateNotificationDto`, `NotificationResponseDto`, `NotificationStatsDto`, `InboxItemDto`, etc.). These are the canonical client types — no parallel ad-hoc definitions elsewhere.
- [X] T045 [US1] Create `admin-dashboard/src/components/NotificationComposer.tsx`: react-hook-form + zod schema (title 1–100, body 1–1000, optional `data` JSON textarea). Shadcn UI components, parchment palette, Fraunces display heading, pill primary "Send" button. For US1, the audience is hard-fixed to `{ kind: 'all' }` — the AudiencePicker comes in US3. Submit handler calls `notifications.api.ts::sendNotification` with a fresh UUID; on success, toast + reset form.
- [X] T046 [US1] Create `admin-dashboard/src/pages/NotificationsSendPage.tsx` rendering the `NotificationComposer`. Layout uses existing `AdminLayout`.
- [X] T047 [US1] Create `admin-dashboard/src/pages/NotificationsPage.tsx`: a tab container (or simple route group) with one tab "Send" (US1) — placeholder "History" tab disabled until US4. Add route `/notifications` to `admin-dashboard/src/App.tsx` (or wherever `react-router-dom` routes are defined). Add a sidebar nav entry in `admin-dashboard/src/components/AdminLayout.tsx`.

**Checkpoint**: Admin can broadcast to all users. Per-recipient state is persisted on the server but not yet visible in the dashboard (history view is US4). The student device receives the OS push (via the Phase 2 push-token registrar + FCM fan-out), but the in-app inbox UI is US2's job — until US2 ships, the message is only visible as the OS notification.

---

## Phase 4: User Story 2 — Student in-app inbox (Priority: P1) 🎯 MVP-half-2

**Goal**: A student opens the bell icon on the home screen and sees every notification ever sent to them, in reverse-chronological order, with read/unread state, even when offline. Tapping a row opens a detail view and marks the item read; the badge count decrements.

**Independent Test**: With seed data of 5 notifications previously delivered to a student account, opening the inbox shows all 5 in correct order; tapping one marks it read on the server; opening the inbox in airplane mode still shows the cached items.

### Backend (read endpoints)

- [X] T048 [US2] Add `GET /notifications/me` to `back/src/notifications/notifications.controller.ts`: `@UseGuards(JwtAuthGuard)`, query `?limit=20&before=<ISO>`. Service method `getInbox(userId, limit, before)` joins `NotificationRecipient` (where `userId` matches and `notificationId` matches) with the parent `Notification` doc, ordered by `Notification.createdAt DESC`. Returns `InboxResponseDto` including a freshly-computed `unreadCount`.
- [X] T049 [US2] Add `PATCH /notifications/me/:id/read` to controller. Service `markRead(userId, notificationId)`: idempotent set of `readAt = now()` on the matching recipient row; recompute `Notification.stats.read`. 404 if no matching row.
- [X] T050 [US2] Add `POST /notifications/me/read-all` to controller. Service `markAllRead(userId)`: bulk update where `userId = current` and `readAt is null`; recompute affected notifications' `stats.read` (via `bulkWrite`). Return `{ markedRead: number }`.

### Flutter inbox (data → UI)

- [X] T051 [US2] Create `na_app/lib/features/notifications/presentation/controllers/inbox_controller.dart` (riverpod): exposes `inboxStreamProvider` (drift stream of cached items merged with periodic remote refresh), `unreadCountProvider`, and methods `markRead(id)`, `markAllRead()`, `refresh()`.
- [X] T052 [P] [US2] Create `na_app/lib/features/notifications/presentation/widgets/notification_row.dart` (parchment background, Fraunces title at body-large size, Inter snippet, relative-time pill, unread dot when `readAt == null`). Touch target ≥44pt.
- [X] T053 [P] [US2] Create `na_app/lib/features/notifications/presentation/widgets/unread_badge.dart`: a riverpod-watcher around `unreadCountProvider`, renders a small Sage-Teal pill with the count when > 0; nothing otherwise. Reusable from the home screen and any other surface.
- [X] T054 [P] [US2] Create `na_app/lib/features/notifications/presentation/widgets/foreground_notification_banner.dart`: parchment-palette banner overlay, slides in (or fades if `MediaQuery.of(context).disableAnimations`), auto-dismisses in 5 s, tappable → opens detail page.
- [X] T055 [US2] Create `na_app/lib/features/notifications/presentation/pages/notifications_inbox_page.dart`: AppBar with "Mark all as read" action; ListView.separated of `NotificationRow` widgets bound to `inboxStreamProvider`; pull-to-refresh wired to `inbox_controller.refresh()`; empty state illustration + localized copy; offline banner if `Connectivity().checkConnectivity()` reports none.
- [X] T056 [P] [US2] Create `na_app/lib/features/notifications/presentation/pages/notification_detail_page.dart`: Fraunces title (display tier), Inter body (long-read line-height), absolute timestamp pill, optional payload action button if `data` contains a recognized deep-link target. On open, calls `inbox_controller.markRead(id)`.
- [X] T057 [US2] Add a `notifications` go_router route in `na_app/lib/core/router/` mapping `/notifications` → `NotificationsInboxPage` and `/notifications/:id` → `NotificationDetailPage`.
- [X] T058 [US2] Edit `na_app/lib/features/home/presentation/pages/home_screen.dart` lines around the existing bell-icon `Tooltip` (currently around line 75): wrap the bell with a `Stack` overlaid by `UnreadBadge`; wrap the bell tap in a `GestureDetector` (or `IconButton` if not already) that pushes `/notifications`. Touch target ≥44pt.
- [X] T059 [US2] Edit `na_app/lib/core/notifications/push_message_handler.dart`: complete the foreground (`onMessage`), opened-from-background (`onMessageOpenedApp`), and cold-start (`getInitialMessage`) handlers. Each path:
  1. Upserts into `notifications_inbox` (foreground only — background isolate already did this).
  2. If foreground: shows the in-app banner via `local_notifications.dart::showForegroundBanner`.
  3. If user-tap (background-opened or cold-start): inspects `data.type` and routes via `go_router` (`exam` → `/exams/:id`, `subject` → `/subjects/:id`, `lesson` → `/lessons/:id`, `url` → external `url_launcher`, default → `/notifications/:id`).
- [X] T060 [US2] Edit `na_app/lib/features/profile/presentation/pages/settings_page.dart` so the existing `notificationsEnabled` toggle does an OS-permission check on `onAppResumed` and reflects the OS state. Replace the "Daily 7:00 PM" placeholder under `profile_screen.dart:52-54` with a real link to `/notifications`.
- [X] T061 [US2] Wire `push_token_registrar.registerOnLogin()` from the existing auth-success path in `na_app/lib/features/auth/` (find login success controller; insert call after JWT is persisted). Wire `unregisterOnLogout()` from the logout path. Verify on app launch that the registrar runs once if the user is already authenticated.

**Checkpoint**: Students see their inbox with correct read/unread state, online and offline. Combined with US1, the **MVP is functional**: an admin broadcasts → student receives push and sees the inbox entry. Stop-and-validate point.

---

## Phase 5: User Story 3 — Targeted send (specific users / subject) (Priority: P2)

**Goal**: An admin (or, with restrictions, a teacher) can send a notification to a hand-picked list of users or to all enrolled students of a specific subject. Teachers see only their own subjects in the audience picker.

**Independent Test**: An admin sends with `audience.kind = 'subject'`, `subjectId = <Algebra 101>`; only enrolled students of Algebra 101 receive the push and inbox entry. A teacher who owns Algebra 101 successfully sends; a teacher who does not own it receives `403 audience-forbidden`.

### Backend

- [X] T062 [US3] Implement `back/src/notifications/audience-resolver.service.ts::resolveUserList(userIds)`: validates each id is an active user; returns intersection. Throws `NotFoundException` for any missing/inactive user.
- [X] T063 [US3] Implement `back/src/notifications/audience-resolver.service.ts::resolveSubject(subjectId, currentUserId, currentUserRole)`:
  1. Load `Subject` by id; 404 if missing.
  2. Teacher path: enforce `subject.createdBy.toString() === currentUserId.toString()`; throw `ForbiddenException('audience-forbidden')` otherwise.
  3. Resolve enrollment: `User.find({ status: 'active', role: 'student', assignedSubjects: subjectId })._id`. (Field already exists on `User` schema per `back/src/users/schemas/user.schema.ts:41-42`.)
- [X] T064 [US3] Update `back/src/notifications/notifications.service.ts::send` to dispatch on `dto.audience.kind`: `all` → `resolveAll`, `user-list` → `resolveUserList`, `subject` → `resolveSubject`. Update the role check inside the service: admin OK on any kind; teacher OK only on `subject`.
- [X] T065 [US3] Add `GET /subjects/me/teaching` endpoint (or extend existing `GET /subjects` with a `?ownerOnly=true` query) in `back/src/subjects/subjects.controller.ts` so the dashboard can list a teacher's owned subjects for the picker. If a similar endpoint already exists, reuse it; otherwise add the smallest possible new route under existing `SubjectsModule`.
- [X] T066 [US3] Add `GET /users/search?q=<term>&limit=20` endpoint in `back/src/users/users.controller.ts` (admin-only) for the user-list picker. Searches `name` and `email` (case-insensitive prefix). Returns `{ id, name, email, role }[]` capped at 20.

### Admin dashboard

- [X] T067 [US3] Create `admin-dashboard/src/components/AudiencePicker.tsx`:
  - Tab-style selector: `All users` | `Specific users` | `Subject`.
  - For admins: all three tabs visible.
  - For teachers: only `Subject` tab; the subject dropdown is filtered to subjects from `GET /subjects/me/teaching`.
  - `Specific users` tab: debounced search input (350 ms) calling `GET /users/search`; results render as a list; selected users appear as removable chips. Cap at 1000 selected (matches DTO bound).
  - `Subject` tab: dropdown populated from the teaching/owned-subjects endpoint.
  - Returns `AudienceDto`-shaped state via `react-hook-form` controller.
- [X] T068 [US3] Update `admin-dashboard/src/components/NotificationComposer.tsx` from US1 to embed the `AudiencePicker`. Replace the hard-coded `{ kind: 'all' }` with the picker's value. Validate via the existing zod schema (extend it to mirror the discriminated union).
- [X] T069 [P] [US3] Update `admin-dashboard/src/services/notifications.api.ts` and `admin-dashboard/src/types/notifications.ts` if needed so the types correctly model the discriminated audience union. (No new endpoints; just the type refinement.)
- [X] T070 [US3] Add a `useCurrentUserRole()` hook in `admin-dashboard/src/hooks/` (or extend an existing auth hook) so `AudiencePicker` can branch admin vs teacher cleanly.

**Checkpoint**: All audience kinds work end-to-end. Teacher restriction holds at both the dashboard UI layer (only the Subject tab) and the backend (server-side ownership check is the source of truth).

---

## Phase 6: User Story 4 — Admin send-history & detail drawer (Priority: P3)

**Goal**: An admin opens the "Notifications → History" tab, browses every send (paginated, searchable), and drills into any one to see full content, audience, and per-recipient delivery state — including a graceful "archived" notice for sends older than 365 days.

**Independent Test**: After 25 sends across the system, the history list paginates correctly, keyword search returns the right entries, the detail drawer of a recent send shows per-recipient state, and the detail drawer of a >365-day-old send shows aggregate counts plus the archived notice.

### Backend

- [X] T071 [US4] Add `GET /notifications` to `back/src/notifications/notifications.controller.ts`: `@Roles(UserRole.ADMIN, UserRole.TEACHER)`. Service method `listHistory(currentUserId, currentUserRole, query)`: admin → all; teacher → `senderId = currentUserId`. Accepts `NotificationListQueryDto` (`q`, `audienceKind`, `subjectId`, `before`, `limit`). For `q`, uses the text index from T008 (`$text: { $search: q }`) ranked by `$meta: 'textScore'`.
- [X] T072 [US4] Add `GET /notifications/:id` to controller: admin (any) or teacher (sender-of-this-notification only); 403 otherwise; 404 if not found. Service method `getDetail(id, currentUserId, currentUserRole)`: returns `NotificationDetailResponseDto`. Decide `recipientsArchived`: if `now - notification.createdAt > 365 days`, omit the recipients array, set `recipientsArchived: true`, `recipientsArchivedAt = lastPruneRunAt` (read from a lightweight `notification_retention_runs` collection or compute as `notification.createdAt + 365 days` for simplicity).
- [X] T073 [US4] Create `back/src/notifications/retention.service.ts` with a `@Cron(CronExpression.EVERY_DAY_AT_3AM)` method `pruneExpiredRecipients()`: deletes `NotificationRecipient` rows where parent `notification.createdAt < now - 365d`. Implementation: aggregate-then-delete to avoid loading all parent docs. Also prune `PushToken` rows where `tombstonedAt < now - 30d`. Log row counts at info level. Skip the run silently in non-production environments unless `RETENTION_FORCE_RUN=true`.
- [X] T074 [US4] Register `ScheduleModule.forRoot()` in `back/src/app.module.ts` (if not already from T001) and add `RetentionService` to `NotificationsModule.providers`.

### Admin dashboard

- [X] T075 [US4] Create `admin-dashboard/src/pages/NotificationsHistoryPage.tsx`: paginated list (default 20/page) ordered by sent timestamp DESC. Columns: Title, Audience descriptor (e.g., `Subject: Algebra 101 — 42 recipients`), Sender, Sent at, Delivered/Total, Read. Search field at the top (debounced 350 ms) wired to `?q=`. "Load more" button using cursor-based `?before=`.
- [X] T076 [P] [US4] Create `admin-dashboard/src/components/NotificationDetailDrawer.tsx`: opens on row click. Shows full title (Fraunces display), full body, optional `data` payload (rendered as a `<pre>` block), audience descriptor, sender, sent-at, aggregate counts. If `recipientsArchived` is true, shows an "Archived: per-recipient delivery details cleared on <date>" notice instead of the recipient list. Otherwise, shows a virtualized recipient list with state pill (`delivered` / `failed` / `read`) and per-recipient timestamps.
- [X] T077 [US4] Add `notifications.api.ts::listNotifications(query)` and `getNotification(id)` to `admin-dashboard/src/services/notifications.api.ts` (extends US1's API client).
- [X] T078 [US4] Wire the History tab in `NotificationsPage.tsx` (US1's T047) so it now points to `NotificationsHistoryPage`. Add the detail drawer trigger.

**Checkpoint**: Full feature complete. Admin can audit any send, including archived ones. Storage growth bounded by retention (FR-029).

---

## Phase N: Polish & Cross-Cutting Concerns

- [ ] T079 [P] Run `npm run lint` in `back/` and fix any violations introduced by this feature.
- [ ] T080 [P] Run `npm run lint` and `tsc -b` in `admin-dashboard/` and fix violations.
- [ ] T081 [P] Run `flutter analyze` in `na_app/` and fix violations.
- [ ] T082 [P] Verify Constitution Principle I conformance on every new screen/component: `admin-dashboard/src/pages/NotificationsSendPage.tsx`, `NotificationsHistoryPage.tsx`, `components/NotificationComposer.tsx`, `AudiencePicker.tsx`, `NotificationDetailDrawer.tsx`, and Flutter `notifications_inbox_page.dart`, `notification_detail_page.dart`, `notification_row.dart`, `unread_badge.dart`, `foreground_notification_banner.dart`. Checklist: parchment palette, Fraunces in display tier only, Inter elsewhere, ≤10% Sage-Teal accent, pill primary buttons, 12–18px radii, no pure black or pure white on large surfaces.
- [ ] T083 [P] Verify Constitution Principle V on `na_app/`: every interactive element on inbox + detail pages has hit-target ≥ 44×44 pt; reduced-motion is honored on the foreground banner; no low-contrast grey-on-grey body text.
- [ ] T084 Add Swagger examples (`@ApiResponse({ schema: { example: ... } })`) for the four most common request/response shapes in `back/src/notifications/notifications.controller.ts` so the `/api` page is self-documenting.
- [ ] T085 [P] Add `notifications.*` translations review pass in `na_app/assets/translations/ar.json` (RTL spacing, Arabic line-height for body). Native speaker review optional but recommended.
- [ ] T086 Run the end-to-end flow from `quickstart.md` §4 on a real device (or emulator) for both Android and iOS; record any deviations and patch the docs or code accordingly.
- [ ] T087 [P] Add a `notifications` section to `back/README.md` documenting the FCM service-account env wiring, the `Idempotency-Key` requirement, and the retention sweep cadence.
- [ ] T088 [P] Final pass: search the repo for any stray `[NEEDS CLARIFICATION]` or TODO markers introduced by this feature and resolve or convert to follow-up tickets.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: no dependencies — start immediately.
- **Phase 2 (Foundational)**: depends on Phase 1. **Blocks all user stories.**
- **Phase 3 (US1 — Admin broadcast)**: depends on Phase 2. Can run in parallel with Phase 4 (US2) once Phase 2 completes.
- **Phase 4 (US2 — Inbox)**: depends on Phase 2. Can run in parallel with Phase 3.
- **Phase 5 (US3 — Targeted)**: depends on Phase 3 (US1's `notifications.service.ts`, controller, composer all exist). Can start once US1 is done; does not block on US2.
- **Phase 6 (US4 — History)**: depends on Phase 3 (the `Notification` schema is the source of history; the controller pattern is established). Can run in parallel with Phase 5 if staffed.
- **Phase N (Polish)**: depends on all desired user-story phases being complete.

### User Story Dependencies

- **US1 + US2 together = the MVP.** Either can be built first; neither blocks the other once Phase 2 is done.
- **US3** extends US1's send path with new audience kinds + the picker UI. Independent of US2.
- **US4** extends US1's persistence with a list/detail read path + retention cron. Independent of US2 and US3.

### Within Each User Story

- Backend schemas → DTOs → services → controllers → wire-up.
- Models / data sources before repositories before controllers (Flutter, Riverpod-style).
- Wire-up tasks (the ones that edit existing files like `app.module.ts`, `home_screen.dart`, the dashboard router) should be the last steps of their phase.

### Parallel Opportunities

- **Phase 1**: T002–T007 are all `[P]` — surface-independent prep.
- **Phase 2**: T009, T010, T012, T013, T014, T015, T016, T019, T020 are `[P]`. T024 is sequential (must complete before T025/T026 start). T029, T031, T032, T034 are `[P]`.
- **Phase 3 (US1)**: T043, T044 are `[P]` (different files; no dependency on each other).
- **Phase 4 (US2)**: T052, T053, T054, T056 are `[P]`. T058–T061 are wire-ups, sequential at the end.
- **Phase 5 (US3)**: T069 is `[P]`.
- **Phase 6 (US4)**: T076 is `[P]`.
- **Phase N (Polish)**: T079, T080, T081, T082, T083, T085, T087, T088 are `[P]`.

---

## Parallel Example: Phase 2 foundational schemas + DTOs

```bash
# After T008 (notifications schema), launch these in parallel:
Task: "Create back/src/notifications/schemas/notification-recipient.schema.ts (T009)"
Task: "Create back/src/push-tokens/schemas/push-token.schema.ts (T010)"
Task: "Create back/src/notifications/dto/create-notification.dto.ts (T012)"
Task: "Create back/src/notifications/dto/notification-response.dto.ts (T013)"
Task: "Create back/src/notifications/dto/recipient-state.dto.ts (T014)"
Task: "Create back/src/notifications/dto/notification-list-query.dto.ts (T015)"
Task: "Create back/src/push-tokens/dto/{register-token,token-response}.dto.ts (T016)"
```

## Parallel Example: Phase 4 (US2) widgets

```bash
# After T051 (inbox controller), launch these in parallel:
Task: "Create na_app/lib/features/notifications/presentation/widgets/notification_row.dart (T052)"
Task: "Create na_app/lib/features/notifications/presentation/widgets/unread_badge.dart (T053)"
Task: "Create na_app/lib/features/notifications/presentation/widgets/foreground_notification_banner.dart (T054)"
Task: "Create na_app/lib/features/notifications/presentation/pages/notification_detail_page.dart (T056)"
```

---

## Implementation Strategy

### MVP First (US1 + US2)

1. Complete Phase 1: Setup (T001–T007).
2. Complete Phase 2: Foundational (T008–T036). Critical — blocks everything.
3. Complete Phase 3 (US1) and Phase 4 (US2). These can run in parallel if you have two developers.
4. **STOP and VALIDATE**: end-to-end smoke test from `quickstart.md` — admin broadcasts to all → student receives push → opens inbox → marks read.
5. Demo / deploy if ready.

### Incremental Delivery After MVP

1. Layer in Phase 5 (US3 — targeted send) → demo subject targeting + teacher RBAC.
2. Layer in Phase 6 (US4 — history & detail drawer) → demo audit view + retention cron.
3. Run Phase N (polish + constitution conformance) → open PR.

### Parallel Team Strategy

With two or three developers:

1. **All hands on Phase 1 + Phase 2** (one day to one and a half).
2. After T036 checkpoint:
   - Developer A: Phase 3 (US1 — admin broadcast).
   - Developer B: Phase 4 (US2 — student inbox).
   - Developer C (optional): on-deck for Phase 5 the moment Phase 3 ships its `notifications.service.ts`.
3. After both P1 stories ship: split Phase 5 (US3) and Phase 6 (US4) across two developers; they share no files.
4. Polish phase as a team.

---

## Notes

- `[P]` = independent file, no dependency on incomplete tasks.
- `[Story]` = traceability back to the user story in `spec.md`.
- Each phase ends in a checkpoint where the system is **demoable**. Stop at any checkpoint.
- The `Notification` schema's `text` index on `(title, body)` is added in T008; the search query in T071 depends on it being present.
- The single-active-token invariant in `PushToken` (T010 partial-unique index + T018 service logic) is what guarantees no cross-account push leakage during device handoff. Do not weaken it without revisiting the `devices` module's contract.
- Avoid: adding a new "course" entity (research.md Decision 3) — use the existing `Subject` collection. Avoid: storing FCM tokens on the `Device` schema (research.md Decision 4) — the `push_tokens` collection is intentionally separate.
- Commit after each task or each logical group (a phase, an entity + its DTO, a controller + its service).
