# Data Model: NA-Academy Backend Platform

**Date**: 2026-04-17  
**Phase**: 1 — Design & Contracts  
**Storage**: MongoDB 7 with Mongoose ODM

---

## Entity Relationship Overview

```
User (Student|Teacher|Admin)
  ├── has one → Device
  ├── has many → Session
  ├── has many → SubjectActivation (via Subject Code)
  ├── has many → ExamActivation (via Exam Code)
  ├── has many → ExamAttempt
  ├── has many → Conversation (as participant)
  └── has many → SecurityFlag

Subject
  ├── has many → MediaAsset (videos, images)
  ├── has many → Exam
  ├── has many → SubjectCode
  └── belongs to many → SubjectBundle

SubjectBundle
  └── has many → Subject

Exam
  ├── has many → Question (embedded)
  ├── has many → ExamCode
  └── has many → ExamAttempt

Conversation
  ├── has two → User (participants)
  └── has many → Message

GridFS collections:
  - media.files / media.chunks (videos, images)
  - chatFiles.files / chatFiles.chunks (chat image attachments)
```

---

## Schemas

### User

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `_id` | ObjectId | PK, auto | |
| `email` | String | required, unique, indexed | Lowercase, trimmed |
| `passwordHash` | String | required | bcrypt hash, never exposed |
| `name` | String | required | Full name |
| `role` | String (enum) | required, `student` \| `teacher` \| `admin` | Indexed |
| `status` | String (enum) | `active` \| `suspended` \| `banned` | Default: `active` |
| `assignedSubjects` | ObjectId[] | ref: Subject | Teachers only — subjects they manage |
| `createdAt` | Date | auto (timestamps) | |
| `updatedAt` | Date | auto (timestamps) | |

**Indexes**: `{ email: 1 }` (unique), `{ role: 1 }`

**Validation**:
- Email must match standard email regex
- Role is immutable after creation (except by admin)
- Students cannot have `assignedSubjects`

---

### Device

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `_id` | ObjectId | PK, auto | |
| `userId` | ObjectId | required, ref: User, unique | One device per user |
| `hardwareId` | String | required | Client-provided fingerprint |
| `registeredAt` | Date | required | First activation date |
| `isActive` | Boolean | default: true | Admin can deactivate for reset |

**Indexes**: `{ userId: 1 }` (unique), `{ hardwareId: 1 }`

**State transitions**: `active` → `inactive` (admin reset) → `active` (re-registration on next login)

---

### Session

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `_id` | ObjectId | PK, auto | Referenced as `sessionId` in JWT |
| `userId` | ObjectId | required, ref: User, indexed | |
| `hardwareId` | String | required | Must match Device.hardwareId |
| `refreshTokenHash` | String | required | SHA-256 hash of refresh token |
| `expiresAt` | Date | required | TTL index for auto-cleanup |
| `isActive` | Boolean | default: true | |

**Indexes**: `{ userId: 1 }`, `{ expiresAt: 1 }` (TTL, expireAfterSeconds: 0)

**Lifecycle**: Created on login → deleted on new login (single session) → auto-deleted on TTL expiry

---

### Subject

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `_id` | ObjectId | PK, auto | |
| `title` | String | required | |
| `description` | String | optional | |
| `category` | String | required, indexed | e.g., "Mathematics", "Physics" |
| `isActive` | Boolean | default: true | Soft delete |
| `createdBy` | ObjectId | ref: User | Admin who created |
| `createdAt` | Date | auto | |
| `updatedAt` | Date | auto | |

**Indexes**: `{ category: 1 }`, `{ isActive: 1 }`

---

### SubjectBundle

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `_id` | ObjectId | PK, auto | |
| `name` | String | required | Bundle display name |
| `subjects` | ObjectId[] | ref: Subject, min: 1 | List of included subjects |
| `isActive` | Boolean | default: true | |
| `createdAt` | Date | auto | |

**Validation**: `subjects` array must contain at least 1 valid Subject reference

---

### Exam

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `_id` | ObjectId | PK, auto | |
| `title` | String | required | |
| `subjectId` | ObjectId | required, ref: Subject, indexed | |
| `questions` | Question[] | embedded, min: 1 | See Question sub-schema |
| `hasFreeSection` | Boolean | default: false | |
| `freeQuestionCount` | Number | optional | Number of questions accessible for free |
| `freeAttemptLimit` | Number | optional | Max attempts for free section per student |
| `isActive` | Boolean | default: true | |
| `createdBy` | ObjectId | ref: User | |
| `createdAt` | Date | auto | |
| `updatedAt` | Date | auto | |

**Indexes**: `{ subjectId: 1 }`, `{ isActive: 1 }`

---

### Question (embedded in Exam)

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `_id` | ObjectId | auto | |
| `text` | String | required | Question text |
| `options` | Object[] | required, min: 2 | `[{ label: "A", text: "..." }, ...]` |
| `correctOption` | String | required | Matches one `options[].label` |
| `timeLimitSeconds` | Number | required, min: 5 | Per-question timer |
| `imageRef` | ObjectId | optional | GridFS file reference for question image |
| `order` | Number | required | Display order in exam |

**Validation**: `correctOption` must exist in `options[].label`

---

### SubjectCode (Subject Activation Code)

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `_id` | ObjectId | PK, auto | |
| `code` | String | required, unique | 12-char alphanumeric, stored without dashes |
| `subjectId` | ObjectId | optional, ref: Subject | Null if linked to bundle |
| `bundleId` | ObjectId | optional, ref: SubjectBundle | Null if linked to subject |
| `status` | String (enum) | `available` \| `used` \| `expired` | Default: `available` |
| `batchId` | String | required, indexed | Groups codes from same generation |
| `activatedBy` | ObjectId | optional, ref: User | Student who used it |
| `activatedAt` | Date | optional | |
| `activationDeviceId` | String | optional | Hardware ID at activation |
| `createdAt` | Date | auto | |

**Indexes**: `{ code: 1 }` (unique), `{ status: 1 }`, `{ batchId: 1 }`, `{ subjectId: 1, status: 1 }`, `{ bundleId: 1, status: 1 }`

**State transitions**: `available` → `used` (student activation) or `available` → `expired` (admin revocation)

**Validation**: Exactly one of `subjectId` or `bundleId` must be set (XOR constraint, enforced in service layer)

---

### ExamCode (Exam Activation Code)

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `_id` | ObjectId | PK, auto | |
| `code` | String | required, unique | 12-char alphanumeric |
| `examId` | ObjectId | required, ref: Exam, indexed | |
| `usageType` | String (enum) | `single` \| `multi` | |
| `maxUses` | Number | optional | For multi-use codes |
| `remainingUses` | Number | optional | Decremented on each activation |
| `timeLimitMinutes` | Number | optional | Validity window after first activation (e.g., 1440 = 24h) |
| `firstActivatedAt` | Date | optional | Timestamp of first use (starts validity window) |
| `status` | String (enum) | `available` \| `used` \| `expired` | |
| `batchId` | String | required, indexed | |
| `activatedBy` | ObjectId | optional, ref: User | |
| `activationDeviceId` | String | optional | |
| `createdAt` | Date | auto | |

**Indexes**: `{ code: 1 }` (unique), `{ examId: 1, status: 1 }`, `{ batchId: 1 }`

**State transitions**:
- Single-use: `available` → `used` (one activation)
- Multi-use: `available` → `available` (decrements `remainingUses`) → `used` (when `remainingUses = 0`)
- Time-limited: becomes effectively expired when `now > firstActivatedAt + timeLimitMinutes` (checked at query time, no background job needed)
- Admin revocation: any status → `expired`

---

### ExamAttempt

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `_id` | ObjectId | PK, auto | |
| `examId` | ObjectId | required, ref: Exam, indexed | |
| `studentId` | ObjectId | required, ref: User, indexed | |
| `answers` | Object[] | required | `[{ questionId, selectedOption, answeredAt }]` |
| `score` | Number | required | Computed on submission |
| `totalQuestions` | Number | required | |
| `correctCount` | Number | required | |
| `isFreeAttempt` | Boolean | default: false | |
| `isOffline` | Boolean | default: false | Submitted via offline sync |
| `hmacSignature` | String | optional | For offline submissions |
| `tamperDetected` | Boolean | default: false | Failed HMAC verification |
| `startedAt` | Date | required | |
| `submittedAt` | Date | required | |
| `createdAt` | Date | auto | |

**Indexes**: `{ examId: 1, studentId: 1 }`, `{ studentId: 1, isFreeAttempt: 1 }` (for attempt limit counting)

---

### MediaAsset (metadata — actual files in GridFS)

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `_id` | ObjectId | PK, auto | |
| `gridFsFileId` | ObjectId | required | Reference to `media.files._id` in GridFS |
| `subjectId` | ObjectId | required, ref: Subject, indexed | |
| `filename` | String | required | Original filename |
| `contentType` | String | required | MIME type (video/mp4, image/jpeg, etc.) |
| `fileSize` | Number | required | Bytes |
| `mediaType` | String (enum) | `video` \| `image` | |
| `title` | String | optional | Display title |
| `order` | Number | optional | Display order within subject |
| `uploadedBy` | ObjectId | ref: User | |
| `createdAt` | Date | auto | |

**Indexes**: `{ subjectId: 1, order: 1 }`, `{ mediaType: 1 }`

---

### Conversation

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `_id` | ObjectId | PK, auto | |
| `participants` | ObjectId[2] | required, ref: User | Exactly 2: [student, teacher] |
| `roomId` | String | required, unique | Deterministic: `sorted(participantIds).join(':')` |
| `lastMessageAt` | Date | optional | For sorting conversations |
| `createdAt` | Date | auto | |

**Indexes**: `{ roomId: 1 }` (unique), `{ participants: 1 }`, `{ lastMessageAt: -1 }`

---

### Message

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `_id` | ObjectId | PK, auto | |
| `conversationId` | ObjectId | required, ref: Conversation, indexed | |
| `senderId` | ObjectId | required, ref: User | |
| `recipientId` | ObjectId | required, ref: User, indexed | For offline delivery query |
| `messageType` | String (enum) | `text` \| `image` | |
| `text` | String | optional | Required if `messageType = text` |
| `imageFileId` | ObjectId | optional | GridFS ref in `chatFiles` bucket |
| `status` | String (enum) | `sent` \| `delivered` \| `read` | Default: `sent` |
| `createdAt` | Date | auto | |

**Indexes**: `{ conversationId: 1, createdAt: 1 }`, `{ recipientId: 1, status: 1 }` (pending delivery query)

**State transitions**: `sent` → `delivered` (recipient online, received) → `read` (recipient opened conversation)

---

### SecurityFlag

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `_id` | ObjectId | PK, auto | |
| `studentId` | ObjectId | required, ref: User, indexed | |
| `flagType` | String (enum) | `screen_recording` \| `root_detected` \| `jailbreak_detected` \| `tamper_detected` | |
| `deviceId` | String | required | Hardware ID that reported the flag |
| `actionTaken` | String (enum) | `session_terminated` \| `account_suspended` \| `logged_only` | |
| `metadata` | Object | optional | Additional context from client |
| `reviewedBy` | ObjectId | optional, ref: User | Admin who reviewed |
| `reviewedAt` | Date | optional | |
| `createdAt` | Date | auto | |

**Indexes**: `{ studentId: 1, createdAt: -1 }`, `{ flagType: 1 }`

---

### ActivationRateLimit

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `_id` | ObjectId | PK, auto | |
| `key` | String | required, unique | `activation:{userId}:{hardwareId}` |
| `attempts` | Number | default: 0 | |
| `windowStart` | Date | required | |
| `expiresAt` | Date | required | TTL index, 15 minutes from windowStart |

**Indexes**: `{ key: 1 }` (unique), `{ expiresAt: 1 }` (TTL, expireAfterSeconds: 0)

---

### WatchTime (analytics tracking)

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| `_id` | ObjectId | PK, auto | |
| `studentId` | ObjectId | required, ref: User, indexed | |
| `mediaAssetId` | ObjectId | required, ref: MediaAsset | |
| `subjectId` | ObjectId | required, ref: Subject | Denormalized for aggregation |
| `durationSeconds` | Number | required | Watch time in this session |
| `recordedAt` | Date | required | |

**Indexes**: `{ studentId: 1, subjectId: 1 }` (aggregation), `{ studentId: 1, mediaAssetId: 1 }`

---

## GridFS Buckets

| Bucket Name | Purpose | Chunk Size |
|-------------|---------|------------|
| `media` | Video and image uploads for subjects | 1MB (1,048,576 bytes) |
| `chatFiles` | Image attachments in chat messages | 256KB (default) |

GridFS creates two collections per bucket: `{bucket}.files` (metadata) and `{bucket}.chunks` (binary data).
