# REST API Contracts: NA-Academy Backend Platform

**Date**: 2026-04-17  
**Base URL**: `/api/v1`  
**Auth**: JWT Bearer token in `Authorization` header (unless marked `@Public`)  
**Content-Type**: `application/json` (unless multipart)

---

## Auth Module

### POST /api/v1/auth/register `@Public`

Register a new student account.

**Request Body**:
```json
{
  "email": "student@example.com",
  "password": "securePass123",
  "name": "Ahmed Hassan",
  "hardwareId": "device-fingerprint-string"
}
```

**Response 201**:
```json
{
  "accessToken": "eyJhbG...",
  "refreshToken": "a1b2c3d4...",
  "user": { "id": "...", "email": "...", "name": "...", "role": "student" }
}
```

**Errors**: 409 (email exists), 400 (validation)

---

### POST /api/v1/auth/login `@Public`

**Request Body**:
```json
{
  "email": "student@example.com",
  "password": "securePass123",
  "hardwareId": "device-fingerprint-string"
}
```

**Response 200**: Same as register response.

**Behavior**: Invalidates any existing session for this user before creating a new one. Rejects login if `hardwareId` does not match registered device (unless first login).

**Errors**: 401 (invalid credentials), 403 (device mismatch), 403 (account suspended/banned)

---

### POST /api/v1/auth/refresh `@Public`

**Request Body**:
```json
{
  "refreshToken": "a1b2c3d4..."
}
```

**Response 200**:
```json
{
  "accessToken": "eyJhbG...",
  "refreshToken": "newRefreshToken..."
}
```

**Errors**: 401 (invalid/expired refresh token)

---

### POST /api/v1/auth/logout

**Response 200**: `{ "message": "Logged out" }`

**Behavior**: Deletes the current session from MongoDB.

---

## Users Module

### GET /api/v1/users `@Roles(admin)`

List users with pagination and filtering.

**Query**: `?page=1&limit=20&role=student&status=active&search=ahmed`

**Response 200**:
```json
{
  "data": [{ "id": "...", "email": "...", "name": "...", "role": "student", "status": "active" }],
  "total": 150,
  "page": 1,
  "limit": 20
}
```

---

### PATCH /api/v1/users/:id/status `@Roles(admin)`

Suspend or reactivate a user account.

**Request Body**: `{ "status": "suspended" | "active" | "banned" }`

**Response 200**: Updated user object.

---

### PATCH /api/v1/users/:id/device-reset `@Roles(admin)`

Reset a student's device lock, allowing re-registration on next login.

**Response 200**: `{ "message": "Device lock reset" }`

---

## Subjects Module

### GET /api/v1/subjects

List all active subjects. Students see only subjects they have access to or can preview.

**Query**: `?category=Mathematics&page=1&limit=20`

---

### POST /api/v1/subjects `@Roles(admin, teacher)`

**Request Body**:
```json
{
  "title": "Algebra I",
  "description": "Introduction to algebraic concepts",
  "category": "Mathematics"
}
```

**Response 201**: Created subject object.

---

### PUT /api/v1/subjects/:id `@Roles(admin, teacher)`

Update subject details.

---

### DELETE /api/v1/subjects/:id `@Roles(admin)`

Soft-delete a subject (sets `isActive: false`).

---

### GET /api/v1/subjects/:id/media

List media assets for a subject. **Requires active subject code**.

---

## Subject Bundles Module

### POST /api/v1/subject-bundles `@Roles(admin)`

**Request Body**:
```json
{
  "name": "Science Bundle",
  "subjectIds": ["subjectId1", "subjectId2", "subjectId3"]
}
```

---

### GET /api/v1/subject-bundles `@Roles(admin)`

### PUT /api/v1/subject-bundles/:id `@Roles(admin)`

### DELETE /api/v1/subject-bundles/:id `@Roles(admin)`

---

## Exams Module

### POST /api/v1/exams `@Roles(admin, teacher)`

**Request Body**:
```json
{
  "title": "Algebra Midterm",
  "subjectId": "...",
  "hasFreeSection": true,
  "freeQuestionCount": 5,
  "freeAttemptLimit": 3,
  "questions": [
    {
      "text": "Solve for x: 2x + 3 = 7",
      "options": [
        { "label": "A", "text": "x = 1" },
        { "label": "B", "text": "x = 2" },
        { "label": "C", "text": "x = 3" },
        { "label": "D", "text": "x = 4" }
      ],
      "correctOption": "B",
      "timeLimitSeconds": 60,
      "order": 1
    }
  ]
}
```

---

### GET /api/v1/exams/:id

Get exam details (questions without correct answers for students).

---

### GET /api/v1/exams/:id/questions `@Roles(student)`

Get exam questions for taking. **Requires active exam code or free attempts remaining**. Correct answers are excluded.

**Response 200**:
```json
{
  "examId": "...",
  "title": "Algebra Midterm",
  "questions": [
    { "id": "q1", "text": "...", "options": [...], "timeLimitSeconds": 60, "order": 1 }
  ],
  "hmacKey": "per-exam-derived-key"
}
```

The `hmacKey` is included for offline exam signing. Only sent when the student downloads for offline use.

---

### POST /api/v1/exams/:id/submit `@Roles(student)`

**Request Body**:
```json
{
  "answers": [
    { "questionId": "q1", "selectedOption": "B", "answeredAt": "2026-04-17T10:05:00Z" }
  ],
  "startedAt": "2026-04-17T10:00:00Z",
  "submittedAt": "2026-04-17T10:30:00Z",
  "isOffline": false,
  "hmacSignature": null
}
```

**Response 200**:
```json
{
  "attemptId": "...",
  "score": 85,
  "correctCount": 17,
  "totalQuestions": 20,
  "tamperDetected": false
}
```

---

### GET /api/v1/exams/:examId/attempts `@Roles(student)`

Get student's own attempt history for an exam.

---

## Activation Codes Module

### POST /api/v1/activation-codes/subject/generate `@Roles(admin)`

**Request Body**:
```json
{
  "subjectId": "...",
  "bundleId": null,
  "quantity": 500
}
```

Exactly one of `subjectId` or `bundleId` must be provided.

**Response 201**:
```json
{
  "batchId": "batch_20260417_001",
  "count": 500,
  "type": "subject",
  "linkedTo": { "id": "...", "name": "Algebra I" }
}
```

---

### POST /api/v1/activation-codes/exam/generate `@Roles(admin)`

**Request Body**:
```json
{
  "examId": "...",
  "quantity": 200,
  "usageType": "single",
  "maxUses": null,
  "timeLimitMinutes": 1440
}
```

---

### POST /api/v1/activation-codes/activate `@Roles(student)`

**Rate limited**: 5 attempts per 15 minutes per student/device.

**Request Body**:
```json
{
  "code": "KR7NV3PXHM4T"
}
```

**Response 200**:
```json
{
  "type": "subject",
  "activatedSubjects": [{ "id": "...", "title": "Algebra I" }],
  "message": "Subject unlocked successfully"
}
```

**Errors**: 400 (invalid code), 409 (already used), 403 (device mismatch), 410 (expired), 429 (rate limited)

---

### GET /api/v1/activation-codes/batch/:batchId `@Roles(admin)`

List codes in a batch with filtering by status.

**Query**: `?status=available&page=1&limit=50`

---

### POST /api/v1/activation-codes/batch/:batchId/export `@Roles(admin)`

**Query**: `?format=csv` or `?format=xlsx`

**Response**: File download (`Content-Disposition: attachment`).

---

### PATCH /api/v1/activation-codes/:id/revoke `@Roles(admin)`

Revoke a single code (set status to `expired`).

---

### PATCH /api/v1/activation-codes/batch/:batchId/revoke `@Roles(admin)`

Revoke all available codes in a batch.

---

## Media Module

### POST /api/v1/media/upload `@Roles(admin, teacher)`

**Content-Type**: `multipart/form-data`

**Form fields**:
- `file`: Binary file (max 2GB video, 20MB image)
- `subjectId`: String
- `mediaType`: `video` | `image`
- `title`: String (optional)

**Response 201**:
```json
{
  "id": "...",
  "gridFsFileId": "...",
  "filename": "lesson1.mp4",
  "contentType": "video/mp4",
  "fileSize": 524288000,
  "mediaType": "video"
}
```

---

### GET /api/v1/media/:id/stream

Stream media with byte-range support. **Requires active subject code**.

**Request Headers**:
- `Range: bytes=0-1048575` (optional)

**Response 206** (partial):
- `Content-Range: bytes 0-1048575/524288000`
- `Accept-Ranges: bytes`
- `Content-Type: video/mp4`
- Body: binary chunk

**Response 200** (no range header): full file stream.

**Errors**: 403 (no active code for subject), 404 (media not found)

---

### DELETE /api/v1/media/:id `@Roles(admin)`

Delete media asset and GridFS file.

---

## Analytics Module

### GET /api/v1/analytics/students/:studentId `@Roles(admin, teacher)`

**Response 200**:
```json
{
  "student": { "id": "...", "name": "...", "email": "..." },
  "examPerformance": [
    { "examId": "...", "examTitle": "...", "attempts": 3, "bestScore": 95, "avgScore": 88 }
  ],
  "watchTime": [
    { "subjectId": "...", "subjectTitle": "...", "totalSeconds": 7200 }
  ],
  "activatedSubjects": [
    { "subjectId": "...", "title": "...", "activatedAt": "2026-04-10T..." }
  ],
  "activatedExams": [
    { "examId": "...", "title": "...", "activatedAt": "2026-04-12T..." }
  ]
}
```

---

### GET /api/v1/analytics/me `@Roles(student)`

Same structure as above, scoped to the authenticated student.

---

### GET /api/v1/analytics/platform `@Roles(admin)`

**Response 200**:
```json
{
  "activeStudents": 127,
  "totalStudents": 1500,
  "codeUsage": {
    "totalGenerated": 5000,
    "totalActivated": 3200,
    "activationsBySubject": [{ "subjectId": "...", "title": "...", "count": 450 }],
    "activationsByDate": [{ "date": "2026-04-17", "count": 25 }]
  },
  "ongoingExamSessions": 12
}
```

---

## Admin / Monitoring Module

### GET /api/v1/admin/dashboard `@Roles(admin)`

Real-time monitoring data (polled every 10 seconds by client).

**Response 200**:
```json
{
  "activeStudentsNow": 45,
  "ongoingExams": 8,
  "recentActivations": [
    { "code": "KR7N-V3PX-HM4T", "student": "...", "type": "subject", "at": "2026-04-17T10:05:00Z" }
  ],
  "securityFlags": [
    { "studentId": "...", "flagType": "screen_recording", "at": "2026-04-17T10:02:00Z", "reviewed": false }
  ]
}
```

---

## Security Module

### POST /api/v1/security/report-flag `@Roles(student)`

Client reports suspicious activity detected on device.

**Request Body**:
```json
{
  "flagType": "screen_recording",
  "metadata": { "appName": "ScreenRecorder Pro" }
}
```

**Response 200**: `{ "message": "Flag recorded" }`

**Side effect**: Active session is immediately terminated.

---

### GET /api/v1/security/flags `@Roles(admin)`

List all security flags with filtering.

**Query**: `?studentId=...&flagType=screen_recording&reviewed=false&page=1&limit=20`

---

### PATCH /api/v1/security/flags/:id/review `@Roles(admin)`

Mark a flag as reviewed and specify action taken.

**Request Body**:
```json
{
  "actionTaken": "account_suspended"
}
```

---

## Watch Time Tracking

### POST /api/v1/watch-time `@Roles(student)`

Record video watch-time (called periodically by client during playback).

**Request Body**:
```json
{
  "mediaAssetId": "...",
  "durationSeconds": 30
}
```

**Response 200**: `{ "message": "Recorded" }`
