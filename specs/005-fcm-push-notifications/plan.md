# Implementation Plan: Push Notifications & In-App Inbox (FCM)

**Branch**: `005-fcm-push-notifications` | **Date**: 2026-05-01 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-fcm-push-notifications/spec.md`

## Summary

Wire **Firebase Cloud Messaging (FCM)** into the NA-Academy stack so admins (and teachers, scoped to their own subjects) can compose notifications in the admin dashboard, deliver them as OS-level push to students' devices within seconds, and persist every notification in the backend so the Flutter `na_app` student app can show them in a reliable in-app inbox even when the OS-level push is missed or the device was offline.

Scope:

- **Backend** (`back/`): new `notifications` module that owns the `Notification` and `NotificationRecipient` collections, an audience-resolver (audience kinds `all` / `user-list` / `subject`), an FCM sender that uses the `firebase-admin` SDK, RBAC (admin sends anything; teacher sends only to subjects they own), idempotent send submissions, and a 365-day retention sweep on per-recipient rows.
- **Push token registration**: new `PushToken` collection (separate from the existing hardware-bound `Device` schema, which serves account-to-hardware binding rather than push delivery). One active push token per user (aligned with the existing single-device-binding rule); previous tokens are tombstoned on logout / token rotation / device handoff.
- **Admin dashboard** (`admin-dashboard/`): a new "Notifications" route with two sub-views — *Send* (composer with audience picker, role-aware) and *History* (paginated, searchable list with detail drawer showing aggregate counts and per-recipient delivery state for ≤365-day-old sends).
- **Mobile** (`na_app/`, Flutter): a new `notifications` feature folder following the existing clean-architecture pattern (`data/domain/presentation`). Integrates `firebase_core` + `firebase_messaging` for FCM and `flutter_local_notifications` for foreground display; persists received notifications to the existing `drift` SQLite database for offline inbox; binds the bell icon on `home_screen` to an unread badge; replaces the placeholder "Notifications" list item under Profile → Settings with a real screen and ties the existing global-on/off toggle in `prefs_store` to OS permission state.
- **Out of scope for v1**: Expo `front/` parity (consistent with 004's surface-scope precedent), web push, scheduled / recurring sends, rich media, action buttons, per-category mute preferences (single global on/off only), role-based audience targeting beyond `subject`, and custom segments.

The contract spine is the four DTOs in `contracts/`: `POST /notifications` (admin/teacher send), `GET /notifications` (history list with filtering), `GET /notifications/:id` (detail), and the four push-token endpoints under `/me/push-tokens` (register, refresh, unregister, list). All DTOs are `class-validator`-checked and Swagger-registered before any client work begins.

## Technical Context

**Language/Version**: Dart 3.11+ / Flutter 3.24+ (`na_app/`); TypeScript on NestJS 11 / Node 20+ (`back/`); Vite + React 19 + TypeScript (`admin-dashboard/`).

**Primary Dependencies**:

- Backend (`back/`): existing NestJS 11, Mongoose, `class-validator`, Swagger, `@nestjs/throttler`, `@nestjs/schedule` (for the retention sweep cron — add if not already present). **New**: `firebase-admin` (server-side FCM client, configured with a service-account JSON loaded from environment, never committed).
- Admin dashboard (`admin-dashboard/`): existing Vite + React 19, shadcn/ui (Tailwind + Radix), `react-router-dom` v7, `react-hook-form` + `zod` for the composer form. No new runtime deps.
- Flutter (`na_app/`): existing `dio`, `flutter_riverpod`, `go_router`, `drift`, `flutter_secure_storage`, `easy_localization`, `freezed`. **New**: `firebase_core`, `firebase_messaging`, `flutter_local_notifications` (foreground banner + Android channel registration). The notifications inbox table piggybacks on the existing `drift` database that 004 introduced.

**Storage**:

- Server: MongoDB (existing). New collections: `notifications` (the message itself, retained indefinitely) and `notification_recipients` (per-user delivery state, auto-pruned at 365 days post-send via a daily cron). New `push_tokens` collection (one active token per user; tombstoned on rotation / logout). No schema-breaking changes to existing collections.
- Client: existing `drift` SQLite database in `na_app/` gains two tables — `notifications_inbox` (cached server records) and `notifications_unread_index` (denormalized count helper). No new DB file.

**Testing**: existing Jest test infrastructure for `back/` (controller + service + DTO contract tests); existing `flutter_test` + `integration_test` for `na_app/`; component-level smoke tests with React Testing Library on `admin-dashboard/` if/where present.

**Target Platform**: iOS 14+ and Android API 26+ via Flutter `na_app/`. Backend on Node 20+ unchanged. Admin dashboard runs in evergreen browsers (Chromium, Firefox, Safari).

**Project Type**: Mobile + Web Admin + API.

**Performance Goals**:

- p50 push delivery within **5 s** of admin click (SC-002), measured server-emit-to-OS-tray on a connected device.
- Composer "Send" endpoint returns within **5 s** for audiences ≤ 1,000 recipients; for larger audiences the endpoint returns immediately with a job id and the per-recipient writes happen asynchronously.
- Inbox list query (`GET /notifications/me?limit=20`) responds in **< 300 ms** at p95 with 5,000 records per user.
- Mobile bell-badge unread count update within **500 ms** of a foreground push arrival or of marking-as-read.

**Constraints**:

- The existing **single-device-binding** rule (`devices` module) is authoritative for security; the `push_tokens` collection is a separate concern (push delivery only) and MUST follow the same "one active token per user" rule to stay coherent. When the hardware device changes (admin reset / handoff), the old push token is tombstoned in the same transaction.
- The FCM service-account JSON MUST be loaded from an env-pointed file or an env JSON blob and **must never** appear in committed code, in client code, in dashboard code, or in logs.
- Push body MUST NOT contain credentials, password-reset codes, or any one-time secret (FR-033). The body is treated as user-readable plaintext that may be logged by the OS.
- Constitution Principle I: dashboard composer + history pages and the mobile inbox screen MUST use the parchment palette, Fraunces for display tiers, Inter for body, 12–18px radii, ≤10% Sage-Teal. No vibrant blue "Send" buttons.
- Constitution Principle V: the mobile inbox is the primary surface; touch targets ≥ 44×44 pt; reduced-motion honored on the foreground banner.
- The spec's edge case about a user receiving on multiple devices simultaneously is **scoped down** to "the user's current bound device" given the existing single-device-binding rule. The inbox-state-consistency-across-devices guarantee still holds *over time* (a user re-binding to a new device sees the same server-stored inbox).

**Scale/Scope**: ~33 functional requirements across three surfaces. ~10 new endpoints (6 notifications, 4 push-token), 3 new collections, 1 new Flutter feature folder, 1 new admin dashboard page (with composer + history sub-views). Single broadcast must support up to **10,000 recipients** without dashboard timeouts (SC-008).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| **I. Scholarly Warmth by Default** | **PASS-WITH-NOTES** | Composer form, audience picker chips, history list, history detail drawer (admin), inbox screen, inbox detail, foreground banner, and bell-badge (mobile) MUST conform to `DESIGN.md`: parchment palette, Fraunces display headings on detail views, Inter body, pill primary "Send" CTAs, 12–18px radii, ≤10% Sage-Teal accent. Forbid generic-SaaS Send-blue buttons and grey-on-grey delivery-state pills. Concrete token usage is fixed in `/speckit.tasks` and verified in implementation. |
| **II. Spec-Before-Code** | **PASS** | Spec is ratified; three clarifications recorded under `## Clarifications` (session 2026-05-01) covering audience kinds, sender RBAC, and retention. No tasks will be opened until this `plan.md` passes Constitution Check. |
| **III. Independent, Priority-Ordered Slices** | **PASS** | Spec orders four user stories: P1 = admin broadcasts to all users; P1 = student inbox + bell badge; P2 = targeted send (specific users / subject); P3 = admin send-history with detail drawer. P1 alone is a viable MVP (broadcast announcements + inbox). Each subsequent priority is independently deliverable on top of P1. The phase-2 task breakdown will preserve this grouping. |
| **IV. Contract-Driven Multi-Surface Consistency** | **PASS-WITH-NOTES** | All new endpoints expressed as DTOs with `class-validator` rules and registered with Swagger before any dashboard or Flutter work begins. Both clients consume the **same** DTO shapes (no parallel ad-hoc types). See `contracts/notifications.md` and `contracts/push-tokens.md`. **Note**: spec's "course" is normalized in the contract layer to the existing `Subject` resource (`audience.kind = "subject"`, `audience.subjectId = ObjectId`); spec wording is preserved in the user-facing layer where readability matters, but the wire model uses the canonical entity name. |
| **V. Mobile-First, Accessible, Calm** | **PASS-WITH-NOTES** | The student inbox is the primary surface and is designed first; admin pages adapt from there. Touch targets ≥ 44×44 pt on every interactive element (notification row, mark-all-as-read, deep-link tap). `prefers-reduced-motion` is honored on the foreground banner. Inbox text uses Parchment-to-Ink contrast — no low-contrast grey-on-grey snippets. **Note**: the constitution names the Expo `front/` app as the flagship mobile surface, but recent feature work (003, 004) and this feature target the active Flutter `na_app/` per the user's explicit Flutter preference. Treated as a **scope decision**, not a constitution violation, consistent with 004-offline-mode's precedent. Expo `front/` parity is a follow-up feature, not a v1 requirement. |

**Outcome**: All five gates pass (three with documented notes). No `Complexity Tracking` entries required.

### Post-design re-check (2026-05-01, after Phase 1)

After authoring `research.md`, `data-model.md`, `contracts/notifications.md`, `contracts/push-tokens.md`, and `quickstart.md`, the Constitution Check was re-evaluated:

- **I.** No design decision in Phase 1 introduced a token violation; concrete styling is still deferred to `/speckit.tasks` and verified at implementation. **PASS-WITH-NOTES (unchanged).**
- **II.** Spec was ratified before plan; plan and design artifacts complete before tasks. **PASS.**
- **III.** Contracts permit independent delivery of P1 (broadcast + inbox) without P2 (targeting) or P3 (history detail) — the audience-resolver supports `kind = 'all'` end-to-end on its own; teacher RBAC and history detail layer cleanly on top. **PASS.**
- **IV.** Both `contracts/*.md` files are the single DTO source consumed by `admin-dashboard/` and `na_app/`. Subject-vs-course terminology bridge fully documented. **PASS-WITH-NOTES (unchanged).**
- **V.** Mobile inbox model in `data-model.md` reuses 004's `drift` patterns; the contract intentionally exposes `unreadCount` so the mobile bell-badge stays cheap. **PASS-WITH-NOTES (unchanged).**

No new violations introduced. Ready for `/speckit.tasks`.

## Project Structure

### Documentation (this feature)

```text
specs/005-fcm-push-notifications/
├── plan.md                  # This file
├── spec.md                  # Feature specification (clarifications resolved)
├── research.md              # Phase 0 — resolves cross-feature/cross-surface decisions
├── data-model.md            # Phase 1 — entities, indexes, lifecycle
├── quickstart.md            # Phase 1 — how to send a broadcast end-to-end (dev loop)
├── contracts/               # Phase 1 — REST/DTO contracts for new endpoints
│   ├── notifications.md     # POST/GET/GET-by-id + DTOs + RBAC matrix
│   └── push-tokens.md       # register/refresh/unregister/list + DTOs
├── checklists/
│   └── requirements.md      # Spec-quality checklist (passing)
└── tasks.md                 # Phase 2 (NOT created here — created by /speckit.tasks)
```

### Source Code (repository root)

```text
back/
└── src/
    ├── notifications/                        # NEW module
    │   ├── notifications.module.ts
    │   ├── notifications.controller.ts       # POST /notifications, GET /notifications, GET /notifications/:id, GET /notifications/me, PATCH /notifications/:id/read
    │   ├── notifications.service.ts          # composer → audience resolver → FCM send → persist; idempotent
    │   ├── audience-resolver.service.ts      # all / user-list / subject → user IDs (snapshot at send time)
    │   ├── fcm.service.ts                    # thin wrapper over firebase-admin Messaging.sendEachForMulticast
    │   ├── retention.service.ts              # daily cron: prune notification_recipients older than 365 days
    │   ├── dto/
    │   │   ├── create-notification.dto.ts
    │   │   ├── audience.dto.ts
    │   │   ├── notification-list-query.dto.ts
    │   │   ├── notification-response.dto.ts
    │   │   └── recipient-state.dto.ts
    │   └── schemas/
    │       ├── notification.schema.ts
    │       └── notification-recipient.schema.ts
    │
    ├── push-tokens/                          # NEW module (small, dedicated)
    │   ├── push-tokens.module.ts
    │   ├── push-tokens.controller.ts         # POST /me/push-tokens, PATCH /me/push-tokens/:id, DELETE /me/push-tokens/:id, GET /me/push-tokens
    │   ├── push-tokens.service.ts            # one-active-per-user invariant + tombstoning
    │   ├── dto/
    │   │   ├── register-token.dto.ts
    │   │   └── token-response.dto.ts
    │   └── schemas/
    │       └── push-token.schema.ts
    │
    ├── devices/devices.service.ts            # EXTEND: when device is reset/handed-off, also tombstone associated push token (one transaction)
    └── app.module.ts                         # EXTEND: register NotificationsModule, PushTokensModule

admin-dashboard/
└── src/
    ├── pages/
    │   ├── NotificationsPage.tsx             # NEW — wraps Send + History tabs (route /notifications)
    │   ├── NotificationsSendPage.tsx         # NEW — composer (audience picker + title/body/payload form)
    │   └── NotificationsHistoryPage.tsx      # NEW — paginated, searchable list + detail drawer
    ├── components/
    │   ├── NotificationComposer.tsx          # form (react-hook-form + zod), audience-aware
    │   ├── AudiencePicker.tsx                # all | user-list (search w/ debounce) | subject (teachers see only their own)
    │   └── NotificationDetailDrawer.tsx      # full body, payload, recipient list (or "archived" notice if pruned)
    └── services/
        └── notifications.api.ts              # typed client over the contract DTOs

na_app/
└── lib/
    ├── core/
    │   ├── notifications/                    # NEW — Firebase + local-notifications wiring (cross-cutting)
    │   │   ├── firebase_bootstrap.dart       # Firebase.initializeApp() + APNs/FCM token bootstrap
    │   │   ├── push_message_handler.dart     # foreground / onMessageOpenedApp / getInitialMessage / background isolate top-level fn
    │   │   ├── push_token_registrar.dart     # registers token with backend on login, refreshes on rotate, unregisters on logout
    │   │   └── local_notifications.dart      # flutter_local_notifications channel + foreground banner display
    │   └── storage/
    │       └── prefs_store.dart              # EXTEND: notificationsEnabled binds to OS permission re-check on app resume
    │
    └── features/
        └── notifications/                    # NEW feature module (clean architecture)
            ├── data/
            │   ├── notifications_local_data_source.dart    # drift dao (notifications_inbox, unread_index)
            │   ├── notifications_remote_data_source.dart   # dio against /notifications/me, /notifications/:id, PATCH /:id/read
            │   ├── notifications_repository.dart           # offline-first: cache, then network refresh; merges by server id
            │   └── models/                                 # freezed/json_serializable
            │       ├── notification_dto.dart
            │       └── notification_recipient_dto.dart
            ├── domain/
            │   ├── entities/notification.dart
            │   └── usecases/
            │       ├── load_inbox.dart
            │       ├── mark_as_read.dart
            │       ├── mark_all_as_read.dart
            │       └── observe_unread_count.dart
            └── presentation/
                ├── pages/
                │   ├── notifications_inbox_page.dart       # bell-icon → here
                │   └── notification_detail_page.dart
                ├── widgets/
                │   ├── notification_row.dart
                │   ├── unread_badge.dart                   # bound to home_screen bell icon
                │   └── foreground_notification_banner.dart # parchment-palette, reduced-motion-safe
                └── controllers/
                    └── inbox_controller.dart               # riverpod
```

**Structure Decision**: This is a **mobile + web admin + API** feature spanning three of the four NA-Academy surfaces. Backend gains two new sibling modules (`notifications`, `push-tokens`) so concerns stay separated; the admin dashboard gains one new top-level page composed of two sub-views; the Flutter app gains one cross-cutting `core/notifications/` (Firebase wiring) and one new feature folder (`features/notifications/`) following the existing clean-architecture convention used by `exams/` and other features. Expo `front/` is intentionally not modified in v1.

## Complexity Tracking

> Constitution Check passes for all five principles. No violations to justify.

The two PASS-WITH-NOTES items (terminology bridge "course → subject" in IV, and Flutter-not-Expo surface choice in V) are scope decisions documented in `research.md`, not violations.
