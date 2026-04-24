# Phase 0 Research — NA-Academy Mobile App

Each entry resolves one unknown or pattern-choice with **Decision / Rationale / Alternatives considered**. All NEEDS CLARIFICATION items from `plan.md`'s Technical Context are resolved below.

---

## 1. State management

**Decision**: Riverpod 2.x (`flutter_riverpod` + `riverpod_annotation` + `riverpod_generator`).

**Rationale**:
- Compile-time-safe providers; the generator removes the boilerplate Riverpod 1.x had and gives us codegen'd `Ref` types.
- Works identically for ephemeral UI state, async HTTP state (`AsyncNotifier`), and realtime subscription state (`StreamProvider`). The chat screen needs all three in one tree — one system keeps mental model flat.
- Doesn't require InheritedWidget acrobatics for testing; providers are overridable in tests directly.

**Alternatives considered**:
- **Bloc**: more ceremony (events/states/boilerplate) for a one-app repo, and the team has no prior Bloc muscle memory to reuse.
- **Provider** (plain): works for the simple screens but doesn't model async/stream lifecycles cleanly, and offers no compile-time safety against missing providers.
- **GetX**: rejected on principle — global singletons + routing + DI in one blob conflicts with "Spec-Before-Code" traceability and makes unit tests hard to isolate.

---

## 2. Navigation & deep linking

**Decision**: `go_router` ^14.x with declarative route tree and a top-level redirect for auth gating. `app_links` for handling the deep-linked password-reset URL.

**Rationale**:
- Declarative routes match the `expo-router`-style layout the `front/` React Native codebase already documents, keeping team mental models aligned across surfaces.
- Redirect hook gives us a single place to enforce Principle V's "unauthenticated → Splash→Onboarding→Login" flow without scattering guards across screens.
- `app_links` is Flutter-friendly, supports universal links on iOS and app links on Android, and integrates with `go_router`'s `routeInformationProvider`.

**Alternatives considered**:
- **`auto_route`**: also good, but its codegen layer adds a second build step alongside Riverpod's generator — not worth the overhead for ~21 screens.
- **Navigator 2.0 raw API**: too low-level; we'd end up reinventing `go_router`.
- **`uni_links`**: older, less maintained than `app_links`; `app_links` is the 2025 canonical choice.

---

## 3. Socket.IO client on Flutter

**Decision**: `socket_io_client` ^2.0 (dev version `2.0.3+1` or newer).

**Rationale**:
- The backend uses `@nestjs/platform-socket.io` on the `chat` namespace. `socket_io_client` is the only maintained Dart client that speaks Socket.IO v4 protocol compatible with the NestJS server.
- Handshake-via-token is supported via `auth` option and matches `chat.gateway.ts` which reads `client.handshake.auth?.token`.
- Handles namespace connection (`io(url + '/chat', …)`), events, and reconnection out of the box.

**Alternatives considered**:
- **Raw WebSocket (`web_socket_channel`)**: would have to reimplement Socket.IO's handshake, ping/pong, namespaces, and event framing — not worth it.
- **`nakama-flutter`**: specific to Nakama servers, not compatible with Socket.IO.

---

## 4. Secure token storage + JWT refresh interceptor

**Decision**:
- Store `accessToken` and `refreshToken` in `flutter_secure_storage` (iOS Keychain, Android EncryptedSharedPreferences with a keystore-backed master key).
- Dio request interceptor attaches `Authorization: Bearer <access>` on every call.
- Dio response interceptor catches 401, serializes concurrent retries through a single `Completer<void>`, calls `POST /auth/refresh` with the stored refresh token, updates the store, and replays the queued requests.
- On refresh failure, clear the store and route back to Login (FR-003).

**Rationale**:
- `flutter_secure_storage` is the canonical choice; it wraps Keychain/EncryptedSharedPreferences correctly and persists across app reinstalls on iOS.
- Queued refresh prevents a thundering herd (5 parallel 401s → 5 refresh calls → backend rate-limit).

**Alternatives considered**:
- **`hive` with an encryption key**: the key would itself need to be stored somewhere — circular.
- **`shared_preferences`**: unencrypted; rejected for tokens (fine for theme prefs).

---

## 5. Theme system (Scholarly Sanctuary tokens, dark mode, dynamic type, reduced motion)

**Decision**: A single `AppTheme` class exposing `lightTheme()` and `darkTheme()` Material 3 `ThemeData` objects, parameterised by a `ThemeMode` and a `MediaQueryData`. Tokens live as `const` values in `app_colors.dart`, `app_typography.dart`, `app_shapes.dart`, `app_motion.dart` — never as hex literals in feature code (Principle I).

- Typography uses `google_fonts`: Fraunces for `displayLarge`, `headlineMedium`, `titleLarge`; Inter for `bodyLarge`, `labelMedium`; JetBrains Mono for code cells (`labelMono` custom TextStyle).
- `MediaQuery.textScalerOf(context)` is consulted; layouts use `Flexible` / `AutoSizeText` on the five core screens to satisfy FR-037 (scale up to 1.3×).
- A `Motion` helper reads `MediaQuery.disableAnimations` (maps to `prefers-reduced-motion`) and degrades the Unlocking transition to an instant state swap and the Chat send animation to a fade.
- `ThemeMode` is persisted via `shared_preferences` and toggled from the Profile > Settings screen.

**Rationale**:
- Single source of truth = Constitution Principle I satisfied mechanically. Lint rule (custom_lint) rejects raw `Color(0x…)` and `Colors.*` in `lib/features/`.
- Motion gating follows Apple's HIG and Android's reduced-motion guidance.

**Alternatives considered**:
- **Dynamic Material-You**: rejected — Material-You palettes would override the Scholarly Sanctuary tokens.
- **Per-feature theme overrides**: rejected — violates Rarity Rule (FR-030) and makes audits impossible.

---

## 6. 6-cell code input

**Decision**: A custom `CodeInputField` widget that renders six `TextField`s wrapped in a `FocusTraversalGroup`. Auto-advance on `onChanged`; on `Backspace` at an empty cell, focus the previous cell. Listens for a single paste event on any cell (`TextField`'s `onChanged` with a longer-than-1 value) and distributes characters across cells. Rejects anything non-alphanumeric.

**Rationale**:
- Six separated cells match the design bundle visually (mono face, letter-spacing) and give the auto-advance behaviour users expect from SMS OTP inputs.
- Paste distribution is cheap (≤6 chars) and matches the Edge Cases section of the spec.
- Single canonical widget → consistent behaviour across Enter Subject Code, Enter Exam Code, and the bottom-sheet variant.

**Alternatives considered**:
- **`pin_code_fields` package**: solid, but introduces an opinionated API (no JetBrains Mono out of the box, no bone-border treatment); a custom widget is ~100 LOC and matches the design exactly.

---

## 7. Exam answer auto-save strategy

**Decision**: Per-question HTTP call to a new `POST /exams/sessions/:sessionId/answer` endpoint, issued the moment the student taps Next (before the next question renders). Client-side debounce is 0ms — the user gesture is already discrete. On network failure the answer is buffered in an in-memory map keyed by `questionId`; a retry kicks on connectivity return and on final submit. The final `POST /exams/submit` includes the full answers map as a defensive second pass — the backend upserts.

**Rationale**:
- Zero-loss requirement (SC-005) demands server-side durability of each answer. Local-only buffering fails the "student kills the app mid-exam" case.
- Per-question traffic is bounded: ~20 questions/exam × N exams/day = negligible load on the existing backend.
- Gap noted: the current `exams.controller.ts` has `POST /exams/submit` only; a new per-answer endpoint is the smallest addition and fits cleanly next to the existing session start/submit flow.

**Alternatives considered**:
- **Batched periodic save (every 5s)**: risks losing the last 0–5s of answers on crash. Rejected against SC-005.
- **Socket.IO live-save channel**: unnecessary complexity; HTTP is fine at this scale.

---

## 8. Chat conversations list — data source

**Decision**: New `GET /chat/conversations` backend endpoint returning `{ conversations: [{ id, counterpartyId, counterpartyName, counterpartyAvatar, subjectId, lastMessage: {text, sentAt, status}, unreadCount }] }` for the authenticated student (or tutor). The mobile app's Chat list screen binds to this plus a Socket.IO subscription on the `new_message` / `conversation_read` events to keep the preview row fresh in-session.

**Rationale**:
- Today the backend has no way to list conversations before a message is exchanged. Since v1 conversations are auto-provisioned per unlocked subject, we need either (a) a server-side projection that unions "existing conversations" with "tutors of my unlocked subjects", or (b) a pre-provisioned `Conversation` document created when a subject is unlocked. Option (a) is strictly additive (no schema change) and keeps `Conversation` a real document only once a message is sent; option (b) fills the DB with empty conversations forever.
- Binding to realtime events for in-session freshness avoids a full re-fetch on every send/read and matches SC-004 (≤2s read-receipt round-trip).

**Alternatives considered**:
- **Derive list entirely on the client** from unlocked-subjects + tutor-of-subject: the subject schema doesn't expose a tutor id today. Adding it would be a larger schema surgery than adding one projection endpoint.
- **Auto-create empty Conversation docs on subject unlock**: pollutes the collection with rows that never get a message. Rejected.

---

## 9. Device id generation & storage (`hardwareId` contract)

**Decision**: On first launch, generate a UUID v4, store it in `flutter_secure_storage` under key `hardware_id`, and send it as the `hardwareId` field on every call that expects one (`/auth/register`, `/auth/login`, `/activation-codes/activate`, the socket handshake). Never regenerate unless an admin explicitly resets the device via `PATCH /users/:id/device-reset`.

**Rationale**:
- The backend uses `hardwareId` to lock an activated code to a specific install (`ActivationCodesService.hasExamAccess(userId, id, hardwareId)`). A volatile or re-generated id would cause the student's own unlocks to stop working between launches.
- `device_info_plus`-derived ids (iOS `identifierForVendor`, Android `androidId`) are the "natural" choice but are not guaranteed stable across reinstalls on iOS and are problematic under Android 13 privacy rules. A self-generated UUID stored in secure storage is stable and privacy-clean.
- Aligns with the web auth flow in `front/` which generates the same way.

**Alternatives considered**:
- **Vendor id (iOS IDFV / Android id)**: reset on reinstall on iOS; policy-gated on Android.
- **Derive from device hardware**: the `DeviceInfoPlugin.deviceInfo` fields are not guaranteed stable.

---

## 10. Password-reset email provider + link format

**Decision**:
- A new NestJS `MailModule` using `@nestjs-modules/mailer` + `nodemailer` with SMTP transport. Transport credentials come from env (`MAIL_HOST`, `MAIL_PORT`, `MAIL_USER`, `MAIL_PASS`, `MAIL_FROM`). Dev uses MailHog; prod uses whatever SMTP the ops team provides.
- `POST /auth/forgot-password` generates a `passwordResetToken` (32 bytes, base64url) stored in a new `PasswordReset` collection with `{ userId, tokenHash, expiresAt: now + 30min, consumed: false }`. Email body contains a link of the form `naacademy://auth/reset?token=<token>` plus an `https://naacademy.app/reset?token=<token>` fallback that universal-links into the app.
- `POST /auth/reset-password` accepts `{ token, newPassword }`, atomically marks the reset row consumed, rehashes the user's password, issues tokens, and returns them (so the client can sign the user straight in per FR-004b).
- Endpoint responds 200 regardless of whether the email exists (FR-004a — no account-existence disclosure).

**Rationale**:
- Token in a DB row with `tokenHash` prevents replay-after-leak (even if the token appears in logs).
- 30 minutes is a generally accepted reset-link TTL; long enough for email delay, short enough to limit exposure.
- Universal link + custom scheme gives us coverage on both installed and browser-first cases.

**Alternatives considered**:
- **Firebase Auth / Supabase Auth drop-in**: we already own auth; adding a second provider just for password reset is not worth the complexity.
- **6-digit reset code (no email link)**: the clarification explicitly chose email-based reset (option A), not reset-by-code (option C).

---

## Resolved status

| Topic | Status |
|------|--------|
| State management | Resolved — Riverpod |
| Navigation & deep links | Resolved — go_router + app_links |
| Realtime | Resolved — socket_io_client |
| Token storage & refresh | Resolved — flutter_secure_storage + Dio interceptor |
| Theme system | Resolved — single AppTheme, MediaQuery-driven |
| Code input | Resolved — custom 6-cell widget |
| Exam autosave | Resolved — per-question HTTP + new endpoint |
| Chat conversations list | Resolved — new GET /chat/conversations projection |
| Device id | Resolved — self-generated UUID in secure storage |
| Password reset | Resolved — new Mail module + 2 endpoints + 30-min token |

No NEEDS CLARIFICATION items remain.
