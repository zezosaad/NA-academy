# Phase 1 Data Model — NA-Academy Mobile App (Client-Side)

The server's canonical schemas live in `back/src/**/schemas/*.schema.ts` per Principle IV. This document describes the **client-side** projection of those schemas: the Dart types the app holds in memory, their state transitions, and how they persist.

---

## 1. Entity models

All client models are immutable Dart records / `@freezed` classes, constructed by mapping from the backend DTO JSON.

### 1.1 `User`

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `id` | `String` | `/users/me → id` | |
| `name` | `String` | `/users/me → name` | Used in the Today greeting. |
| `email` | `String` | `/users/me → email` | |
| `avatarUrl` | `String?` | derived from `id` via media endpoint if present | |
| `role` | `enum {student, teacher, admin}` | `/users/me → role` | App hard-filters to `student` for all non-P1 behaviour. |
| `status` | `enum {active, suspended}` | `/users/me → status` | If not `active`, sign-out and toast. |

**Persistence**: memory-only (refetched on each app launch after splash).

---

### 1.2 `AuthSession`

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `accessToken` | `String` | `/auth/login → tokens.accessToken` | |
| `refreshToken` | `String` | `/auth/login → tokens.refreshToken` | |
| `expiresAt` | `DateTime` | derived by decoding JWT `exp` | Used by Dio refresh interceptor. |
| `hardwareId` | `String` | generated once on first launch | UUID v4, stored in secure storage (see research §9). |

**Persistence**: `flutter_secure_storage`. Cleared on sign-out and on 401-after-refresh failure.

**State transitions**:
```
unauthenticated ──login/register──▶ authenticated
authenticated ──refresh-ok──▶ authenticated (new tokens)
authenticated ──refresh-fail──▶ unauthenticated (and route to /login)
authenticated ──sign-out──▶ unauthenticated
```

---

### 1.3 `Subject`

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `id` | `String` | `/subjects → _id` | |
| `title` | `String` | `/subjects → title` | Fraunces headline. |
| `description` | `String?` | `/subjects → description` | |
| `coverImageUrl` | `String?` | `/subjects → coverImage` | Optional. |
| `lessonCount` | `int` | `/subjects → lessonCount` | |
| `isUnlocked` | `bool` | derived: client calls `/activation-codes/me` or the `/subjects` response includes an `unlocked` flag per student | **Gap flagged in contracts**: the list endpoint must expose this per-student flag. |
| `progressPercent` | `double` (0.0–1.0) | derived from analytics | Used in Today scroller. |

---

### 1.4 `Lesson`

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `id` | `String` | `/subjects/:id → lessons[i]._id` | |
| `subjectId` | `String` | parent | |
| `title` | `String` | | |
| `order` | `int` | | Determines list order. |
| `status` | `enum {done, active, locked}` | derived per student | Active = next one to take. |
| `mediaAssetId` | `String?` | | For video lessons. |
| `estimatedMinutes` | `int?` | | |

**State transitions (per student)**:
```
locked ──prereq satisfied──▶ active
active ──started──▶ active (in-progress)
active ──completed──▶ done
```

---

### 1.5 `ActivationCode` (client-side view)

Only two outcomes of a redemption attempt matter on the client:

```dart
sealed class ActivationResult {}
class ActivationSuccess extends ActivationResult {
  final String codeType; // 'subject' | 'exam'
  final String targetId; // subjectId or examId
  final String? subjectTitle;
  final String? examTitle;
}
class ActivationFailure extends ActivationResult {
  final ActivationErrorReason reason;
  final DateTime? expiredAt;
  final DateTime? consumedAt;
  final Duration? retryAfter;
}
enum ActivationErrorReason { invalid, expired, alreadyUsed, deviceMismatch, rateLimited }
```

**Screen mapping**:
- `ActivationSuccess` + `codeType == 'subject'` → code-unlocking transition → subject detail
- `ActivationSuccess` + `codeType == 'exam'` → code-unlocking transition → take exam
- `ActivationFailure(expired)` → Code Expired screen
- `ActivationFailure(alreadyUsed)` → Code Already Used screen
- `ActivationFailure(rateLimited)` → inline toast with `retryAfter` countdown
- `ActivationFailure(invalid | deviceMismatch)` → inline error on the code input

---

### 1.6 `Exam`

| Field | Type | Source |
|-------|------|--------|
| `id` | `String` | `/exams → _id` |
| `title` | `String` | |
| `subjectId` | `String` | |
| `durationMinutes` | `int` | |
| `questionCount` | `int` | |
| `attemptsAllowed` | `int` | |
| `attemptsRemaining` | `int` | derived from unused exam-code count for this student (see contracts) |
| `dueDate` | `DateTime?` | |
| `status` | `enum {available, completed, locked}` | derived per student |
| `lastScore` | `double?` | present only if completed |

---

### 1.7 `ExamSession`

Represents one in-progress or completed attempt.

| Field | Type |
|-------|------|
| `id` | `String` |
| `examId` | `String` |
| `startedAt` | `DateTime` |
| `endsAt` | `DateTime` (startedAt + duration) |
| `answers` | `Map<String, AnswerValue>` (questionId → value) |
| `status` | `enum {inProgress, submitted, timedOut}` |

**Persistence (client)**: mirror in memory via Riverpod; every answer tap also hits `POST /exams/sessions/:sessionId/answer` (see contracts). Local copy is only a UI convenience — the server is authoritative for SC-005.

**State transitions**:
```
inProgress ──next answered──▶ inProgress (answer count +1)
inProgress ──submit (user)──▶ submitted
inProgress ──timer==0──▶ timedOut ──auto-submit──▶ submitted
```

---

### 1.8 `ExamScore`

| Field | Type |
|-------|------|
| `sessionId` | `String` |
| `score` | `double` (0.0–1.0) |
| `passFail` | `enum {pass, fail, none}` |
| `perQuestion` | `List<{questionId, studentAnswer, correctAnswer, isCorrect}>` |

Populated by the response of `POST /exams/submit`; consumed by the Result screen.

---

### 1.9 `Conversation`

| Field | Type | Source |
|-------|------|--------|
| `id` | `String` | `/chat/conversations → id` |
| `counterpartyId` | `String` | the tutor's userId |
| `counterpartyName` | `String` | |
| `counterpartyAvatarUrl` | `String?` | |
| `subjectId` | `String` | the conversation's bound subject |
| `lastMessage` | `MessagePreview?` | `{text?, sentAt, senderId, status}` |
| `unreadCount` | `int` | |

**State transitions (message-driven)**:
```
conversation ──incoming new_message──▶ unreadCount++
conversation ──mark_read──▶ unreadCount = 0
conversation ──outgoing message──▶ lastMessage updated
```

---

### 1.10 `Message`

| Field | Type | Source |
|-------|------|--------|
| `id` | `String` | server-generated |
| `conversationId` | `String` | |
| `senderId` | `String` | |
| `recipientId` | `String` | |
| `type` | `enum {text, image}` | matches `ChatMessageType` on the server |
| `text` | `String?` | |
| `imageFileId` | `String?` | maps to `/media/:id/stream` |
| `sentAt` | `DateTime` | |
| `deliveredAt` | `DateTime?` | |
| `readAt` | `DateTime?` | |
| `status` | `enum {pending, sent, delivered, read, failed, deleted}` | `pending` is a client-only transient state for FR-019 queued sends |

**State transitions**:
```
pending (client-only) ──socket send_message ack──▶ sent
sent ──delivery_ack──▶ delivered
delivered ──mark_read──▶ read
pending ──connectivity lost beyond retry budget──▶ failed (surfaced with a retry affordance)
any ──tutor deletes──▶ deleted (rendered as "Message removed" per FR-020)
```

---

### 1.11 `AnalyticsSnapshot`

| Field | Type | Source |
|-------|------|--------|
| `streakDays` | `int` | `/analytics/student/me → streak` |
| `lessonsCompleted` | `int` | |
| `examsTaken` | `int` | |
| `weeklyActivity` | `List<int>` (7 buckets) | |

---

### 1.12 `UserPreferences` (local-only)

| Field | Type | Storage |
|-------|------|---------|
| `themeMode` | `enum {system, light, dark}` | `shared_preferences` |
| `language` | `enum {en}` (v1) | |
| `notificationsEnabled` | `bool` | |

---

## 2. Cross-entity invariants

- **Subject access** = a `SubjectActivationCode` was successfully redeemed by this student on this device. The client never fabricates `Subject.isUnlocked = true` locally; it always trusts the backend's projection.
- **Exam attempts remaining** = number of unused `ExamActivationCode` rows whose `assignedStudentId == currentUserId` (or whose `assignedStudentId` is null, i.e. a batch-issued code the student could redeem). The client reads this from the `/exams` list response.
- **Conversation existence** is derived by `/chat/conversations` which unions (a) existing `Conversation` documents the student participates in, and (b) "virtual" conversations for every unlocked subject whose tutor hasn't yet exchanged a message with this student. The client treats both uniformly — opening a virtual conversation for the first time creates the real `Conversation` doc via the first sent message.
- **Message ordering**: by `sentAt` ascending within a conversation. The client reconciles out-of-order arrivals (offline-queued sends) by stable sort on `sentAt` with `id` as a tiebreaker.

---

## 3. Persistence boundaries

| Concern | Stored where | Rationale |
|---------|--------------|-----------|
| Access + refresh tokens | `flutter_secure_storage` | Sensitive; needs OS-backed encryption. |
| `hardwareId` | `flutter_secure_storage` | Stable identity across reinstalls; same privacy tier as tokens. |
| Theme / language / notifications | `shared_preferences` | Non-sensitive, cheap reads. |
| Last-seen user name (for Splash → Today greeting pre-fetch) | `shared_preferences` | Removes a blocking network call on cold start. |
| Subjects / Exams / Chat list | Riverpod in-memory cache with a TTL invalidation on the relevant Socket.IO event | Simple; no offline lesson consumption in v1. |
| In-progress exam answers | Both: server via per-answer endpoint (authoritative) + Riverpod in-memory (UI) | Zero-loss guarantee (SC-005). |
| Drafted chat messages | Riverpod in-memory + short-lived queue in memory | No durable drafts in v1. |

---

## 4. Mapping to spec requirements

| Spec requirement | Driven by |
|------------------|-----------|
| FR-001 / FR-002 / FR-003 / FR-004 | `AuthSession`, `User` |
| FR-004a / FR-004b | (server-side) `PasswordReset` — not a client-visible entity beyond a token on the deep-link query string |
| FR-005 / FR-006 / FR-007 / FR-008 / FR-009 / FR-010 | `Subject` (isUnlocked), `ActivationResult` |
| FR-011 | `Lesson` |
| FR-012 / FR-013 / FR-014 / FR-015 / FR-016 | `Exam`, `ExamSession`, `ExamScore` |
| FR-017 / FR-018 / FR-019 / FR-020 | `Conversation`, `Message` |
| FR-021 / FR-022 / FR-023 | `User` (greeting name), `Subject` (progress), `Exam` (due today), `AnalyticsSnapshot` (streak) |
| FR-024 / FR-025 / FR-026 | `User`, `UserPreferences`, `AnalyticsSnapshot` |
| FR-027 / FR-028 / FR-029 / FR-030 / FR-031 | No data entities — theme + router concerns |
| FR-032 / FR-033 | All of the above consume backend endpoints; no client-only shape |
| FR-034 | `ApiException` (normalised error envelope) |
| FR-035 / FR-036 / FR-037 | No data entities — MediaQuery + theme concerns |
