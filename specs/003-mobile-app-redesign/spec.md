# Feature Specification: NA-Academy Mobile App (Scholarly Sanctuary)

**Feature Branch**: `003-mobile-app-redesign`
**Created**: 2026-04-24
**Status**: Draft
**Input**: User description: "Create the mobile app from the Claude design. Fetch the design file, read its README, and implement the relevant aspects of the design. Mobile app lives at `na_app/` (Flutter), backend at `back/` (NestJS). Connect the backend and the app."

## Overview

NA-Academy is a mobile-first "scholarly sanctuary" for students and lifelong learners. The mobile app gives each student a single, calm place to (1) unlock paid subjects with a one-time code, (2) study lessons, (3) take code-gated exams, and (4) message their assigned tutor. It is the student-facing counterpart to the existing admin dashboard (where staff issue codes, create exams, and manage users) and it talks to the existing backend API and chat gateway.

The visual identity follows the "Scholarly Sanctuary" design system: warm parchment canvas, Fraunces serif headings, Inter body, pill-shaped primary buttons, hairline cards, sage-teal primary (#3F7D78) and clay secondary (#B06A43), organic progress shapes, no pure black/white surfaces. The complete design source (`na-academy/`) is included in this feature directory under `design-bundle/` — treat it as the visual ground truth.

## Clarifications

### Session 2026-04-24

- Q: Is each subject activation code single-use (one student ever) or multi-use with a seat counter? → A: Single-use — a code binds to exactly one student on first redemption; any later attempt shows "Code already used".
- Q: How do exam codes relate to "attempts allowed" when an exam permits multiple attempts? → A: One code = one attempt. Each exam code unlocks exactly one session and is consumed when the session starts (not on submit); multiple attempts require multiple codes.
- Q: Which tutors can a student message? → A: Only tutors of the subjects the student has unlocked. A 1:1 thread is auto-provisioned per unlocked subject with that subject's tutor; there is no free-form tutor directory or "New chat" search in v1.
- Q: Does v1 include a password reset flow? → A: Yes — basic email-based reset. Login has a "Forgot password?" link → email-entry screen → confirmation screen → deep-linked reset-password screen (new password + confirm).
- Q: What are the limits for image attachments in chat? → A: Up to 10 MB per image, formats JPEG / PNG / WebP / HEIC, one image per message. The composer rejects larger or unsupported files client-side with a human-readable toast.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Unlock and study a subject with a code (Priority: P1)

A signed-in student receives a subject activation code from their tutor or institution (e.g., `NA24CH`). They open the app, see their subjects grid with every unpurchased subject displayed as a locked card with a "Needs code" badge, tap "Enter code", type the 6-character code into an auto-advancing input, see a short unlocking animation ("Verifying → Linking to teacher → Downloading lesson index"), and land on the subject detail screen where they can start or resume lessons.

**Why this priority**: This is the core value loop. Without unlock-and-study, the app has no reason to exist for a student. It covers authentication, code redemption, and the primary study surface in one slice.

**Independent Test**: From a fresh install, complete sign-in, enter a valid subject code, reach the subject detail screen, and open the first lesson. Deliver value = the student can consume a lesson they paid for.

**Acceptance Scenarios**:

1. **Given** a signed-in student with no subjects unlocked, **When** they open the Subjects tab, **Then** every available subject is rendered as a locked card with a lock icon and a "Needs code" chip, and a prominent "Have a subject code?" card sits at the top.
2. **Given** a student on the Enter Subject Code screen, **When** they type a valid, unused code, **Then** the app shows the "Code accepted · unlocking" transition (spinner + 3-step progress list) and routes to the subject detail screen within 3 seconds of the server confirming.
3. **Given** a student on the Enter Subject Code screen, **When** they enter a code that is expired, **Then** the app shows the "Code expired" error state with the entered code in mono type, the expiry timestamp, and two actions: "Try another code" and "Message teacher".
4. **Given** a student on the Enter Subject Code screen, **When** they enter a code that has already been used, **Then** the app shows the "Code already used" error state with the same affordances, and the subject remains locked.
5. **Given** a student on any unlocked Subject detail screen, **When** they tap a lesson marked "Done", "Active", or "Locked", **Then** the app opens an active/completed lesson for viewing and blocks entry to locked lessons with an inline hint.

---

### User Story 2 — Take a code-gated exam and see the result (Priority: P1)

A student opens the Exams tab, sees a list grouped by Available / Completed, taps an available exam, enters a one-time exam code, reads three pre-start notices (timer starts immediately, single attempt, auto-save), unlocks the exam, answers each question (one per screen with a sticky timer and progress bar), submits, and sees a result screen with a score ring, pass/fail badge, per-question review, and a CTA back to subjects.

**Why this priority**: Exams are the assessment half of the product. Without this flow the app is a read-only content viewer and tutors cannot evaluate students.

**Independent Test**: Seed an exam on the backend, enter its code in the app, complete all questions, submit, and verify the score matches backend grading.

**Acceptance Scenarios**:

1. **Given** an exam with status "available", **When** a student taps it, **Then** the app shows the Enter Exam Code screen with the exam summary card (subject, duration, question count, attempts allowed) and a wide mono-font code input.
2. **Given** the student has entered a valid exam code, **When** they tap "Unlock and start exam", **Then** the timer starts, the first question appears, and the student cannot navigate away without triggering a "Leave exam?" confirmation.
3. **Given** the student is on any question, **When** they answer and tap Next, **Then** the answer is auto-saved to the backend before the next question loads and the progress bar advances.
4. **Given** the student has answered all questions, **When** they submit, **Then** the app shows the Result screen with the server-computed score, a score ring, and a collapsible per-question review (correct answer vs. their answer).
5. **Given** the exam timer reaches zero, **When** any answer is unsaved, **Then** the app auto-submits the current state and routes to the Result screen with a "Timed out" badge.

---

### User Story 3 — Message a tutor (Priority: P2)

A student opens the Chat tab, sees their list of conversations (1:1 tutor threads and any group threads), taps a tutor, and exchanges messages in real time — with typing indicators, read receipts, and inline images. Conversations are driven by the backend's existing chat gateway.

**Why this priority**: Tutor access is a key differentiator ("direct access to mentorship" in the product brief), but a student can still study and take exams without it. It is the next slice after the study + exam loop.

**Independent Test**: Two devices (student + tutor account) can exchange a message with typing and read receipts within the thread.

**Acceptance Scenarios**:

1. **Given** a student with active conversations, **When** they open the Chat tab, **Then** each row shows the counterparty avatar/name, last message preview, relative timestamp, and an unread badge if any messages are unread.
2. **Given** a student in a 1:1 tutor thread, **When** the tutor is typing, **Then** a typing indicator (3-dot breathing animation) appears below the last message.
3. **Given** a student sends a text message or an image, **When** the tutor receives it, **Then** the message is marked with a delivered state and flips to "read" when the tutor opens the thread.
4. **Given** the student loses connectivity mid-thread, **When** they try to send a message, **Then** the message is queued with a "Sending…" state and retried when connectivity returns (no message loss).

---

### User Story 4 — Glance at today's study plan (Priority: P3)

A student opens the app and lands on the Today screen: a serif greeting ("Good afternoon, {name}"), a streak indicator, a "Resume where you left off" card, due-today exams, and a horizontal scroller of subject cards with progress rings.

**Why this priority**: Valuable for engagement and daily return, but every primitive is already available from the Subjects and Exams tabs. Ship the study and assessment loops first.

**Independent Test**: After a student has unlocked one subject and started one lesson, the Today screen shows their name, a non-zero streak if applicable, the in-progress lesson in the resume card, and the unlocked subject in the horizontal scroller.

**Acceptance Scenarios**:

1. **Given** a signed-in student at app launch, **When** the Today screen renders, **Then** the greeting uses the current local time of day and the student's display name.
2. **Given** the student has at least one in-progress lesson, **When** they tap the Resume card, **Then** the app opens that lesson in the same state it was left.
3. **Given** an exam is due today, **When** the Today screen renders, **Then** a "Due today" card surfaces it with the remaining time.

---

### User Story 5 — Create an account and complete onboarding (Priority: P3)

A first-time user sees a splash screen (NA monogram, parchment background, soft radial glow, animated loader) that transitions into a 3-slide onboarding pager. They tap "Get started", land on Register, fill Full name / Email / Password (with a show toggle and strength meter) and a Terms checkbox, and complete the sign-up. Returning users tap "I have an account" and see the Login screen.

**Why this priority**: Required to use the app, but can reuse an existing backend account or admin-created account; purely net-new onboarding polish ships last.

**Independent Test**: A new device completes the splash → onboarding → register flow and lands on an empty, locked Subjects grid.

**Acceptance Scenarios**:

1. **Given** a cold launch, **When** the app starts, **Then** it shows the Splash screen with the wordmark and a loader for no more than 3 seconds before advancing.
2. **Given** the onboarding pager, **When** the student reaches the final slide, **Then** the primary CTA reads "Get started" and the secondary CTA is the ghost text link "I have an account".
3. **Given** the Register form, **When** the student submits with valid inputs and accepts terms, **Then** the backend creates the account, issues tokens, and the app routes to the Subjects tab (all subjects locked until a code is entered).
4. **Given** the Login screen, **When** the student taps "Forgot password?" and enters an email, **Then** the app shows a generic "Check your inbox" confirmation regardless of whether the email is registered, and the backend emails a time-limited reset link to the address if the account exists.
5. **Given** the student opens a valid reset link on their device, **When** they enter a new password that meets the strength rules and confirm it, **Then** the backend accepts the reset, signs them in, and routes them to the Today tab.

---

### Edge Cases

- Offline at app launch: show the cached last state for Today, Subjects, Exams (read-only); block Chat send and code redemption with clear retry affordances.
- Expired or revoked auth token: intercept 401, clear tokens, route back to Login with a non-alarming toast ("Session ended — please sign in again").
- Student pastes a subject code from the clipboard: the 6-box input must accept the pasted value and distribute characters across cells.
- Student backgrounds the app mid-exam: when they return within the timer window, restore answers from auto-save; past the window, auto-submit.
- Tutor deletes a message in a chat thread: the student sees a placeholder ("Message removed") without disrupting scroll position.
- Locked subject tapped from the Today screen: open the Enter Subject Code screen pre-filled with that subject's context instead of the bare subjects grid.
- Code entry from within an existing screen (e.g., a locked subject card): use the bottom-sheet variant of Enter Subject Code instead of a full-screen navigation.

## Requirements *(mandatory)*

### Functional Requirements

**Identity & session**

- **FR-001**: Students MUST be able to create an account using full name, email, and password, with server-side validation and terms acceptance.
- **FR-002**: Students MUST be able to sign in with email and password and receive a session that persists across app restarts via secure device storage.
- **FR-003**: The app MUST automatically refresh the session when the backend signals that the current token is nearing expiry, and MUST sign the user out on a refresh failure.
- **FR-004**: Students MUST be able to sign out from the Profile screen, which clears all tokens and cached user-scoped data on the device.
- **FR-004a**: The Login screen MUST expose a "Forgot password?" link that routes to an email-entry screen. Submitting a known email MUST display a confirmation state ("Check your inbox…") regardless of whether the email is registered (to avoid account-existence disclosure), and the backend MUST email a time-limited reset link to the address if it exists.
- **FR-004b**: The reset link MUST deep-link into the app to a Reset Password screen that accepts a new password and confirmation, enforces the same strength rules as Register, and signs the student in on success.

**Subject access & study**

- **FR-005**: The Subjects grid MUST display every subject the backend exposes to the student, rendering unpurchased subjects as locked cards with a "Needs code" chip and a lock icon.
- **FR-006**: Students MUST be able to redeem a subject activation code via a dedicated Enter Subject Code screen OR a bottom-sheet variant launched from a locked card.
- **FR-007**: The subject code input MUST be 6 cells (alphanumeric), auto-advance on keystroke, accept paste across cells, and render in a monospaced face.
- **FR-008**: On a valid code, the app MUST show the "Code accepted · unlocking" transition with a 3-step progress list before routing to the subject detail.
- **FR-009**: On an invalid, expired, or already-used code, the app MUST show the corresponding error state with the entered code preserved in mono and two CTAs: retry another code, or message the student's teacher. A code is "already used" whenever it has been redeemed by any student (single-use semantics) — the error copy does NOT distinguish "used by you" from "used by someone else".
- **FR-010**: The app MUST enforce the server's per-account and per-code rate limits by disabling the Unlock button and showing a wait-time hint when the backend returns a rate-limit response.
- **FR-011**: The Subject Detail screen MUST list lessons with clear status (Done, Active, Locked) and allow the student to open any lesson that is not Locked.

**Exams**

- **FR-012**: The Exams list MUST show two groups — Available and Completed — with metadata per exam (title, subject, duration, question count, attempts remaining). "Attempts remaining" equals the number of unused exam codes the student currently holds for that exam.
- **FR-013**: Students MUST enter a valid exam code before a take-exam session can begin; the Unlock button MUST remain disabled until the code input reaches the expected length. Each exam code unlocks exactly one session and is consumed the moment the session starts (the timer first ticks) — not on submit — so an abandoned attempt still burns the code.
- **FR-014**: While taking an exam, the app MUST show a sticky timer and progress bar, render one question per screen, auto-save each answer to the backend before advancing, and warn the student on back-navigation attempts.
- **FR-015**: The app MUST submit the exam automatically when the timer expires using whatever answers have been saved.
- **FR-016**: The Result screen MUST show the server-computed score, a score ring, a pass/fail indicator where applicable, and a per-question review (student answer vs. correct answer).

**Chat**

- **FR-017**: Students MUST be able to see a list of their conversations with avatar, name, last-message preview, timestamp, and unread count. Conversations are auto-provisioned as 1:1 threads with the tutor of each subject the student has unlocked; the app does NOT expose a tutor directory, search, or "New chat" composer in v1. If the student has no unlocked subjects, the Chat tab shows an empty state pointing them to enter a subject code.
- **FR-018**: The 1:1 thread screen MUST render student messages right-aligned in a pill bubble and tutor messages left-aligned with a small avatar, support inline images, and show typing indicators and read receipts using the backend's chat gateway. Image attachments are limited to one per message in the formats JPEG, PNG, WebP, or HEIC, up to 10 MB each; the composer MUST reject oversize or unsupported files client-side with a toast before upload starts.
- **FR-019**: Messages sent while offline MUST be queued with a visible "Sending…" state and retried on reconnect without duplicating on success.
- **FR-020**: The app MUST show "Message removed" in place of messages deleted by the other party without affecting scroll state.

**Today / Home**

- **FR-021**: The Today screen MUST show a greeting that uses the current local time of day and the student's display name.
- **FR-022**: The Today screen MUST surface a Resume card when the student has any in-progress lesson and a "Due today" section when an available exam's due date equals today.
- **FR-023**: The Today screen MUST include a horizontal scroller of unlocked subject cards with a progress indicator per subject.

**Profile**

- **FR-024**: The Profile screen MUST show the student's avatar, display name, email, and a stats block (e.g., streak, lessons completed, exams taken) and a weekly activity chart populated from the backend analytics endpoint.
- **FR-025**: The Profile screen MUST expose Settings (theme, language, notifications) and Sign out.
- **FR-026**: Students MUST be able to switch the app between light and dark themes and have that preference persist across app restarts.

**Navigation & chrome**

- **FR-027**: The in-app shell MUST use a 5-tab floating pill tab bar (Today, Subjects, Exams, Chat, Profile) with haptic feedback on tab change and an icon-only active pill in the accent color.
- **FR-028**: The app MUST route unauthenticated users to the Splash → Onboarding → Login/Register flow and authenticated users directly to the Today tab on launch.

**Visual system (from the design bundle)**

- **FR-029**: The app MUST apply the Scholarly Sanctuary tokens: parchment canvas `#F4EFE5`, ink `#1F1C16`, sage-teal primary `#3F7D78`, clay secondary `#B06A43`, border-subtle `#E0D8C6`, Fraunces for display/headline, Inter for body/UI, and JetBrains Mono for code/exam codes.
- **FR-030**: Primary actions MUST be pill-shaped (radius 999px); cards MUST use radius 18px and a hairline bone border; the primary color MUST occupy ≤10% of any given screen (Rarity Rule).
- **FR-031**: The app MUST ship at minimum the 21 screens: the 19 in the design bundle (Splash, Onboarding, Login, Register, Today, Subjects, Subjects-locked, Subject detail, Enter subject code, Code-entry bottom sheet, Code accepted (unlocking), Code expired, Code already used, Exams, Enter exam code, Take exam, Exam result, Chat list, Chat thread, Profile) **plus two auth-recovery screens added during clarification: Forgot Password (email entry + confirmation state) and Reset Password (deep-linked, new-password entry)**. The two new screens MUST reuse the Scholarly Sanctuary visual tokens and layout conventions of the Login/Register screens.

**Connectivity to backend**

- **FR-032**: The mobile app MUST consume the existing REST endpoints exposed by `back/` for auth, users, subjects, subject bundles, exams, activation-codes, and analytics — no new backend endpoints are introduced by this feature unless a gap is identified during planning.
- **FR-033**: The app MUST use the existing realtime chat gateway exposed by `back/` for conversation and message delivery, typing indicators, and read receipts.
- **FR-034**: The app MUST surface a human-readable error toast for every 4xx/5xx response and MUST NOT leak raw error payloads into the UI.

**Accessibility & localization**

- **FR-035**: Touch targets for primary controls (buttons, tab bar, code cells) MUST be ≥44×44 density-independent pixels.
- **FR-036**: The app MUST respect the operating system's reduced-motion setting by disabling non-essential transitions and scale animations.
- **FR-037**: The app MUST support dynamic text scaling up to 1.3× without clipping primary actions or breaking layout on the Today, Subject detail, Take exam, and Chat thread screens.

### Key Entities

- **Student (User)**: The signed-in human. Attributes: id, display name, email, avatar, role (student), created date, preferences (theme, language, notifications).
- **Subject**: A course the student can unlock with a code. Attributes: id, title, short description, cover color/imagery hint, lesson count, progress percentage (per student), lock state (per student).
- **Lesson**: A unit inside a subject. Attributes: id, parent subject, title, order, status per student (done/active/locked), content pointer, estimated duration.
- **Subject Activation Code**: A **single-use** code issued by staff. On first redemption the code binds irreversibly to the redeeming student. Attributes: code string (6 chars alphanumeric), bound subject, status (active/used/expired), redeemed-by student id (nullable), redeemed-at timestamp, rate-limit metadata.
- **Exam**: An assessment bound to a subject. Attributes: id, title, subject, duration, question count, attempts allowed, due date, availability state per student.
- **Exam Activation Code**: A **single-use** code required to open an exam session. Consumed when the session starts (timer begins), not on submit. Attributes: code string, bound exam, assigned-student id (nullable — may be pre-assigned or batch-issued), status (active/used/expired), consumed-at timestamp, consumed-by session id.
- **Exam Session**: A single attempt by a student. Attributes: id, exam, student, started/ended timestamps, answers, auto-save cursor.
- **Exam Score**: The server-computed result of a session. Attributes: session id, score, pass/fail flag, per-question correctness.
- **Conversation**: A 1:1 thread between a student and the tutor of one of the student's unlocked subjects. Auto-provisioned on subject unlock. Attributes: id, participants (student + tutor), bound subject, last message preview, unread count per participant. Group threads are out of scope for v1.
- **Message**: A single item in a conversation. Attributes: id, conversation, sender, content (text or image), sent/delivered/read timestamps, deleted flag.
- **Analytics Snapshot**: The data behind the Profile stats and weekly chart. Attributes: streak, lessons completed, exams taken, weekly activity series.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 90% of first-time students complete the Splash → Onboarding → Register → first subject unlock flow within 4 minutes on a mid-range device.
- **SC-002**: A valid subject or exam code is redeemed end-to-end (tap → result screen) in under 3 seconds on a typical 4G connection (p50), and under 6 seconds at p95.
- **SC-003**: 95% of code-redemption error states (invalid / expired / already used) reach the student in under 1.5 seconds and preserve the entered code for retry.
- **SC-004**: Chat message round-trip from student send to tutor read-receipt appears on the student's device in under 2 seconds at p95 on a stable network.
- **SC-005**: Exams finish with zero data loss — in 1,000 simulated app-background/terminate events mid-exam, 100% of previously auto-saved answers are restored on resume and no session is lost.
- **SC-006**: The 19 screens in the design bundle are reachable from a navigable build, and each matches the design bundle's visual intent (colors, typography, shape, spacing) as verified by a design-review pass against `design-bundle/project/`.
- **SC-007**: The app passes an accessibility audit covering ≥44pt touch targets, dynamic text scale to 1.3×, and reduced-motion respect on the five core screens (Today, Subject detail, Take exam, Chat thread, Profile).
- **SC-008**: First-launch cold start is under 2.5 seconds on a mid-range device from splash to Today (or Login) — excluding network fetches.

## Assumptions

- Primary target platforms for v1 are iOS and Android phones (tablet and web out of scope).
- The existing `back/` NestJS service already exposes the endpoints required for auth, subjects, exams, activation-codes, chat, and analytics. Any gap found during planning will be filed as backend work under this feature, not a parallel one.
- The chat surface is **student↔tutor messaging** only — there is no in-app LLM or AI chat in this feature. This is explicit in the design handoff transcript.
- Activation codes are issued out-of-band (admin dashboard, in-person, email) — the mobile app is a redemption surface, not an issuance surface.
- Students authenticate with email + password for v1. OAuth / SSO, magic links, and phone-number auth are out of scope.
- The app is English-first. Arabic/RTL support is a fast-follow and noted as an open question rather than a launch requirement.
- Dark mode ships at launch (the design handoff provides a dark-mode toggle), with the light theme as default.
- The existing `na_app/` Flutter scaffold (with feature folders for `auth`, `home`, `subjects`, `exams`, `chat`, `profile`, `onboarding`) is the build target. The `front/` React Native codebase is a separate track and is not migrated by this feature.
- Offline support is limited to cached reads of Today/Subjects/Exams lists and a queued-send experience for chat; full offline lesson consumption and offline exam taking are out of scope for v1.
- Media/file attachments in chat are limited to images for v1 (the backend already supports media).
- Push notifications are out of scope for v1 (the backend `devices` module can be wired in a follow-up).

## Dependencies

- Backend API and realtime chat gateway under `back/` must be running and reachable from the device.
- Activation codes must be seeded (by staff via the admin dashboard at `admin-dashboard/`) for the unlock flows to be demonstrable end-to-end.
- Design bundle under `specs/003-mobile-app-redesign/design-bundle/` is the visual ground truth.
