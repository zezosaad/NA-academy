# Phase 1 API Contracts — NA-Academy Mobile App

This document is the **single source of truth** reviewers use to verify Constitution Principle IV (Contract-Driven Multi-Surface Consistency). Every mobile call goes to a documented backend route with a NestJS DTO + `class-validator` rules + Swagger entry.

- "Existing" = already live in `back/src/` today; no change required.
- "Existing +Δ" = route exists but behaviour or response shape needs an incremental change.
- "NEW" = must be added to `back/` before the mobile feature that depends on it can merge.

All responses follow the backend's current convention (no custom envelope). Errors are standard Nest `HttpException` JSON, which the Dio interceptor normalises into `ApiException { statusCode, code, message }` on the client (FR-034).

---

## 1. Auth

| FR | Method + Path | Status | Request | Response (200/201) |
|----|---------------|--------|---------|---------------------|
| FR-001 | `POST /auth/register` | Existing | `{ name, email, password, hardwareId }` | `{ user: {id, name, email, role}, tokens: {accessToken, refreshToken} }` |
| FR-002 | `POST /auth/login` | Existing | `{ email, password, hardwareId }` | same shape as register |
| FR-003 | `POST /auth/refresh` | Existing | `{ refreshToken }` | `{ accessToken, refreshToken }` |
| FR-004 | `POST /auth/logout` | Existing | — (Authorization header) | `{ message }` |
| FR-004a | `POST /auth/forgot-password` | **NEW** | `{ email }` | `204 No Content` regardless of whether the email exists (no account-existence disclosure) |
| FR-004b | `POST /auth/reset-password` | **NEW** | `{ token, newPassword, hardwareId }` | `{ user, tokens }` — signs the student in on success |

### NEW endpoint detail — `POST /auth/forgot-password`

- **DTO**: `ForgotPasswordDto { @IsEmail email: string }`
- **Behaviour**:
  1. Look up user by email.
  2. If found: generate a 32-byte base64url token, hash with SHA-256, store `{ userIdHash, tokenHash, expiresAt: now + 30min, consumed: false }` in the new `PasswordReset` collection, and send an email via the new `MailModule` containing a link of the form `naacademy://auth/reset?token=<raw>` (with `https://naacademy.app/reset?token=<raw>` as the universal-link fallback).
  3. If not found: no-op silently.
  4. Always respond `204`.

### NEW endpoint detail — `POST /auth/reset-password`

- **DTO**: `ResetPasswordDto { @IsString token: string; @MinLength(8) newPassword: string; @IsString hardwareId: string }`
- **Behaviour**:
  1. Hash `token` with SHA-256, look up the `PasswordReset` row, verify `consumed === false` and `expiresAt > now`.
  2. Atomically set `consumed = true`.
  3. Hash the new password, update the `User` row.
  4. Issue a fresh `{accessToken, refreshToken}` pair and return `{ user, tokens }`.
  5. Reject expired or consumed tokens with `410 Gone`.

---

## 2. Users & Profile

| FR | Method + Path | Status | Response shape |
|----|---------------|--------|----------------|
| FR-021 / FR-024 / FR-025 | `GET /users/me` | Existing | `{ id, email, name, role, status }` — the current Today greeting + Profile name source. |

---

## 3. Subjects & Lessons

| FR | Method + Path | Status | Response |
|----|---------------|--------|----------|
| FR-005 / FR-022 / FR-023 | `GET /subjects` | **Existing +Δ** | `{ data: Subject[], total, page, limit }`. Add a per-student `isUnlocked: boolean` field on each `Subject` when `role === 'student'` (currently the controller does not project this). |
| FR-011 | `GET /subjects/:id` | Existing | Subject + populated lessons array. |
| FR-011 | `GET /subjects/:id/media` | Existing | List of media assets for lessons (access-gated on the server via `AccessCheckHelper.hasSubjectAccess`). |

### Δ — `GET /subjects` per-student unlock flag

Change (backend): inside `SubjectsService.findAllSubjects(query, role)`, when `role === 'student'`, join against `SubjectCode.findOne({ bundleId: subject._id, redeemedByUserId: userId, status: 'used' })` (or the equivalent existing access helper) and set `subject.isUnlocked = Boolean(row)`. The client (FR-005) uses this flag to render the lock icon and "Needs code" chip.

**Impact**: additive. No breaking change to admin/teacher consumers (the new field is present for them too but semantically `true`).

---

## 4. Activation Codes

| FR | Method + Path | Status | Request / Response |
|----|---------------|--------|---------------------|
| FR-006 / FR-007 / FR-008 / FR-009 / FR-013 | `POST /activation-codes/activate` | Existing | `{ code: string }` → `{ type: 'subject' | 'exam', targetId, title?, subjectId?, examId? }` on success; throws `400 / 403 / 429` on failure with one of `INVALID`, `EXPIRED`, `ALREADY_USED`, `DEVICE_MISMATCH`, `RATE_LIMITED`. |
| FR-010 | Same | Existing | The `ActivationThrottlerGuard` already enforces rate limits server-side; the client translates 429 responses into the rate-limit affordance and reads `Retry-After` / response body for wait time. |

### Gap flagged in research §7 — exam attempts semantics

The clarification locked "one code = one attempt, consumed on start". The existing `/activate` endpoint already consumes the code and the server's `hasExamAccess` check confirms access. No endpoint change; the `POST /exams/:id/start` flow is what actually "starts the timer" and therefore is the moment the code is considered consumed for accounting purposes.

---

## 5. Exams

| FR | Method + Path | Status | Notes |
|----|---------------|--------|-------|
| FR-012 | `GET /exams` | **Existing +Δ** | Response must include `attemptsRemaining: number` per exam per student (derived from unused exam codes). Current response does not expose this field for the student role. |
| FR-013 / FR-014 | `GET /exams/:id` | Existing | Returns the exam + filtered questions (no answers for students). |
| FR-013 | `POST /exams/:id/start` | Existing | Validates `hasExamAccess` via activation codes; returns `{ session, exam }`. Starting the session is the moment the exam code is "consumed" (spec clarification). |
| FR-014 | `POST /exams/sessions/:sessionId/answer` | **NEW** | Incremental auto-save. `{ questionId, value }` → `204`. Upserts the answer into the session document. |
| FR-015 / FR-016 | `POST /exams/submit` | Existing | `{ sessionId, answers }` → `{ score, passFail?, perQuestion[] }`. The submit call remains a defensive full-snapshot upsert. |

### NEW endpoint detail — `POST /exams/sessions/:sessionId/answer`

- **DTO**: `SaveAnswerDto { @IsMongoId questionId: string; @IsDefined value: string | string[] }`
- **Guard**: `Roles('student')`, plus a service-level check that `session.userId === currentUserId` and `session.status === 'inProgress'`.
- **Behaviour**: `$set` the answer by `questionId` into the session's answers map; `$set updatedAt = now`. Idempotent — the client may retry on network failure.
- **Response**: `204 No Content`.

### Δ — `GET /exams` per-student attempts remaining

Change (backend): inside `ExamsService.findAllExams(query)`, when invoked by a student, join against `ExamCode.count({ examId: exam._id, assignedStudentId: userId | null, status: 'active' })` and set `exam.attemptsRemaining`. No change for admin/teacher consumers beyond an extra field being present.

---

## 6. Chat

### REST

| FR | Method + Path | Status | Response |
|----|---------------|--------|----------|
| FR-017 | `GET /chat/conversations` | **NEW** | `{ conversations: ConversationPreview[] }` — see shape below. |
| FR-019 | `GET /chat/pending` | Existing | Fetches offline messages on reconnect/launch; also delivered opportunistically via socket `pending_messages`. |

#### NEW endpoint detail — `GET /chat/conversations`

- **Response shape**:
  ```ts
  type ConversationPreview = {
    id: string;                 // Conversation._id (present only if a message has been exchanged)
    virtual: boolean;           // true if no Conversation doc exists yet — client derived from unlocked subjects
    counterpartyId: string;     // tutor's userId
    counterpartyName: string;
    counterpartyAvatarUrl: string | null;
    subjectId: string;
    subjectTitle: string;
    lastMessage: {
      text: string | null;
      hasImage: boolean;
      sentAt: string;           // ISO
      senderId: string;
      status: 'sent' | 'delivered' | 'read';
    } | null;
    unreadCount: number;
  };
  ```
- **Behaviour**: union of (a) conversations the student participates in and (b) "virtual" conversations derived from unlocked subjects whose subject has a `teacherId` and no existing `Conversation` with that tutor.
- **Guard**: `Roles('student', 'teacher', 'admin')`. Teacher and admin get their own counterparty lists by symmetry.

#### Δ — `canChat()` scoping

Backend change: `ChatService.canChat(senderId, recipientId)` currently returns `true`. Tighten to: a student may chat only with a tutor that teaches a subject the student has unlocked; a tutor may chat only with students who have unlocked a subject the tutor teaches; admins remain unrestricted. Emit a specific socket error (`'unauthorized_conversation'`) when blocked so the client can show a toast instead of silently dropping the message.

### Socket.IO — namespace `/chat` (existing; no protocol change)

| Event | Direction | Payload | Notes |
|-------|-----------|---------|-------|
| connect | client → server | `auth.token = <access>` | Reuses the same access token the REST client carries. |
| `send_message` | client → server | `{ recipientId, text?, imageFileId?, messageType }` | `imageFileId` comes from `POST /media/chat/upload`. Ack returns `{ messageId, status: 'sent' }`. FR-018. |
| `delivery_ack` | client → server | `{ messageId, senderId }` | FR-018. |
| `mark_read` | client → server | `{ conversationId, senderId }` | FR-018. |
| `typing` | client → server | `{ recipientId, isTyping }` | FR-018. |
| `new_message` | server → client | full message doc | FR-018. |
| `pending_messages` | server → client on connect | array of messages | FR-019 offline retry ingress. |
| `status_update` | server → client | `{ messageId, status }` | FR-018. |
| `conversation_read` | server → client | `{ conversationId }` | FR-018. |
| `typing_indicator` | server → client | `{ userId, isTyping }` | FR-018. |

---

## 7. Media

| FR | Method + Path | Status | Notes |
|----|---------------|--------|-------|
| FR-018 | `POST /media/chat/upload` | **Existing +Δ** | Current handler is a simplified passthrough that calls `mediaService.uploadMedia`. Δ: enforce the 10 MB cap and `image/jpeg|png|webp|heic` MIME whitelist (FR-018) server-side; reject with `415` or `413` otherwise. Returns `{ fileId }`. |
| FR-011 | `GET /media/:id/stream` | Existing | Access-gated by activation; used for lesson media and chat image rendering. |
| FR-011 | `GET /subjects/:id/media` | Existing | |

---

## 8. Analytics

| FR | Method + Path | Status |
|----|---------------|--------|
| FR-024 | `GET /analytics/student/me` | Existing — returns the streak, lessons-completed, exams-taken, and weekly activity series that populate the Profile stats and weekly chart. |
| FR-023 | `POST /analytics/watch-time` | Existing — called by the lesson player to track watch time; also feeds the "Resume where you left off" card on Today. |

---

## 9. Backend gap summary (merge-order constraint)

These server-side additions MUST land before the mobile feature that depends on them:

| # | Backend change | Blocks mobile work on | Target module |
|---|----------------|-----------------------|---------------|
| B1 | `POST /auth/forgot-password` + `POST /auth/reset-password` + `PasswordReset` schema + `MailModule` | Forgot Password + Reset Password screens (User Story 5, P3) | `back/src/auth/` + `back/src/mail/` |
| B2 | `GET /subjects` adds per-student `isUnlocked` flag | Subjects grid (User Story 1, P1) | `back/src/subjects/` |
| B3 | `GET /exams` adds per-student `attemptsRemaining` field | Exams list (User Story 2, P1) | `back/src/exams/` |
| B4 | `POST /exams/sessions/:sessionId/answer` per-answer autosave | Take Exam screen (User Story 2, P1) | `back/src/exams/` |
| B5 | `GET /chat/conversations` + tighten `canChat()` scoping | Chat list + thread (User Story 3, P2) | `back/src/chat/` |
| B6 | `POST /media/chat/upload` enforces 10 MB + MIME whitelist | Chat image attachments (User Story 3, P2) | `back/src/media/` |

B1, B2, B3, B4, B6 block P1/P3 slices and should be tackled first during `/speckit.tasks`. B5 blocks the P2 slice.
