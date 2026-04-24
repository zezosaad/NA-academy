# Implementation Plan: NA-Academy Mobile App (Scholarly Sanctuary)

**Branch**: `003-mobile-app-redesign` | **Date**: 2026-04-24 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/003-mobile-app-redesign/spec.md`

## Summary

Ship the student-facing Flutter app under `na_app/` that consumes the existing NestJS backend (`back/`) and realises the "Scholarly Sanctuary" design bundle shipped with this feature (21 screens across Splash, Auth, Today, Subjects, Exams, Chat, Profile). The core value loop is subject-code unlock → study, with a code-gated exam flow as the assessment half and a student↔tutor chat as the mentorship half.

Backend-side this feature adds five targeted endpoints/changes (password reset, conversations list, per-answer autosave, canChat scoping, and optional conversation auto-provisioning). All other FRs map to endpoints already live in `back/src/`. The app uses the existing JWT + hardware-id auth pattern, the existing `POST /activation-codes/activate` endpoint for both subject and exam codes, and the existing `chat` Socket.IO namespace for realtime messaging.

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.24+ (matches `na_app/pubspec.yaml` SDK constraint `^3.11.3`); backend stays on NestJS 11 / Node 20+ per the constitution.
**Primary Dependencies** (mobile):
- **UI & design system**: `google_fonts` (Fraunces, Inter, JetBrains Mono) — already in pubspec; `flutter_svg`, `lucide_icons_flutter`, `animate_do` — already in pubspec.
- **Navigation**: `go_router` (declarative, deep-link-friendly for the reset-password link).
- **State management**: `flutter_riverpod` + `riverpod_annotation` (compile-time-safe providers; avoids the Provider/InheritedWidget ceremony and avoids a BLoC learning curve for a one-app repo).
- **Networking**: `dio` (interceptors for JWT refresh and normalized error shape) + `retrofit` (optional, for typed endpoint classes generated from Swagger later — acceptable to skip if over-engineered).
- **Realtime**: `socket_io_client` ^2.0 — matches the `back/` Socket.IO 4.x server.
- **Secure storage**: `flutter_secure_storage` (Keychain / EncryptedSharedPreferences) for access + refresh tokens.
- **Prefs**: `shared_preferences` for theme/language/notifications.
- **Forms**: `reactive_forms` or `flutter_form_builder` (aligns with the web app's react-hook-form + zod pattern; picks a single canonical form library).
- **Images & media**: `cached_network_image`, `image_picker` (camera + gallery), `video_player` + `chewie` for lesson playback.
- **Device id**: `device_info_plus` + `flutter_secure_storage` (generate a stable hardware id once, store it, send it on every auth call — matches the backend's `hardwareId` contract).
- **Deep links**: `app_links` for the password-reset link handler.
- **Observability (client)**: structured logging via `logger`; Sentry/Firebase Crashlytics deferred to a follow-up (not required for v1 per Clarifications outcome).

**Primary Dependencies** (backend additions):
- `@nestjs-modules/mailer` + `nodemailer` with an SMTP transport for password-reset emails (new `mail` module).
- No other new deps — conversations-list, canChat scoping, and per-answer autosave extend existing modules.

**Storage**: Mongoose/MongoDB (server, unchanged). Client persists only tokens (secure-store), theme/lang prefs (shared_prefs), and a small in-memory cache of GET responses per screen — no offline lesson playback in v1.
**Testing**: `flutter_test` (widget + unit) and `integration_test` for the Splash → Register → unlock-subject happy path. Backend: existing `npm run test` (Jest) covers the new endpoints.
**Target Platform**: iOS 13+, Android 8 / API 26+ (matches the default Flutter stable minimums and covers >95% of students per Play/App Store stats).
**Project Type**: mobile-app with a shared existing API.
**Performance Goals**:
- Cold start ≤ 2.5s to Today or Login (SC-008)
- Code redemption round-trip p50 ≤ 3s / p95 ≤ 6s (SC-002)
- Chat round-trip to read-receipt p95 ≤ 2s (SC-004)
- 60 fps steady-state on the Subject detail, Take exam, and Chat thread screens on a mid-range device.
**Constraints**:
- Backend device-lock via `hardwareId`: every auth and activation request MUST include the same stable id for that install. Forgetting this = cryptic 403s.
- Rarity Rule: Sage-Teal ≤ 10% of any screen — enforced at theme-token level (no raw accent calls in feature code).
- `prefers-reduced-motion` honoured on Onboarding pager, Unlocking transition, and Chat send animations (Principle V).
- No `.env` files committed (Technology & Quality Standards).
**Scale/Scope**: 21 screens, ~10–20 k students at launch scale, single backend region, realtime chat peak concurrency in the low thousands. Two-phase delivery (P1 first) sized to ship within ~3 weeks of developer time.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Evaluated against `.specify/memory/constitution.md` v1.0.0.

| # | Principle | Verdict | Notes |
|---|-----------|---------|-------|
| I | Scholarly Warmth by Default (NON-NEGOTIABLE) | **PASS** | Spec FR-029/030/031 bind the Scholarly Sanctuary tokens; the design bundle is preserved under `design-bundle/` as visual ground truth. Theme layer centralised in `na_app/lib/core/theme/`; no raw hex allowed in feature code. |
| II | Spec-Before-Code | **PASS** | This plan is generated after `/speckit.specify` and `/speckit.clarify` against the feature branch `003-mobile-app-redesign`. Implementation tasks opened only via `/speckit.tasks` after this plan's post-design re-check. |
| III | Independent, Priority-Ordered Slices | **PASS** | Spec orders P1 (unlock-and-study), P1 (code-gated exam), P2 (chat), P3 (today), P3 (auth polish + password reset). Task decomposition (next phase) MUST group by user story; no cross-story dependency that blocks P1 alone is expected. |
| IV | Contract-Driven Multi-Surface Consistency | **PASS-WITH-NOTES** | Five backend gaps are filed under this feature (see `contracts/api-contracts.md`): (a) forgot-/reset-password, (b) list conversations, (c) per-answer autosave, (d) canChat scoping, (e) deep-link-friendly reset token format. Each will land as a DTO + `class-validator` rules + Swagger entry before the mobile client consumes it. No ad-hoc client types. |
| V | Mobile-First, Accessible, Calm | **PASS** | Mobile is the only surface of this feature. Spec FR-035/036/037 codify touch targets, reduced motion, and dynamic-type. Post-design review will reverify on the five core screens (Today, Subject detail, Take exam, Chat thread, Profile). |

**Overall gate**: PASS. No violations requiring Complexity Tracking.

Post-Phase 1 re-check (after research.md, data-model.md, contracts/, quickstart.md are generated): see `## Post-Design Constitution Check` at the end of this document.

## Project Structure

### Documentation (this feature)

```text
specs/003-mobile-app-redesign/
├── plan.md                 # This file (/speckit.plan output)
├── spec.md                 # /speckit.specify + /speckit.clarify output
├── research.md             # Phase 0 output (this command)
├── data-model.md           # Phase 1 output
├── quickstart.md           # Phase 1 output
├── contracts/
│   └── api-contracts.md    # Phase 1 output — endpoint map + backend gaps
├── checklists/
│   └── requirements.md     # /speckit.specify output
├── design-bundle/          # Frozen design handoff (README + chats + project/)
└── tasks.md                # /speckit.tasks output (not created by this command)
```

### Source Code (repository root)

Only the directories this feature actually touches are shown. Sibling surfaces (`admin-dashboard/`, `front/`) are out of scope.

```text
back/
└── src/
    ├── auth/
    │   ├── auth.controller.ts          # + POST /auth/forgot-password, POST /auth/reset-password
    │   ├── auth.service.ts             # + issueResetToken, consumeResetToken
    │   ├── dto/
    │   │   ├── forgot-password.dto.ts  # NEW
    │   │   └── reset-password.dto.ts   # NEW
    │   └── schemas/
    │       └── password-reset.schema.ts # NEW — token, userId, expiresAt, consumed
    ├── mail/                           # NEW module
    │   ├── mail.module.ts
    │   ├── mail.service.ts             # sends password-reset email
    │   └── templates/password-reset.hbs
    ├── chat/
    │   ├── chat.controller.ts          # + GET /chat/conversations
    │   ├── chat.service.ts             # tighten canChat() to unlocked-subject tutors
    │   └── dto/
    │       └── conversation-list.dto.ts # NEW
    ├── exams/
    │   ├── exams.controller.ts         # + POST /exams/sessions/:sessionId/answer
    │   ├── exams.service.ts            # persist incremental answers on the ExamSession doc
    │   └── dto/
    │       └── save-answer.dto.ts      # NEW
    └── activation-codes/               # unchanged — /activate already covers subject + exam
na_app/
├── pubspec.yaml                        # + go_router, dio, flutter_riverpod, socket_io_client, flutter_secure_storage, shared_preferences, image_picker, cached_network_image, video_player, chewie, app_links, device_info_plus, cached_network_image
└── lib/
    ├── main.dart                       # rewritten: ProviderScope + MaterialApp.router
    ├── core/
    │   ├── theme/
    │   │   ├── app_theme.dart          # Scholarly Sanctuary tokens (light + dark)
    │   │   ├── app_colors.dart
    │   │   ├── app_typography.dart
    │   │   ├── app_shapes.dart
    │   │   └── app_motion.dart         # Reduced-motion aware transitions
    │   ├── router/
    │   │   ├── app_router.dart         # go_router config + auth guards
    │   │   └── deep_link_handler.dart  # reset-password link
    │   ├── api/
    │   │   ├── dio_client.dart         # base URL + interceptors (auth, refresh, normalize errors)
    │   │   ├── api_exception.dart
    │   │   └── endpoints.dart          # typed constants for every backend route
    │   ├── realtime/
    │   │   └── chat_socket.dart        # socket_io_client wrapper + reconnect
    │   ├── storage/
    │   │   ├── secure_token_store.dart # access + refresh
    │   │   ├── hardware_id_store.dart  # stable device id generator
    │   │   └── prefs_store.dart        # theme + lang + notifications
    │   ├── widgets/                    # design-system primitives (Button, Card, ListRow, CodeInput, ProgressRing, Chip, EmptyState, SectionHeader, AppBarX, BottomSheetX, ScoreRing, TypingIndicator, StreamingCursor)
    │   └── utils/
    │       ├── time_of_day_greeting.dart
    │       ├── time_ago.dart
    │       └── result.dart             # sealed Result<T, E>
    └── features/
        ├── auth/
        │   ├── data/
        │   │   ├── auth_repository.dart
        │   │   └── dtos.dart
        │   ├── domain/
        │   │   └── auth_models.dart
        │   └── presentation/
        │       ├── pages/
        │       │   ├── splash_page.dart
        │       │   ├── login_page.dart
        │       │   ├── register_page.dart
        │       │   ├── forgot_password_page.dart     # NEW
        │       │   └── reset_password_page.dart      # NEW (deep-linked)
        │       └── widgets/
        ├── onboarding/
        │   └── presentation/pages/onboarding_page.dart
        ├── home/                       # "Today"
        │   ├── data/home_repository.dart
        │   └── presentation/pages/today_page.dart, widgets/
        ├── subjects/
        │   ├── data/subjects_repository.dart
        │   └── presentation/
        │       ├── pages/
        │       │   ├── subjects_page.dart           # grid with locked + unlocked
        │       │   ├── subject_detail_page.dart
        │       │   ├── enter_subject_code_page.dart
        │       │   ├── code_unlocking_page.dart
        │       │   ├── code_expired_page.dart
        │       │   └── code_used_page.dart
        │       └── widgets/subject_card.dart, code_input.dart, bottom_sheet_code.dart
        ├── exams/
        │   ├── data/exams_repository.dart
        │   └── presentation/
        │       ├── pages/
        │       │   ├── exams_page.dart
        │       │   ├── enter_exam_code_page.dart
        │       │   ├── take_exam_page.dart
        │       │   └── exam_result_page.dart
        │       └── widgets/question_card.dart, exam_timer.dart, score_ring.dart
        ├── chat/
        │   ├── data/chat_repository.dart
        │   └── presentation/
        │       ├── pages/chat_list_page.dart, chat_thread_page.dart
        │       └── widgets/message_bubble.dart, composer.dart, typing_indicator.dart
        └── profile/
            ├── data/profile_repository.dart
            └── presentation/
                ├── pages/profile_page.dart, settings_page.dart
                └── widgets/stat_tile.dart, weekly_chart.dart
```

**Structure Decision**: Mobile + API layout (Option 3 from the template). The Flutter app under `na_app/` follows a `core/` + `features/<domain>/{data,domain,presentation}` layering — matches the existing feature folders already scaffolded (`auth/presentation`, `home/presentation/widgets`, etc.) and cleanly separates HTTP/DTO types (data) from UI state (presentation) with domain models in between. The backend keeps NestJS's module-per-domain convention; new additions sit inside the existing modules plus one new `mail` module.

## Phase 0 — Outline & Research

Generated alongside this file: **`research.md`**.

Topics researched:
1. Flutter state-management choice (Riverpod vs. Bloc vs. Provider)
2. Navigation library (`go_router` vs. `auto_route`) and deep-link handling for password reset
3. Socket.IO client on Flutter (`socket_io_client` vs. `nakama` vs. raw WebSocket)
4. Secure token storage & JWT refresh interceptor pattern
5. Theme system for Scholarly Sanctuary tokens with dark-mode + dynamic-type + reduced-motion
6. Code input ergonomics (6-cell auto-advance + paste) in Flutter
7. Exam session auto-save strategy: per-answer HTTP vs. batched debounce vs. durable local buffer
8. Chat conversations list — where should the truth live given the current backend shape
9. Device id generation & storage (to satisfy the backend's `hardwareId` contract)
10. Password-reset email provider + link format

Every entry resolves to a **Decision / Rationale / Alternatives considered** triple. No NEEDS CLARIFICATION items remain after Phase 0.

## Phase 1 — Design & Contracts

Generated alongside this file:

- **`data-model.md`** — client-side entity model, state transitions (code lifecycle, exam session lifecycle, message delivery states), and persistence strategy.
- **`contracts/api-contracts.md`** — the complete endpoint map from spec FRs to backend routes, with request/response sketches for the five new/changed routes. This document is the source of truth reviewers use to verify Principle IV (contract-driven consistency).
- **`quickstart.md`** — 10-minute local setup: clone → run backend → seed a subject + code → `flutter run` on a device → complete the P1 unlock flow.

### Agent context update

Ran `.specify/scripts/powershell/update-agent-context.ps1 -AgentType claude` to refresh the agent context file with the new technology choices (Flutter, Riverpod, go_router, dio, socket_io_client, flutter_secure_storage).

## Post-Design Constitution Check

Re-evaluated after Phase 1 artifacts were generated.

| # | Principle | Verdict | Delta from pre-design check |
|---|-----------|---------|-----------------------------|
| I | Scholarly Warmth | PASS | Theme layer isolated under `core/theme/`; no regression. |
| II | Spec-Before-Code | PASS | No code touched yet; this plan is still documentation. |
| III | Independent Slices | PASS | `contracts/api-contracts.md` confirms each P1 slice (unlock, exam) can be delivered without depending on P2 or P3 work. |
| IV | Contract-Driven | PASS-WITH-NOTES | The five backend gaps are now each drafted as a request/response sketch with validation rules. They MUST land in `back/` with Swagger entries before the corresponding mobile code is merged. Added as a merge-order constraint in `tasks.md` (next phase). |
| V | Mobile-First, Accessible, Calm | PASS | `data-model.md` notes which fields drive dynamic-type layouts; `research.md` documents the reduced-motion gating for the Unlocking transition and Chat send animations. |

**Overall post-design gate**: PASS. No Complexity Tracking entries required.

## Complexity Tracking

_No violations. Table intentionally empty._

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| — | — | — |
