---
description: "Task list for feature 003-mobile-app-redesign — NA-Academy Mobile App (Scholarly Sanctuary)"
---

# Tasks: NA-Academy Mobile App (Scholarly Sanctuary)

**Input**: Design documents from `/specs/003-mobile-app-redesign/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api-contracts.md, quickstart.md

**Tests**: Test tasks are included ONLY for the single integration happy-path mandated in plan.md (`flutter_test` + `integration_test` for Splash → Register → unlock-subject) and for the two backend modules that add new business logic (auth reset + per-answer autosave). No contract tests are generated (contracts live in `api-contracts.md`). All other testing is left to the Polish phase.

**Organization**: Tasks are grouped by user story from spec.md so each P1 slice can be delivered independently. Backend gaps B1–B6 from `contracts/api-contracts.md` are embedded in the user-story phase that depends on them — each backend task is the merge-order prerequisite for the mobile tasks in the same phase.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile**: `na_app/lib/...` (Flutter — Dart 3.11, Riverpod + go_router + Dio + socket_io_client)
- **Backend**: `back/src/...` (NestJS 11 — additions to existing modules plus one new `mail` module)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Wire the Flutter app skeleton (deps, entrypoint, theme tokens, core plumbing) and confirm the backend is ready to accept the additions in later phases. None of these tasks require writing any user-visible UI.

- [x] T001 Add mobile dependencies to `na_app/pubspec.yaml`: `go_router ^14`, `flutter_riverpod ^2` + `riverpod_annotation` + `riverpod_generator` + `build_runner`, `dio ^5`, `socket_io_client ^2`, `flutter_secure_storage ^9`, `shared_preferences ^2`, `cached_network_image ^3`, `image_picker ^1`, `video_player ^2`, `chewie ^1`, `app_links ^6`, `device_info_plus ^10`, `logger ^2`, `freezed` + `freezed_annotation` + `json_serializable` + `json_annotation`, then run `flutter pub get`.
- [x] T002 [P] Add backend mail dependencies to `back/package.json`: `@nestjs-modules/mailer` and `nodemailer`; run `npm install` in `back/`.
- [x] T003 [P] Create Scholarly Sanctuary colour tokens in `na_app/lib/core/theme/app_colors.dart` (parchment `#F4EFE5`, ink `#1F1C16`, sage-teal `#3F7D78`, clay `#B06A43`, border-subtle `#E0D8C6`, dark-mode counterparts).
- [x] T004 [P] Create typography tokens in `na_app/lib/core/theme/app_typography.dart` using `google_fonts` (Fraunces for display/headline, Inter for body/UI, JetBrains Mono for `labelMono`).
- [x] T005 [P] Create shape tokens in `na_app/lib/core/theme/app_shapes.dart` (pill radius 999, card radius 18, hairline bone border) and motion helpers in `na_app/lib/core/theme/app_motion.dart` that read `MediaQuery.disableAnimations` and degrade transitions per FR-036.
- [x] T006 [P] Assemble `ThemeData` in `na_app/lib/core/theme/app_theme.dart` exposing `lightTheme()` and `darkTheme()` that consume T003–T005 tokens (no raw hex, satisfies Principle I).
- [x] T007 [P] Create API endpoint constants in `na_app/lib/core/api/endpoints.dart` for every route listed in `contracts/api-contracts.md` (auth, users, subjects, exams, activation-codes, chat, media, analytics).
- [x] T008 [P] Create Dio client skeleton in `na_app/lib/core/api/dio_client.dart` reading `API_BASE_URL` via `dart-define`; create `na_app/lib/core/api/api_exception.dart` sealed type (`ApiException { statusCode, code, message }`) for FR-034 normalised errors.
- [x] T009 [P] Create secure token store in `na_app/lib/core/storage/secure_token_store.dart` (wraps `flutter_secure_storage` for `accessToken`, `refreshToken`).
- [x] T010 [P] Create hardware-id store in `na_app/lib/core/storage/hardware_id_store.dart` — generates a UUID v4 on first read and persists in secure storage (research §9, data-model §1.2).
- [x] T011 [P] Create prefs store in `na_app/lib/core/storage/prefs_store.dart` using `shared_preferences` for `themeMode`, `language`, `notificationsEnabled`, `lastKnownUserName`.
- [x] T012 [P] Create utility helpers in `na_app/lib/core/utils/time_of_day_greeting.dart`, `na_app/lib/core/utils/time_ago.dart`, and `na_app/lib/core/utils/result.dart` (sealed `Result<T, E>`).
- [x] T013 Rewrite `na_app/lib/main.dart` to wrap the app in `ProviderScope` and use `MaterialApp.router` bound to a stub `app_router.dart` (full router comes in T015); confirm `flutter run` boots to a blank scaffold using the new theme.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Plumbing every user story depends on: the auth interceptor with refresh, the router with guards, the realtime socket wrapper, and the design-system primitive widgets. Until this phase is complete, no user-story UI can be built.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T014 Implement Dio interceptors in `na_app/lib/core/api/dio_client.dart` — request interceptor attaches `Authorization: Bearer <access>`; response interceptor catches 401, queues concurrent retries through a single `Completer<void>`, calls `POST /auth/refresh`, replays queued requests, and on refresh failure clears tokens and emits a `sessionExpired` event (FR-003, research §4).
- [ ] T015 Implement full `go_router` tree with auth-guard redirect in `na_app/lib/core/router/app_router.dart` — routes for every screen listed in `plan.md` project structure, plus a top-level redirect that sends unauthenticated users to `/splash` (FR-028).
- [ ] T016 [P] Implement deep-link handler in `na_app/lib/core/router/deep_link_handler.dart` using `app_links` — maps `naacademy://auth/reset?token=<t>` and `https://naacademy.app/reset?token=<t>` onto `/auth/reset-password?token=<t>` (FR-004b).
- [ ] T017 [P] Implement Socket.IO wrapper in `na_app/lib/core/realtime/chat_socket.dart` — connects to `<baseUrl>/chat` with `auth.token = <access>`, exposes typed streams for `new_message`, `status_update`, `conversation_read`, `typing_indicator`, `pending_messages`, and reconnect with access-token refresh (research §3, contracts §6).
- [ ] T018 [P] Build primitive widgets in `na_app/lib/core/widgets/`: `button.dart` (pill primary/secondary/ghost), `card.dart` (hairline bone border, radius 18), `list_row.dart`, `chip.dart`, `empty_state.dart`, `section_header.dart`, `app_bar_x.dart`, `bottom_sheet_x.dart`, `progress_ring.dart`, `score_ring.dart`, `typing_indicator.dart`, `streaming_cursor.dart` — all consume theme tokens only (FR-029/FR-030).
- [ ] T019 [P] Build 6-cell `CodeInputField` in `na_app/lib/core/widgets/code_input.dart` — six `TextField`s in a `FocusTraversalGroup`, auto-advance on keystroke, backspace-at-empty focuses previous cell, paste distributes across cells, rejects non-alphanumeric, JetBrains Mono (FR-007, research §6).
- [ ] T020 Create auth Riverpod notifier in `na_app/lib/features/auth/presentation/controllers/auth_controller.dart` and `na_app/lib/features/auth/data/auth_repository.dart` — methods `login`, `register`, `logout`, `refresh`, `bootstrap`; exposes `AsyncValue<AuthSession?>` that T015's redirect consumes (data-model §1.2).
- [ ] T021 [P] Create `User` and `AuthSession` freezed models in `na_app/lib/features/auth/domain/auth_models.dart` with `fromJson`/`toJson` matching `contracts §1–§2`.
- [ ] T022 Build the 5-tab pill bar shell in `na_app/lib/core/widgets/app_shell.dart` (Today, Subjects, Exams, Chat, Profile) with haptic feedback on tab change and icon-only active pill in sage-teal (FR-027); wire via `StatefulShellRoute` in T015's router.
- [ ] T023 [P] Configure `custom_lint` in `na_app/analysis_options.yaml` to forbid raw `Color(0x…)` and direct `Colors.*` references inside `lib/features/` (Principle I enforcement).

**Checkpoint**: Foundation ready — user story implementation can now begin.

---

## Phase 3: User Story 1 — Unlock and study a subject with a code (Priority: P1) 🎯 MVP

**Goal**: A signed-in student sees a subjects grid with locked cards, enters a 6-char subject code, watches the unlocking transition, and lands on a subject detail screen where lessons are browsable.

**Independent Test**: From a fresh install, sign in, enter a valid subject code, reach the subject detail screen, and open the first lesson (quickstart.md §3).

**Backend gap B2 — MUST land before T028**:

- [ ] T024 [US1] Modify `back/src/subjects/subjects.service.ts` `findAllSubjects` to accept `(query, role, userId)` and, when `role === 'student'`, join against `SubjectCode` (or existing access helper) to project `isUnlocked: boolean` on each subject in the response (contracts §3 Δ / B2).
- [ ] T025 [US1] Update `back/src/subjects/subjects.controller.ts` `GET /subjects` handler to pass the authenticated `userId` into the service and update the Swagger response schema to include `isUnlocked`.
- [ ] T026 [US1] Update `back/src/subjects/dto/subject-response.dto.ts` (or equivalent) to add the `isUnlocked: boolean` field; add Jest test in `back/test/subjects.e2e-spec.ts` asserting the flag is `true` for a student with a redeemed code and `false` otherwise.

**Mobile implementation**:

- [ ] T027 [P] [US1] Create `Subject` and `Lesson` freezed models in `na_app/lib/features/subjects/domain/subject_models.dart` matching data-model §1.3–§1.4 (including `isUnlocked` from B2).
- [ ] T028 [P] [US1] Create `ActivationResult` sealed class in `na_app/lib/features/subjects/domain/activation_result.dart` with `ActivationSuccess` / `ActivationFailure` variants and `ActivationErrorReason` enum (data-model §1.5).
- [ ] T029 [US1] Create `na_app/lib/features/subjects/data/subjects_repository.dart` with `listSubjects()`, `getSubject(id)`, and `activateCode(code)` methods; maps Dio errors (400/403/429) onto `ActivationFailure` reasons per contracts §4.
- [ ] T030 [US1] Create `na_app/lib/features/auth/presentation/pages/splash_page.dart` — NA monogram, parchment background, soft radial glow, ≤3 s loader, routes to Login or Today based on `AuthController` state (FR-028, FR-029, acceptance US5 #1).
- [ ] T031 [P] [US1] Create `na_app/lib/features/auth/presentation/pages/login_page.dart` — email + password, "Forgot password?" link (routes to `/auth/forgot-password`, page built in US5), primary pill CTA, secondary "Create account" ghost link.
- [ ] T032 [P] [US1] Create `na_app/lib/features/auth/presentation/pages/register_page.dart` — full name, email, password (with show toggle + strength meter), Terms checkbox, primary pill CTA; on success stores tokens via `AuthController` and routes to `/subjects` (FR-001, FR-028).
- [ ] T033 [P] [US1] Create `na_app/lib/features/subjects/presentation/widgets/subject_card.dart` rendering unlocked vs. locked states (lock icon + "Needs code" chip when `!isUnlocked`) per FR-005.
- [ ] T034 [US1] Create `na_app/lib/features/subjects/presentation/pages/subjects_page.dart` — grid of `SubjectCard`s, "Have a subject code?" prominent card at the top, pull-to-refresh bound to the subjects provider (FR-005, acceptance US1 #1).
- [ ] T035 [P] [US1] Create `na_app/lib/features/subjects/presentation/pages/enter_subject_code_page.dart` — full-screen code entry using `CodeInputField` from T019, "Unlock" pill CTA disabled until 6 chars, FR-006/FR-007.
- [ ] T036 [P] [US1] Create `na_app/lib/features/subjects/presentation/widgets/bottom_sheet_code.dart` — bottom-sheet variant of code entry for locked-card taps (FR-006, edge case: code entry from within a screen).
- [ ] T037 [US1] Create `na_app/lib/features/subjects/presentation/pages/code_unlocking_page.dart` — 3-step progress list ("Verifying → Linking to teacher → Downloading lesson index") with reduced-motion degrade to instant state swap (FR-008, FR-036).
- [ ] T038 [P] [US1] Create `na_app/lib/features/subjects/presentation/pages/code_expired_page.dart` — preserves entered code in JetBrains Mono, shows expiry timestamp, two CTAs "Try another code" + "Message teacher" (FR-009, acceptance US1 #3).
- [ ] T039 [P] [US1] Create `na_app/lib/features/subjects/presentation/pages/code_used_page.dart` — same layout as `code_expired_page.dart` with "Code already used" copy that does NOT distinguish "used by you" vs. "used by someone else" (FR-009 clarified, acceptance US1 #4).
- [ ] T040 [US1] Create `na_app/lib/features/subjects/presentation/pages/subject_detail_page.dart` — lesson list with status chips (Done / Active / Locked), opens Active or Done lessons, blocks Locked with inline hint (FR-011, acceptance US1 #5).
- [ ] T041 [US1] Wire rate-limit handling in `subjects_repository.dart` and the activation flow: on 429 show an inline wait-time hint using `Retry-After` header / response body; disable the Unlock button for the advertised duration (FR-010).
- [ ] T042 [US1] Add `flutter_test` widget test `na_app/test/features/subjects/enter_subject_code_page_test.dart` asserting `CodeInputField` auto-advance, paste distribution across cells, and Unlock button enable-on-6-chars.
- [ ] T043 [US1] Add `integration_test` in `na_app/integration_test/p1_unlock_flow_test.dart` walking Splash → Register → empty Subjects → enter code → Code Accepted → Subject detail (quickstart.md §3, plan.md Testing).

**Checkpoint**: User Story 1 should be fully functional and demoable as the MVP.

---

## Phase 4: User Story 2 — Take a code-gated exam and see the result (Priority: P1)

**Goal**: Student opens Exams tab, unlocks an exam with a one-time code, answers questions one per screen with autosave, and sees a result screen with score and per-question review.

**Independent Test**: Seed an exam + exam code on the backend, unlock in the app, complete all questions, submit, verify score matches backend grading (quickstart.md §4).

**Backend gaps B3 + B4 — MUST land before T049**:

- [ ] T044 [US2] Modify `back/src/exams/exams.service.ts` `findAllExams` to project `attemptsRemaining: number` per exam when invoked by a student — count unused `ExamCode` rows where `assignedStudentId === userId || null` and `status === 'active'` (contracts §5 Δ / B3).
- [ ] T045 [US2] Update `back/src/exams/exams.controller.ts` `GET /exams` Swagger schema with `attemptsRemaining`; add Jest test asserting the count matches seeded codes.
- [ ] T046 [US2] Create `back/src/exams/dto/save-answer.dto.ts` with `SaveAnswerDto { @IsMongoId questionId: string; @IsDefined value: string | string[] }` (contracts §5 / B4).
- [ ] T047 [US2] Add `POST /exams/sessions/:sessionId/answer` to `back/src/exams/exams.controller.ts` returning 204, guarded by `Roles('student')`.
- [ ] T048 [US2] Implement `saveAnswer(sessionId, userId, dto)` in `back/src/exams/exams.service.ts` — service-level check that `session.userId === userId && session.status === 'inProgress'`; `$set` the answer keyed by `questionId` into the session's answers map; idempotent upsert (contracts §5). Add Jest test for the happy path and the "session not owned by user" rejection.

**Mobile implementation**:

- [ ] T049 [P] [US2] Create `Exam`, `ExamSession`, `ExamScore`, and `AnswerValue` freezed models in `na_app/lib/features/exams/domain/exam_models.dart` (data-model §1.6–§1.8).
- [ ] T050 [US2] Create `na_app/lib/features/exams/data/exams_repository.dart` with `listExams()`, `getExam(id)`, `startSession(examId)`, `saveAnswer(sessionId, questionId, value)`, and `submitSession(sessionId, answers)`; the autosave call is issued on every Next tap before the next question renders (research §7).
- [ ] T051 [P] [US2] Create `na_app/lib/features/exams/presentation/widgets/exam_timer.dart` — sticky countdown reading `session.endsAt`, triggers an `onExpire` callback used for auto-submit (FR-015).
- [ ] T052 [P] [US2] Create `na_app/lib/features/exams/presentation/widgets/question_card.dart` rendering one question per screen with answer input widgets appropriate to the question type.
- [ ] T053 [P] [US2] Create `na_app/lib/features/exams/presentation/widgets/score_ring.dart` (may re-export the core widget) and exam-specific detail sections.
- [ ] T054 [US2] Create `na_app/lib/features/exams/presentation/pages/exams_page.dart` — list grouped by Available / Completed with title, subject, duration, question count, and `attemptsRemaining` per exam (FR-012).
- [ ] T055 [P] [US2] Create `na_app/lib/features/exams/presentation/pages/enter_exam_code_page.dart` — exam summary card + wide mono-font `CodeInputField`, "Unlock and start exam" CTA disabled until code length is met (FR-013, acceptance US2 #1).
- [ ] T056 [US2] Create `na_app/lib/features/exams/presentation/pages/take_exam_page.dart` — sticky timer + progress bar, one question per screen, Next tap issues `saveAnswer` via repo before advancing, warns on back-navigation with "Leave exam?" dialog, auto-submits on timer expiry (FR-014, FR-015, acceptance US2 #2–5).
- [ ] T057 [US2] Create `na_app/lib/features/exams/presentation/pages/exam_result_page.dart` — score ring, pass/fail badge where applicable, collapsible per-question review (student answer vs. correct answer), CTA back to subjects; shows "Timed out" badge when the score came from a timer-expiry submit (FR-016, acceptance US2 #4–5).
- [ ] T058 [US2] Handle the background-mid-exam edge case in `take_exam_page.dart`: on resume within the timer window, refetch session and hydrate local answer map; past the window, route straight to `exam_result_page.dart` (Edge Cases, SC-005).
- [ ] T059 [US2] Add `integration_test` in `na_app/integration_test/p1_exam_flow_test.dart` walking Exams list → enter exam code → answer all questions (asserting autosave calls) → submit → Result screen.

**Checkpoint**: Both P1 slices work independently. This is the point at which the MVP can ship.

---

## Phase 5: User Story 3 — Message a tutor (Priority: P2)

**Goal**: Student sees a conversation list auto-provisioned from unlocked subjects, opens a 1:1 tutor thread, and exchanges text / image messages in realtime with typing indicators and read receipts.

**Independent Test**: Two accounts (student + tutor) exchange a message across two devices with typing and read receipts within the thread.

**Backend gaps B5 + B6 — MUST land before T064**:

- [ ] T060 [US3] Create `back/src/chat/dto/conversation-list.dto.ts` with the `ConversationPreview` shape from contracts §6 (id nullable when `virtual: true`, counterparty metadata, subjectId, lastMessage, unreadCount).
- [ ] T061 [US3] Add `GET /chat/conversations` to `back/src/chat/chat.controller.ts` guarded by `Roles('student', 'teacher', 'admin')`; returns the union of existing `Conversation` docs and "virtual" conversations derived from unlocked subjects whose `teacherId` has no existing thread with the caller (contracts §6 / B5).
- [ ] T062 [US3] Tighten `ChatService.canChat(senderId, recipientId)` in `back/src/chat/chat.service.ts`: student ↔ tutor only when the tutor teaches a subject the student has unlocked; tutor ↔ student symmetric; admins unrestricted. Emit socket error `'unauthorized_conversation'` when blocked (contracts §6 Δ / B5). Add Jest tests for both directions.
- [ ] T063 [US3] Enforce 10 MB cap and MIME whitelist (`image/jpeg`, `image/png`, `image/webp`, `image/heic`) in the `POST /media/chat/upload` handler in `back/src/media/media.controller.ts`; reject oversize with 413 and unsupported MIME with 415 (FR-018, contracts §7 / B6).

**Mobile implementation**:

- [ ] T064 [P] [US3] Create `Conversation`, `Message`, and `MessagePreview` freezed models in `na_app/lib/features/chat/domain/chat_models.dart` including the client-only `pending` message status (data-model §1.9–§1.10).
- [ ] T065 [US3] Create `na_app/lib/features/chat/data/chat_repository.dart` — `listConversations()` (hits `GET /chat/conversations`), `uploadImage(file)`, and a realtime stream that merges socket events from `chat_socket.dart` into the in-memory conversation cache.
- [ ] T066 [P] [US3] Create `na_app/lib/features/chat/presentation/widgets/message_bubble.dart` — right-aligned pill for student, left-aligned with tutor avatar, inline image via `cached_network_image` (FR-018).
- [ ] T067 [P] [US3] Create `na_app/lib/features/chat/presentation/widgets/composer.dart` — text field + camera/gallery buttons; client-side validation rejects non-image or oversize (>10 MB) attachments with a human-readable toast (FR-018).
- [ ] T068 [P] [US3] Create `na_app/lib/features/chat/presentation/widgets/typing_indicator.dart` — 3-dot breathing animation honouring reduced-motion (FR-018, FR-036).
- [ ] T069 [US3] Create `na_app/lib/features/chat/presentation/pages/chat_list_page.dart` — row per conversation with avatar, name, preview, relative timestamp via `time_ago.dart`, unread badge; empty state directs to enter a subject code when no unlocked subjects (FR-017, acceptance US3 #1).
- [ ] T070 [US3] Create `na_app/lib/features/chat/presentation/pages/chat_thread_page.dart` — message list bound to the realtime stream, composer, typing indicator, read-receipts marking, "Message removed" placeholder for deleted messages without losing scroll position (FR-018, FR-020, acceptance US3 #2–3, edge case: tutor deletes).
- [ ] T071 [US3] Implement offline-send queue in `chat_repository.dart` — messages sent without connectivity enter `pending` state with visible "Sending…" label; retry on reconnect using socket `send_message` with an idempotency token to avoid duplicates on success (FR-019, acceptance US3 #4).

**Checkpoint**: US1, US2, and US3 all work independently.

---

## Phase 6: User Story 4 — Glance at today's study plan (Priority: P3)

**Goal**: Student lands on the Today screen with a time-of-day greeting, streak, "Resume where you left off" card, due-today exams, and a horizontal scroller of unlocked subject cards with progress rings.

**Independent Test**: After a student has unlocked one subject and started one lesson, the Today screen shows their name, a non-zero streak if applicable, the in-progress lesson in the resume card, and the unlocked subject in the horizontal scroller.

- [ ] T072 [P] [US4] Create `AnalyticsSnapshot` freezed model in `na_app/lib/features/home/domain/home_models.dart` (data-model §1.11).
- [ ] T073 [US4] Create `na_app/lib/features/home/data/home_repository.dart` — aggregates `GET /users/me`, `GET /analytics/student/me`, the `/subjects` list (filtered to unlocked), and `GET /exams` (filtered to due-today) into a single `TodayViewState`.
- [ ] T074 [P] [US4] Create `na_app/lib/features/home/presentation/widgets/resume_card.dart` — deep-links into the last in-progress lesson (FR-022, acceptance US4 #2).
- [ ] T075 [P] [US4] Create `na_app/lib/features/home/presentation/widgets/due_today_card.dart` — surfaces the earliest exam due today with its remaining time (FR-022, acceptance US4 #3).
- [ ] T076 [P] [US4] Create `na_app/lib/features/home/presentation/widgets/subject_scroller.dart` — horizontal scroller of unlocked subjects with progress rings (FR-023).
- [ ] T077 [US4] Create `na_app/lib/features/home/presentation/pages/today_page.dart` — Fraunces greeting driven by `time_of_day_greeting.dart` + student name, streak indicator, Resume card, due-today section, subject scroller (FR-021, acceptance US4 #1).
- [ ] T078 [US4] Handle the "locked subject tapped from Today" edge case: route to `enter_subject_code_page.dart` pre-filled with the subject context instead of the bare subjects grid (Edge Cases).

**Checkpoint**: Today screen populated — no cross-story regressions.

---

## Phase 7: User Story 5 — Create an account and complete onboarding (Priority: P3)

**Goal**: First-time users get a splash → 3-slide onboarding → Register; returning users get Login. The Login screen exposes a password-reset flow that deep-links back into the app.

**Independent Test**: A new device completes Splash → Onboarding → Register → empty locked Subjects grid; a separate session completes Login → Forgot Password → MailHog link → Reset Password → Today (quickstart.md §5).

**Backend gap B1 — MUST land before T086**:

- [ ] T079 [US5] Create `back/src/mail/mail.module.ts`, `back/src/mail/mail.service.ts`, and `back/src/mail/templates/password-reset.hbs` using `@nestjs-modules/mailer` + `nodemailer` SMTP transport reading `MAIL_HOST`, `MAIL_PORT`, `MAIL_USER`, `MAIL_PASS`, `MAIL_FROM` from env (research §10, plan.md §Project Structure).
- [ ] T080 [US5] Create `back/src/auth/schemas/password-reset.schema.ts` with `{ userIdHash, tokenHash, expiresAt, consumed }` and a TTL index on `expiresAt`.
- [ ] T081 [P] [US5] Create `back/src/auth/dto/forgot-password.dto.ts` with `ForgotPasswordDto { @IsEmail email: string }` and `back/src/auth/dto/reset-password.dto.ts` with `ResetPasswordDto { @IsString token; @MinLength(8) newPassword; @IsString hardwareId }` (contracts §1).
- [ ] T082 [US5] Add `issueResetToken(email)` and `consumeResetToken(token, newPassword, hardwareId)` to `back/src/auth/auth.service.ts` — SHA-256 hash the token before storage, 30-minute TTL, atomic `consumed = true` mark, reject with `410 Gone` if expired or consumed, issue fresh tokens on success (contracts §1 / B1).
- [ ] T083 [US5] Add `POST /auth/forgot-password` (returns 204 regardless of email existence per FR-004a) and `POST /auth/reset-password` (returns `{ user, tokens }` per FR-004b) to `back/src/auth/auth.controller.ts` with Swagger entries.
- [ ] T084 [US5] Add Jest tests in `back/test/auth-reset.e2e-spec.ts` covering: unknown email returns 204 with no mail sent; known email queues a mail and creates a PasswordReset row; reset with expired token returns 410; reset with consumed token returns 410; happy-path reset returns user + tokens and lets the user log in with the new password.

**Mobile implementation**:

- [ ] T085 [P] [US5] Create `na_app/lib/features/onboarding/presentation/pages/onboarding_page.dart` — 3-slide pager with reduced-motion degrade, final slide primary CTA "Get started" + secondary ghost "I have an account" (FR-028, acceptance US5 #2, Principle V).
- [ ] T086 [P] [US5] Create `na_app/lib/features/auth/presentation/pages/forgot_password_page.dart` — email input, primary pill CTA, confirmation state "Check your inbox" shown on any server 204 response (FR-004a, acceptance US5 #4).
- [ ] T087 [P] [US5] Create `na_app/lib/features/auth/presentation/pages/reset_password_page.dart` — deep-linked from `/auth/reset-password?token=<t>`, new-password + confirm inputs with strength meter matching Register, on 200 stores tokens via `AuthController` and routes to `/today` (FR-004b, acceptance US5 #5).
- [ ] T088 [US5] Extend `auth_repository.dart` / `AuthController` (from T020) with `forgotPassword(email)` and `resetPassword(token, newPassword)` methods; the latter uses the hardware-id from `hardware_id_store.dart` per contracts §1.
- [ ] T089 [US5] Wire the Login screen's "Forgot password?" link (scaffolded in T031) to `/auth/forgot-password`; wire the onboarding "Get started" CTA to `/auth/register`; wire `deep_link_handler.dart` (T016) end-to-end so the MailHog link opens `reset_password_page.dart` with the token pre-parsed.

**Checkpoint**: All five user stories are independently functional.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Non-story improvements that span features — Profile + settings, accessibility audit, performance, error handling, and final validation against the quickstart.

- [ ] T090 [P] Create `na_app/lib/features/profile/data/profile_repository.dart` and `na_app/lib/features/profile/presentation/pages/profile_page.dart` — avatar, display name, email, stats block (streak, lessons completed, exams taken), weekly chart populated from `GET /analytics/student/me` (FR-024).
- [ ] T091 [P] Create `na_app/lib/features/profile/presentation/pages/settings_page.dart` — theme selector (system/light/dark persisted via `prefs_store.dart`), language (v1 locked to en), notifications toggle, Sign out button that clears secure storage and user-scoped caches then routes to Login (FR-025, FR-026, FR-004).
- [ ] T092 [P] Create stats widgets in `na_app/lib/features/profile/presentation/widgets/stat_tile.dart` and `na_app/lib/features/profile/presentation/widgets/weekly_chart.dart` (FR-024).
- [ ] T093 Audit every `ApiException` → toast path per FR-034; add a central `error_toast.dart` helper in `na_app/lib/core/widgets/` that every repository's error branch uses so raw payloads never reach the UI.
- [ ] T094 [P] Accessibility audit pass on the five core screens (`today_page.dart`, `subject_detail_page.dart`, `take_exam_page.dart`, `chat_thread_page.dart`, `profile_page.dart`) — verify ≥44dp touch targets, dynamic text scale up to 1.3× without clipping, reduced-motion honoured on Onboarding pager, Code Unlocking transition, and Chat send animation (FR-035, FR-036, FR-037, SC-007).
- [ ] T095 [P] Verify the Rarity Rule (sage-teal ≤10% of any screen) by walking every screen; add a `custom_lint` rule or visual-review checklist documented in `na_app/lib/core/theme/README.md` (FR-030, Principle I).
- [ ] T096 [P] Performance pass: measure cold-start-to-Today/Login on a mid-range device and confirm ≤2.5 s (SC-008); measure code-redemption round-trip p50/p95 (SC-002); confirm 60 fps on Subject detail, Take exam, and Chat thread using Flutter DevTools' performance overlay.
- [ ] T097 Implement offline-at-launch behaviour per Edge Cases: Today / Subjects / Exams render cached last state read-only; Chat composer and code-redemption CTAs are disabled with clear retry affordances.
- [ ] T098 Implement the 401-intercepted-sign-out path per Edge Cases: Dio refresh-failure (T014) clears tokens, emits `sessionExpired`, and the shell shows a non-alarming toast ("Session ended — please sign in again") on the Login landing.
- [ ] T099 Run `cd back && npm run lint && npm test` and `cd na_app && flutter analyze && flutter test` and fix any residual warnings (quickstart.md §7).
- [ ] T100 Execute `specs/003-mobile-app-redesign/quickstart.md` end-to-end on an iOS simulator + an Android emulator against a fresh `back/` + MongoDB + MailHog stack; confirm the P1 unlock path, the P1 exam path, the password-reset path, and the P2 chat path all succeed.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1, T001–T013)**: No dependencies — can start immediately.
- **Foundational (Phase 2, T014–T023)**: Depends on Setup. BLOCKS all user stories.
- **User Stories (Phases 3–7)**: Each depends on Foundational. Within each phase, the backend gap tasks (B1–B6) are merge-order prerequisites for the mobile tasks in the same phase per Principle IV.
- **Polish (Phase 8)**: Depends on all user stories you intend to ship.

### User Story Dependencies

- **US1 (P1)**: After Phase 2. Backend B2 (T024–T026) MUST land before T028 can hit a real `isUnlocked` field. No dependency on other stories.
- **US2 (P1)**: After Phase 2. Backend B3 + B4 (T044–T048) MUST land before T050. No dependency on US1 code (the subjects list and exams list are independent views), though exams are contextually tied to subjects.
- **US3 (P2)**: After Phase 2. Backend B5 + B6 (T060–T063) MUST land before T065. Functionally depends on the user having unlocked a subject (US1) for the empty state to be non-empty, but the code does not depend on US1's mobile code.
- **US4 (P3)**: After Phase 2. No backend gap. Draws on data from US1 (unlocked subjects) and US2 (due-today exams) but does not depend on their UI code.
- **US5 (P3)**: After Phase 2. Backend B1 (T079–T084) MUST land before T086. The Splash/Login/Register pages already exist from US1; US5 adds onboarding + the two password-reset pages.

### Within Each User Story

- Backend gap tasks (B1–B6) before the mobile tasks they unblock.
- Freezed models before repositories.
- Repositories before pages.
- Primitive widgets (Phase 2) before feature widgets.
- Feature widgets before the pages that compose them.
- Integration tests last within their phase.

### Parallel Opportunities

- **Phase 1**: T002 through T012 are all `[P]` — they touch different files and have no dependencies on each other.
- **Phase 2**: T016, T017, T018, T019, T021, T023 are `[P]` once T014 and T015 land.
- **US1**: T027, T028 can run in parallel with the backend (B2) work. T031, T032, T033, T035, T036, T038, T039 are all `[P]` once their predecessors land.
- **US2**: The backend B3 + B4 work can run in parallel with US1's mobile work. T049, T051, T052, T053, T055 are `[P]` within US2.
- **US3**: B5 + B6 can run in parallel with US2 work. T064, T066, T067, T068 are `[P]`.
- **US4**: T072, T074, T075, T076 are `[P]`.
- **US5**: T081, T085, T086, T087 are `[P]`.
- **Polish**: T090, T091, T092, T094, T095, T096 are all `[P]`.

---

## Parallel Example: User Story 1 kick-off

```bash
# Developer A (backend) picks up B2:
Task: T024 Modify back/src/subjects/subjects.service.ts findAllSubjects to project per-student isUnlocked
Task: T025 Update GET /subjects controller + Swagger schema
Task: T026 Update DTO + add Jest e2e test

# Developer B (mobile) picks up models + widgets in parallel:
Task: T027 Create Subject + Lesson freezed models
Task: T028 Create ActivationResult sealed class
Task: T033 Create SubjectCard widget

# Once B2 merges, Developer B continues:
Task: T029 SubjectsRepository → T034 subjects_page → T040 subject_detail_page
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Complete Phase 1 (Setup) and Phase 2 (Foundational).
2. Complete Phase 3 (US1): B2 → Subjects grid + code entry + unlocking + Subject detail.
3. **STOP and VALIDATE** against the Independent Test for US1.
4. Demo — this is enough for a design-review pass against `design-bundle/project/`.

### Incremental Delivery

1. Ship MVP (US1).
2. Add US2 (P1: exams) → a second P1 slice → ship.
3. Add US3 (P2: chat) → ship.
4. Add US4 + US5 (P3: Today + onboarding/reset) → ship.
5. Run Phase 8 Polish before a public release.

### Parallel Team Strategy

With two developers:

- Both complete Phases 1–2 together (pair on T014, split the rest).
- Developer A tackles the backend gaps in order B2 → B3 → B4 → B1 → B5 → B6 (each has Jest coverage before hand-off).
- Developer B tackles the mobile user stories in priority order, starting each phase as soon as its backend gap merges.
- Phase 8 Polish is shared.

---

## Notes

- `[P]` tasks = different files, no dependencies with other in-flight work.
- `[Story]` label maps every user-story-phase task to its story for traceability (US1–US5).
- Each user story is independently completable and testable per its Independent Test in spec.md.
- Commit after each task or logical group. Follow the existing Conventional Commits style in the repo (`feat:`, `fix:`, `chore:`).
- Do not introduce raw hex colours or `Colors.*` under `lib/features/` — T023's lint rule will reject this (Principle I).
- Every new backend endpoint (T024, T044–T048, T060–T063, T079–T083) MUST land with a `class-validator` DTO and a Swagger entry before the mobile side of the same phase merges (Principle IV).
- The Rarity Rule (sage-teal ≤10% of any screen) is enforced at review time — T095 formalises this.
