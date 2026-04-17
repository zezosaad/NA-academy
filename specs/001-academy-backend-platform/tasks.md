# Tasks: NA-Academy Backend Platform

**Input**: Design documents from `specs/001-academy-backend-platform/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/rest-api.md, contracts/websocket-api.md

**Tests**: Not explicitly requested in spec — test tasks are excluded. Test infrastructure is scaffolded but test authoring is deferred.

**Organization**: Tasks grouped by user story. User stories ordered by dependency chain, not strictly by priority, because US4 (Content Management, P1) must precede US1/US2/US3.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US9). Setup and Foundational phases have no story label.
- Exact file paths included per task

---

## Phase 1: Setup

**Purpose**: NestJS project scaffold, dependencies, tooling

- [ ] T001 Initialize NestJS project with TypeScript — `nest new` with `src/main.ts`, `src/app.module.ts`, `tsconfig.json`, `package.json`
- [ ] T002 Install all required dependencies — `@nestjs/mongoose`, `@nestjs/swagger`, `@nestjs/jwt`, `@nestjs/passport`, `@nestjs/websockets`, `@nestjs/platform-socket.io`, `@nestjs/throttler`, `socket.io`, `class-validator`, `class-transformer`, `exceljs`, `@fast-csv/format`, `passport-jwt`, `bcrypt`, `busboy`, `mongoose`; devDeps: `@types/busboy`, `@types/bcrypt`
- [ ] T003 [P] Configure ESLint and Prettier — `.eslintrc.js`, `.prettierrc`
- [ ] T004 [P] Create `.env.example` per `quickstart.md` and update `.gitignore` to exclude `.env`, `dist/`, `node_modules/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can begin. Includes config, common utilities, auth, users, and devices modules.

**CRITICAL**: No user story work can begin until this phase is complete.

### Configuration & Common

- [ ] T005 Create environment config loader — `src/config/configuration.ts` exporting typed config from `process.env` (PORT, MONGODB_URI, JWT_SECRET, JWT_ACCESS_EXPIRATION, JWT_REFRESH_EXPIRATION, EXAM_HMAC_SECRET, MAX_VIDEO_SIZE_MB, MAX_IMAGE_SIZE_MB, ACTIVATION_RATE_LIMIT, ACTIVATION_RATE_WINDOW_MINUTES, GRIDFS_VIDEO_CHUNK_SIZE, GRIDFS_CHAT_CHUNK_SIZE)
- [ ] T006 [P] Create custom decorators — `src/common/decorators/roles.decorator.ts` (@Roles with SetMetadata), `src/common/decorators/current-user.decorator.ts` (@CurrentUser extracting user from request), `src/common/decorators/public.decorator.ts` (@Public marking routes as unauthenticated)
- [ ] T007 [P] Create common DTOs — `src/common/dto/pagination.dto.ts` (page, limit, search query params with class-validator), `src/common/dto/api-response.dto.ts` (standardized response wrapper with data, total, page, limit)
- [ ] T008 [P] Create global validation pipe config — `src/common/pipes/validation.pipe.ts` (whitelist: true, forbidNonWhitelisted: true, transform: true)
- [ ] T009 [P] Create global exception filter — `src/common/filters/all-exceptions.filter.ts` (catch all exceptions, format as `{ statusCode, message, error, timestamp }`)
- [ ] T010 [P] Create response transform interceptor — `src/common/interceptors/response-transform.interceptor.ts` (wrap successful responses in standard envelope)

### Users Module

- [ ] T011 Create User schema — `src/users/schemas/user.schema.ts` with fields per data-model.md (email unique+indexed, passwordHash, name, role enum, status enum, assignedSubjects, timestamps). Include index definitions.
- [ ] T012 Create Users service — `src/users/users.service.ts` with `create()`, `findByEmail()`, `findById()`, `findAll()` (paginated, filtered by role/status/search), `updateStatus()`. Hash password with bcrypt on create.
- [ ] T013 Create Users controller — `src/users/users.controller.ts` with `GET /api/v1/users` (@Roles admin, paginated), `PATCH /api/v1/users/:id/status` (@Roles admin), `PATCH /api/v1/users/:id/device-reset` (@Roles admin)
- [ ] T014 Create Users module — `src/users/users.module.ts` registering User schema, exporting UsersService
- [ ] T015 Create Users DTOs — `src/users/dto/create-user.dto.ts`, `src/users/dto/update-status.dto.ts`, `src/users/dto/list-users-query.dto.ts`

### Devices Module

- [ ] T016 Create Device schema — `src/devices/schemas/device.schema.ts` with fields per data-model.md (userId unique+indexed, hardwareId indexed, registeredAt, isActive). Include index definitions.
- [ ] T017 Create Devices service — `src/devices/devices.service.ts` with `registerDevice()`, `findByUserId()`, `validateHardwareId()`, `resetDevice()`. Enforce one device per user.
- [ ] T018 Create Devices module — `src/devices/devices.module.ts` registering Device schema, exporting DevicesService

### Auth Module

- [ ] T019 Create Session schema — `src/auth/schemas/session.schema.ts` with fields per data-model.md (userId indexed, hardwareId, refreshTokenHash, expiresAt TTL index, isActive)
- [ ] T020 Create Auth DTOs — `src/auth/dto/register.dto.ts` (email, password, name, hardwareId), `src/auth/dto/login.dto.ts` (email, password, hardwareId), `src/auth/dto/refresh-token.dto.ts`, `src/auth/dto/token-response.dto.ts`
- [ ] T021 Create JWT strategy — `src/auth/strategies/jwt.strategy.ts` extracting Bearer token, validating payload `{ sub, role, hardwareId, sessionId }`, checking session exists in DB (single-session enforcement)
- [ ] T022 Create Local strategy — `src/auth/strategies/local.strategy.ts` validating email + password via UsersService
- [ ] T023 Create Auth service — `src/auth/auth.service.ts` with `register()` (create user + device + session + tokens), `login()` (validate creds, check device, deleteMany existing sessions, create new session, issue tokens), `refresh()` (validate refresh token hash, rotate tokens), `logout()` (delete session). Access JWT 15min, refresh token 7d opaque.
- [ ] T024 Create Auth controller — `src/auth/auth.controller.ts` with `POST /api/v1/auth/register` (@Public), `POST /api/v1/auth/login` (@Public), `POST /api/v1/auth/refresh` (@Public), `POST /api/v1/auth/logout`
- [ ] T025 Create Auth module — `src/auth/auth.module.ts` registering Session schema, importing UsersModule + DevicesModule + JwtModule + PassportModule

### Guards (depend on Auth)

- [ ] T026 Create JwtAuthGuard — `src/common/guards/jwt-auth.guard.ts` extending AuthGuard('jwt'), checking @Public metadata to skip auth on public routes
- [ ] T027 Create RolesGuard — `src/common/guards/roles.guard.ts` reading @Roles metadata from reflector, comparing with `request.user.role`

### App Bootstrap

- [ ] T028 Configure `src/main.ts` — apply global ValidationPipe, AllExceptionsFilter, ResponseTransformInterceptor, Swagger setup (`/api/docs`), CORS, set global prefix `/api/v1`, enable shutdown hooks
- [ ] T029 Wire `src/app.module.ts` — import ConfigModule (forRoot with configuration.ts), MongooseModule (forRootAsync from config), ThrottlerModule, AuthModule, UsersModule, DevicesModule. Apply JwtAuthGuard and RolesGuard as APP_GUARD providers.

**Checkpoint**: Foundation ready — auth works, users can register/login, device binding enforced, JWT + RBAC active. All user stories can now begin.

---

## Phase 3: User Story 4 — Admin Manages Academic Content (Priority: P1)

**Goal**: Admin/teacher can create subjects, bundles, exams with questions, and upload/manage media (video + images via GridFS).

**Independent Test**: Create a subject, upload a video, create an exam with questions — verify all stored correctly and retrievable.

**Why before US1**: Subjects and exams must exist before activation codes can be generated for them.

### Schemas

- [ ] T030 [P] [US4] Create Subject schema — `src/subjects/schemas/subject.schema.ts` with fields per data-model.md (title, description, category indexed, isActive, createdBy, timestamps)
- [ ] T031 [P] [US4] Create SubjectBundle schema — `src/subjects/schemas/subject-bundle.schema.ts` with fields per data-model.md (name, subjects ref array min:1, isActive, timestamps)
- [ ] T032 [P] [US4] Create Exam schema with embedded Question sub-schema — `src/exams/schemas/exam.schema.ts` and `src/exams/schemas/question.schema.ts` per data-model.md (questions embedded, hasFreeSection, freeQuestionCount, freeAttemptLimit, isActive)
- [ ] T033 [P] [US4] Create MediaAsset schema — `src/media/schemas/media-asset.schema.ts` per data-model.md (gridFsFileId, subjectId indexed, filename, contentType, fileSize, mediaType enum, title, order, uploadedBy)

### Subjects Module

- [ ] T034 [US4] Create Subjects DTOs — `src/subjects/dto/create-subject.dto.ts`, `src/subjects/dto/update-subject.dto.ts`, `src/subjects/dto/create-bundle.dto.ts`, `src/subjects/dto/update-bundle.dto.ts`, `src/subjects/dto/list-subjects-query.dto.ts`
- [ ] T035 [US4] Create Subjects service — `src/subjects/subjects.service.ts` with CRUD for subjects (create, findAll paginated+filtered by category, findById, update, soft-delete) and bundles (create, findAll, update, delete). Validate bundle subjects exist.
- [ ] T036 [US4] Create Subjects controller — `src/subjects/subjects.controller.ts` with `POST /api/v1/subjects` (@Roles admin,teacher), `GET /api/v1/subjects` (all roles), `PUT /api/v1/subjects/:id` (@Roles admin,teacher), `DELETE /api/v1/subjects/:id` (@Roles admin), `POST /api/v1/subject-bundles` (@Roles admin), `GET /api/v1/subject-bundles` (@Roles admin), `PUT /api/v1/subject-bundles/:id` (@Roles admin), `DELETE /api/v1/subject-bundles/:id` (@Roles admin)
- [ ] T037 [US4] Create Subjects module — `src/subjects/subjects.module.ts` registering Subject + SubjectBundle schemas, exporting SubjectsService

### Exams Module

- [ ] T038 [US4] Create Exams DTOs — `src/exams/dto/create-exam.dto.ts` (with nested question DTOs), `src/exams/dto/update-exam.dto.ts`, `src/exams/dto/list-exams-query.dto.ts`
- [ ] T039 [US4] Create Exams service — `src/exams/exams.service.ts` with CRUD (create with embedded questions, findAll by subject, findById, update, soft-delete). Validate correctOption exists in options for each question.
- [ ] T040 [US4] Create Exams controller — `src/exams/exams.controller.ts` with `POST /api/v1/exams` (@Roles admin,teacher), `GET /api/v1/exams/:id`, `PUT /api/v1/exams/:id` (@Roles admin,teacher), `DELETE /api/v1/exams/:id` (@Roles admin)
- [ ] T041 [US4] Create Exams module — `src/exams/exams.module.ts` registering Exam schema, exporting ExamsService

### Media Module

- [ ] T042 [US4] Create Media service — `src/media/media.service.ts` with GridFSBucket operations: `upload()` using busboy for streaming multipart (1MB chunk for video, default for images), `streamFile()` with byte-range support (`openDownloadStream` with start/end, end+1 for exclusive), `deleteFile()` removing both MediaAsset and GridFS data. Access GridFSBucket via `@InjectConnection()` → `this.connection.db`.
- [ ] T043 [US4] Create Media controller — `src/media/media.controller.ts` with `POST /api/v1/media/upload` (@Roles admin,teacher, multipart streaming via busboy), `GET /api/v1/media/:id/stream` (byte-range with 206/200, `@Res({ passthrough: false })`), `DELETE /api/v1/media/:id` (@Roles admin), `GET /api/v1/subjects/:id/media` (list media for subject)
- [ ] T044 [US4] Create Media DTOs — `src/media/dto/upload-media.dto.ts` (subjectId, mediaType, title), `src/media/dto/media-response.dto.ts`
- [ ] T045 [US4] Create Media module — `src/media/media.module.ts` registering MediaAsset schema, exporting MediaService

**Checkpoint**: Admin can create subjects, bundles, exams with questions, upload videos and images. Content management is fully functional.

---

## Phase 4: User Story 1 — Admin Generates and Distributes Subject Activation Codes (Priority: P1)

**Goal**: Admin generates bulk activation codes for subjects/bundles and exams, exports as CSV/XLSX, manages code status.

**Independent Test**: Generate 500 codes for a subject, export as CSV, verify uniqueness and metadata. Revoke a code, verify status change.

### Schemas

- [ ] T046 [P] [US1] Create SubjectCode schema — `src/activation-codes/schemas/subject-code.schema.ts` per data-model.md (code unique+indexed, subjectId, bundleId, status enum, batchId indexed, activatedBy, activatedAt, activationDeviceId, timestamps). Include compound indexes `{ subjectId:1, status:1 }`, `{ bundleId:1, status:1 }`.
- [ ] T047 [P] [US1] Create ExamCode schema — `src/activation-codes/schemas/exam-code.schema.ts` per data-model.md (code unique, examId indexed, usageType enum, maxUses, remainingUses, timeLimitMinutes, firstActivatedAt, status, batchId, activatedBy, activationDeviceId). Include compound indexes.

### Code Generation & Management

- [ ] T048 [US1] Create code generation utility — `src/activation-codes/utils/code-generator.ts` implementing: 32-char charset (`ABCDEFGHJKLMNPQRSTUVWXYZ23456789`), 12-char codes via `crypto.randomBytes()`, `mod 32` for zero-bias selection, display formatting as `XXXX-XXXX-XXXX`, batch generation with local Set dedup.
- [ ] T049 [US1] Create ActivationCodes DTOs — `src/activation-codes/dto/generate-subject-codes.dto.ts` (subjectId XOR bundleId, quantity), `src/activation-codes/dto/generate-exam-codes.dto.ts` (examId, quantity, usageType, maxUses, timeLimitMinutes), `src/activation-codes/dto/list-codes-query.dto.ts` (status filter, pagination), `src/activation-codes/dto/batch-export-query.dto.ts` (format: csv|xlsx)
- [ ] T050 [US1] Create ActivationCodes service (generation) — `src/activation-codes/activation-codes.service.ts` with `generateSubjectCodes()` and `generateExamCodes()`: generate unique codes locally, `insertMany({ ordered: false })`, retry collisions only, return batchId + count. Also `findByBatch()` (paginated, filtered by status), `revokeCode()` (set status to expired), `revokeBatch()` (bulk update all available codes in batch to expired).
- [ ] T051 [US1] Create export functionality — add `exportBatch()` to `src/activation-codes/activation-codes.service.ts` using `exceljs` `WorkbookWriter` for XLSX (stream to response, constant memory) and `@fast-csv/format` for CSV. Columns: code (formatted XXXX-XXXX-XXXX), linked entity name, status, generation date.
- [ ] T052 [US1] Create ActivationCodes controller (admin endpoints) — `src/activation-codes/activation-codes.controller.ts` with `POST /api/v1/activation-codes/subject/generate` (@Roles admin), `POST /api/v1/activation-codes/exam/generate` (@Roles admin), `GET /api/v1/activation-codes/batch/:batchId` (@Roles admin), `POST /api/v1/activation-codes/batch/:batchId/export` (@Roles admin, query format=csv|xlsx), `PATCH /api/v1/activation-codes/:id/revoke` (@Roles admin), `PATCH /api/v1/activation-codes/batch/:batchId/revoke` (@Roles admin)
- [ ] T053 [US1] Create ActivationCodes module — `src/activation-codes/activation-codes.module.ts` registering SubjectCode + ExamCode schemas, importing SubjectsModule + ExamsModule, exporting ActivationCodesService

**Checkpoint**: Admin can generate, list, export, and revoke activation codes for both subjects and exams. SC-001 (1000 codes + export in 30s) and SC-009 (accurate exports, zero duplicates) are achievable.

---

## Phase 5: User Story 2 — Student Activates a Subject Code and Accesses Course Content (Priority: P1)

**Goal**: Student enters a subject activation code, gains permanent access to the linked subject(s), and streams video content with byte-range seeking.

**Independent Test**: Register student, activate a subject code, verify access granted, stream a video with Range header, verify seeking works. Try invalid/used/wrong-device codes — all rejected.

### Rate Limiting

- [ ] T054 [US2] Create ActivationRateLimit schema — `src/activation-codes/schemas/activation-rate-limit.schema.ts` per data-model.md (key unique `activation:{userId}:{hardwareId}`, attempts, windowStart, expiresAt TTL). Include TTL index.
- [ ] T055 [US2] Create ActivationThrottlerGuard — `src/common/guards/activation-throttler.guard.ts` checking ActivationRateLimit collection: if attempts >= 5 within 15min window, throw 429 with remaining cooldown. Increment on each activation attempt. Auto-cleanup via TTL.

### Activation & Access

- [ ] T056 [US2] Implement subject code activation — add `activateCode()` to `src/activation-codes/activation-codes.service.ts`: lookup code (reject if not found / already used / expired), validate device matches student's registered device, mark code as `used` with student + device + timestamp, resolve linked subject or bundle subjects. For bundles: grant all subjects (overlapping subjects retain existing access per edge case).
- [ ] T057 [US2] Create subject access helper — `src/activation-codes/helpers/access-check.helper.ts` or method in ActivationCodesService: `hasSubjectAccess(studentId, subjectId): boolean` querying SubjectCode where `activatedBy = studentId AND status = used AND (subjectId = X OR bundleId resolves to include X)`.
- [ ] T058 [US2] Add access control to media streaming — update `src/media/media.controller.ts` `GET /api/v1/media/:id/stream`: before streaming, verify the requesting student has an activated subject code for the media's subject (call access helper). Return 403 if no access.
- [ ] T059 [US2] Wire activation endpoint — add `POST /api/v1/activation-codes/activate` (@Roles student) to `src/activation-codes/activation-codes.controller.ts` with ActivationThrottlerGuard. Rate limited: 5 attempts per 15 minutes per student/device.

**Checkpoint**: Students can activate subject codes and stream authorized content. SC-002 (activate + access in 10s), SC-003 (seek within 2s), SC-004 (100% device mismatch blocked) are achievable.

---

## Phase 6: User Story 3 — Student Activates an Exam Code and Takes an MCQ Assessment (Priority: P1)

**Goal**: Student activates exam codes (single/multi/time-limited), takes MCQ exams with per-question timers, submits results (online or offline with HMAC tamper detection).

**Independent Test**: Activate single-use exam code, take exam, submit, verify score. Activate multi-use code, verify decrement. Activate time-limited code, verify expiry. Submit offline with valid HMAC — accepted. Submit with tampered HMAC — rejected and flagged.

### Exam Activation

- [ ] T060 [US3] Implement exam code activation — add to `src/activation-codes/activation-codes.service.ts`: `activateExamCode()` handling single-use (consume entirely), multi-use (decrement remainingUses, mark used when 0), time-limited (set firstActivatedAt on first use, check `now < firstActivatedAt + timeLimitMinutes` on subsequent). Same device validation as subject codes.
- [ ] T061 [US3] Create exam access helper — add `hasExamAccess(studentId, examId): boolean` to ActivationCodesService checking ExamCode where `activatedBy = studentId AND status != expired` and time-limit not elapsed.

### Exam Engine

- [ ] T062 [US3] Create ExamAttempt schema — `src/exams/schemas/exam-attempt.schema.ts` per data-model.md (examId, studentId, answers array, score, totalQuestions, correctCount, isFreeAttempt, isOffline, hmacSignature, tamperDetected, startedAt, submittedAt, timestamps). Include compound indexes.
- [ ] T063 [US3] Create Exam submission DTOs — `src/exams/dto/submit-exam.dto.ts` (answers array with questionId+selectedOption+answeredAt, startedAt, submittedAt, isOffline, hmacSignature), `src/exams/dto/exam-result.dto.ts` (attemptId, score, correctCount, totalQuestions, tamperDetected)
- [ ] T064 [US3] Implement exam questions endpoint — add `GET /api/v1/exams/:id/questions` (@Roles student) to `src/exams/exams.controller.ts`: verify exam access (code or free attempts), return questions WITHOUT correctOption field. Include `hmacKey` (per-exam derived key) only when `?offline=true` query param.
- [ ] T065 [US3] Implement HMAC key derivation — `src/exams/utils/hmac.ts` with `deriveExamKey(globalSecret, examId)` using `HMAC(secret, examId)`, `signSubmission(key, canonicalPayload)` producing HMAC-SHA256, `verifySubmission(key, payload, signature)` using `crypto.timingSafeEqual()`. Canonical form: sorted keys, answers sorted by questionId.
- [ ] T066 [US3] Implement exam submission + scoring — add `POST /api/v1/exams/:id/submit` (@Roles student) to `src/exams/exams.controller.ts` + `submitExam()` in `src/exams/exams.service.ts`: verify access, compare answers to correct options, compute score, create ExamAttempt. For offline: verify HMAC, set `tamperDetected = true` and flag account if mismatch. For time-limited exams in progress when window expires: allow current submission (edge case).
- [ ] T067 [US3] Implement attempt history — add `GET /api/v1/exams/:examId/attempts` (@Roles student) to `src/exams/exams.controller.ts`, returning student's own attempts sorted by date.

**Checkpoint**: Full exam lifecycle works — code activation, question delivery, submission, scoring, offline sync with tamper detection. SC-006 (offline sync in 30s, 100% tamper rejection) is achievable.

---

## Phase 7: User Story 8 — Device Locking and Anti-Piracy Protection (Priority: P2)

**Goal**: System captures device hardware ID on registration, restricts access to that device, detects and responds to security flags (screen recording, root/jailbreak).

**Independent Test**: Register on Device A, attempt login from Device B — rejected. Report a security flag — session terminated, flag logged. Admin reviews and takes action.

- [ ] T068 [US8] Create SecurityFlag schema — `src/security/schemas/security-flag.schema.ts` per data-model.md (studentId indexed, flagType enum, deviceId, actionTaken enum, metadata, reviewedBy, reviewedAt, timestamps). Include indexes `{ studentId:1, createdAt:-1 }`, `{ flagType:1 }`.
- [ ] T069 [US8] Create Security DTOs — `src/security/dto/report-flag.dto.ts` (flagType enum, metadata object), `src/security/dto/review-flag.dto.ts` (actionTaken enum), `src/security/dto/list-flags-query.dto.ts` (studentId, flagType, reviewed, pagination)
- [ ] T070 [US8] Create Security service — `src/security/security.service.ts` with `reportFlag()` (create SecurityFlag with actionTaken=session_terminated, delete all active sessions for that student to force re-auth), `listFlags()` (paginated, filtered), `reviewFlag()` (mark reviewed by admin, apply action like account_suspended). Import and use Auth session deletion.
- [ ] T071 [US8] Create Security controller — `src/security/security.controller.ts` with `POST /api/v1/security/report-flag` (@Roles student), `GET /api/v1/security/flags` (@Roles admin), `PATCH /api/v1/security/flags/:id/review` (@Roles admin)
- [ ] T072 [US8] Create Security module — `src/security/security.module.ts` registering SecurityFlag schema, importing AuthModule + UsersModule
- [ ] T073 [US8] Harden device validation in auth flow — update `src/auth/auth.service.ts` `login()`: if user already has a registered device and incoming `hardwareId` differs, reject with 403 (device mismatch). Ensure `register()` creates the device record. Verify `PATCH /api/v1/users/:id/device-reset` in UsersController calls DevicesService.resetDevice() correctly.

**Checkpoint**: Device lock enforced on every auth flow. Security flags trigger immediate session termination. Admin can review and escalate. SC-004 (100% non-registered device blocked) is achieved.

---

## Phase 8: User Story 5 — Real-Time Chat Between Students and Teachers (Priority: P2)

**Goal**: Real-time 1:1 chat via Socket.io with message status indicators (Sent/Delivered/Read), image sharing, offline message delivery, subject-gated authorization.

**Independent Test**: Student sends message to teacher of activated subject — delivered in real-time with status progression. Share an image. Go offline, receive pending messages on reconnect.

### Schemas

- [ ] T074 [P] [US5] Create Conversation schema — `src/chat/schemas/conversation.schema.ts` per data-model.md (participants array of 2, roomId unique deterministic, lastMessageAt, timestamps). Indexes: `{ roomId:1 }` unique, `{ participants:1 }`, `{ lastMessageAt:-1 }`.
- [ ] T075 [P] [US5] Create Message schema — `src/chat/schemas/message.schema.ts` per data-model.md (conversationId indexed, senderId, recipientId indexed, messageType enum, text, imageFileId, status enum, timestamps). Indexes: `{ conversationId:1, createdAt:1 }`, `{ recipientId:1, status:1 }`.

### Chat Infrastructure

- [ ] T076 [US5] Create WsJwtGuard — `src/common/guards/ws-jwt.guard.ts` validating JWT from `client.handshake.auth.token`, verifying session exists, attaching user to `client.data.user`. Disconnect with error on failure.
- [ ] T077 [US5] Create Chat service — `src/chat/chat.service.ts` with `findOrCreateConversation()` (deterministic roomId from sorted participant IDs), `saveMessage()` (persist with status=sent, update conversation lastMessageAt), `updateMessageStatus()` (sent→delivered, delivered/sent→read), `getPendingMessages()` (recipientId + status=sent for offline delivery), `markConversationRead()` (bulk update messages in conversation), `getConversations()` (list user's conversations sorted by lastMessageAt).
- [ ] T078 [US5] Implement subject-gated chat authorization — add `canChat(studentId, teacherId): boolean` to `src/chat/chat.service.ts` or `src/activation-codes/helpers/access-check.helper.ts`: verify teacher has at least one `assignedSubject` that the student has an activated SubjectCode for.
- [ ] T079 [US5] Create Chat gateway — `src/chat/chat.gateway.ts` (@WebSocketGateway namespace '/chat') with:
  - `handleConnection()`: verify JWT, validate session, join all user conversation rooms, flush pending messages, track online status in memory Map
  - `handleDisconnect()`: remove from online map
  - `@SubscribeMessage('send_message')`: validate subject-gated auth, save message, emit `message_ack` to sender, emit `new_message` to recipient room if online
  - `@SubscribeMessage('delivery_ack')`: update status to delivered, emit `status_update` to sender
  - `@SubscribeMessage('mark_read')`: bulk update to read, emit `status_update` to sender
  - `@SubscribeMessage('typing')`: broadcast `typing_indicator` to room
- [ ] T080 [US5] Create chat image upload endpoint — add `POST /api/v1/media/chat/upload` (@Roles student,teacher) to `src/media/media.controller.ts` storing in `chatFiles` GridFS bucket (256KB default chunk), returning `{ fileId, contentType, fileSize }`.
- [ ] T081 [US5] Create Chat module — `src/chat/chat.module.ts` registering Conversation + Message schemas, importing AuthModule + ActivationCodesModule (for subject-gated check)

**Checkpoint**: Real-time chat fully functional with status indicators, image sharing, offline delivery, and subject-gated access. SC-005 (delivery within 1s, accurate status) is achievable.

---

## Phase 9: User Story 6 — Student Performance Analytics (Priority: P2)

**Goal**: Aggregated analytics for students (exam performance, video watch-time, activated content) viewable by admins, teachers, and students themselves.

**Independent Test**: Student completes exams and watches videos. Admin views student analytics — all data accurate. Student views own dashboard — matches.

- [ ] T082 [US6] Create WatchTime schema — `src/analytics/schemas/watch-time.schema.ts` per data-model.md (studentId indexed, mediaAssetId, subjectId denormalized, durationSeconds, recordedAt). Indexes: `{ studentId:1, subjectId:1 }`, `{ studentId:1, mediaAssetId:1 }`.
- [ ] T083 [US6] Create watch-time tracking endpoint — add `POST /api/v1/watch-time` (@Roles student) to a new controller or `src/analytics/analytics.controller.ts`. DTO: `{ mediaAssetId, durationSeconds }`. Service looks up MediaAsset to get subjectId, creates WatchTime record. Validate student has subject access.
- [ ] T084 [US6] Create Analytics service — `src/analytics/analytics.service.ts` with MongoDB aggregation pipelines:
  - `getStudentAnalytics(studentId)`: aggregate exam attempts (group by examId → bestScore, avgScore, attempt count), aggregate watch-time (group by subjectId → totalSeconds), query activated subjects/exams from activation codes
  - `getPlatformAnalytics()`: count active students (sessions with recent activity), total students, code usage stats (totalGenerated, totalActivated, by subject, by date), ongoing exam sessions
- [ ] T085 [US6] Create Analytics DTOs — `src/analytics/dto/student-analytics.dto.ts`, `src/analytics/dto/platform-analytics.dto.ts`
- [ ] T086 [US6] Create Analytics controller — `src/analytics/analytics.controller.ts` with `GET /api/v1/analytics/students/:studentId` (@Roles admin,teacher), `GET /api/v1/analytics/me` (@Roles student), `GET /api/v1/analytics/platform` (@Roles admin)
- [ ] T087 [US6] Create Analytics module — `src/analytics/analytics.module.ts` registering WatchTime schema, importing ExamsModule + ActivationCodesModule + MediaModule

**Checkpoint**: Analytics dashboards deliver accurate student and platform data. SC-008 (accurate within 5min) is achievable.

---

## Phase 10: User Story 7 — Admin Monitors Platform Activity in Real Time (Priority: P2)

**Goal**: Admin dashboard showing active students, ongoing exams, recent activations, and security flags — refreshed every 10 seconds by client polling.

**Independent Test**: Multiple students active, taking exams, activating codes — admin dashboard reflects all activity accurately.

- [ ] T088 [US7] Create Admin service — `src/admin/admin.service.ts` with `getDashboard()`: count active sessions (isActive=true, not expired), count ongoing exam attempts (startedAt within recent window, no submittedAt), query recent activations (last N subject/exam code activations with student info), query unreviewed security flags. All queries optimized with existing indexes.
- [ ] T089 [US7] Create Admin controller — `src/admin/admin.controller.ts` with `GET /api/v1/admin/dashboard` (@Roles admin) returning `{ activeStudentsNow, ongoingExams, recentActivations[], securityFlags[] }` per rest-api.md contract.
- [ ] T090 [US7] Create Admin module — `src/admin/admin.module.ts` importing AuthModule (sessions), ExamsModule (attempts), ActivationCodesModule (recent activations), SecurityModule (flags)

**Checkpoint**: Admin monitoring dashboard operational. SC-010 (data refreshed every 10s) is achievable via client polling.

---

## Phase 11: User Story 9 — Free Exam Sections with Limited Attempts (Priority: P3)

**Goal**: Some exams offer free sections (subset of questions) with configurable per-student attempt limits, accessible without an activation code.

**Independent Test**: Student without exam code accesses free section, uses all attempts, system blocks further access. Activate a code — full exam now available.

- [ ] T091 [US9] Implement free section access logic — update `src/exams/exams.service.ts`: add `canAccessFreeSection(studentId, examId): { allowed: boolean, remainingAttempts: number }` checking `ExamAttempt.countDocuments({ examId, studentId, isFreeAttempt: true })` against `exam.freeAttemptLimit`.
- [ ] T092 [US9] Update exam questions endpoint for free sections — modify `GET /api/v1/exams/:id/questions` in `src/exams/exams.controller.ts`: if student has no exam code but exam `hasFreeSection=true` and free attempts remain, return only the first `freeQuestionCount` questions. If attempts exhausted, return 403 prompting code activation.
- [ ] T093 [US9] Update exam submission for free attempts — modify `POST /api/v1/exams/:id/submit` in `src/exams/exams.service.ts`: if no exam code, validate free section access, set `isFreeAttempt=true` on the ExamAttempt, score only the free questions.

**Checkpoint**: Free exam sections enforce attempt limits with 100% accuracy. SC-011 verified.

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Final integration, documentation, and hardening

- [ ] T094 [P] Complete Swagger decorators — add `@ApiTags`, `@ApiOperation`, `@ApiResponse`, `@ApiBearerAuth` to all controllers across all modules for comprehensive interactive documentation (FR-022)
- [ ] T095 [P] Create admin seed script — `src/scripts/seed-admin.ts` creating an admin user with hashed password, callable via `npm run seed:admin` (add to package.json scripts)
- [ ] T096 Wire AppModule with all feature modules — update `src/app.module.ts` to import all 11 modules: AuthModule, UsersModule, DevicesModule, SubjectsModule, ExamsModule, ActivationCodesModule, MediaModule, ChatModule, AnalyticsModule, SecurityModule, AdminModule
- [ ] T097 Validate quickstart.md workflow — run through the complete quickstart: project setup, env config, start server, create admin, create subject, generate codes, activate code, stream video, take exam, send chat message. Fix any issues found.
- [ ] T098 [P] Add Dockerfile and docker-compose.yml — create per quickstart.md Docker section at repository root

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1: Setup ──────────────────────── No dependencies
    │
    ▼
Phase 2: Foundational ──────────────── Depends on Setup; BLOCKS all user stories
    │
    ├──▶ Phase 3: US4 Content Mgmt ── First US, no dependencies on other stories
    │        │
    │        ├──▶ Phase 4: US1 Code Gen ── Needs subjects/exams from US4
    │        │        │
    │        │        ├──▶ Phase 5: US2 Subject Activation ── Needs codes from US1
    │        │        │
    │        │        └──▶ Phase 6: US3 Exam Activation ── Needs codes from US1
    │        │
    │        └──▶ Phase 8: US5 Chat ── Needs subjects (for gating)
    │
    ├──▶ Phase 7: US8 Security ─────── Only needs auth foundation
    │
    ├──▶ Phase 9: US6 Analytics ────── Needs exams + codes + media (Phase 3-6)
    │
    ├──▶ Phase 10: US7 Admin Monitor ─ Needs all data modules (Phase 3-8)
    │
    └──▶ Phase 11: US9 Free Exams ──── Needs exam engine (Phase 6)

Phase 12: Polish ────────────────────── After all desired phases complete
```

### Critical Path (minimum to MVP)

```
Setup → Foundation → US4 → US1 → US2 + US3 (parallel) → Polish
```

This delivers all P1 stories: content management, code generation, subject activation with streaming, and exam engine.

### Parallel Opportunities

| Can run in parallel | Condition |
|---|---|
| T003 + T004 | Both Setup, different files |
| T006 + T007 + T008 + T009 + T010 | All common/ utilities, independent files |
| T030 + T031 + T032 + T033 | All US4 schemas, independent files |
| T046 + T047 | Both US1 schemas, independent files |
| T074 + T075 | Both US5 schemas, independent files |
| Phase 5 (US2) + Phase 6 (US3) | After Phase 4 (US1), independent stories |
| Phase 7 (US8) | After Foundation, independent of content phases |
| Phase 8 (US5) | After Phase 3 (US4), independent of code phases |
| T094 + T095 + T098 | All Polish, independent files |

### Within Each Phase

- Schemas before services (services depend on model injection)
- Services before controllers (controllers depend on service methods)
- DTOs can be created alongside or before their consuming controller
- Module file last (wires everything together)

---

## Task Count Summary

| Phase | Tasks | Cumulative |
|---|---|---|
| Phase 1: Setup | 4 | 4 |
| Phase 2: Foundation | 25 | 29 |
| Phase 3: US4 Content | 16 | 45 |
| Phase 4: US1 Codes | 8 | 53 |
| Phase 5: US2 Activation | 6 | 59 |
| Phase 6: US3 Exams | 8 | 67 |
| Phase 7: US8 Security | 6 | 73 |
| Phase 8: US5 Chat | 8 | 81 |
| Phase 9: US6 Analytics | 6 | 87 |
| Phase 10: US7 Monitoring | 3 | 90 |
| Phase 11: US9 Free Exams | 3 | 93 |
| Phase 12: Polish | 5 | 98 |
| **Total** | **98** | |
