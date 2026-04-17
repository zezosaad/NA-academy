# Research: NA-Academy Backend Platform

**Date**: 2026-04-17  
**Phase**: 0 — Outline & Research  
**Status**: Complete — all unknowns resolved

---

## R-001: GridFS Video Streaming with Byte-Range Support

**Decision**: Use native MongoDB `GridFSBucket` API (from `mongodb` driver, transitive dependency of Mongoose) — not the deprecated `gridfs-stream` package.

**Rationale**: `gridfs-stream` is unmaintained, incompatible with `mongodb` driver v4+, and relies on the deprecated GridStore API. `GridFSBucket` is the official, supported API with proper streaming support.

**Alternatives considered**:
- `gridfs-stream`: Rejected — deprecated, incompatible with modern drivers
- External object storage (S3/MinIO): Viable for high-scale but adds infrastructure complexity; GridFS adequate for 500 concurrent users
- Filesystem storage: Rejected — no replication, requires separate backup strategy

**Key findings**:
- Access `GridFSBucket` via `this.connection.db` from Mongoose's `@InjectConnection()`
- Increase chunk size to 1MB (default 255KB) for video workloads — reduces chunk documents, improves throughput
- For byte-range: `GridFSBucket.openDownloadStream(id, { start, end })` where `end` is **exclusive** (HTTP Range `end` is inclusive — always `+1`)
- Use `@Res({ passthrough: false })` for streaming endpoints — NestJS `StreamableFile` doesn't support `206` status
- For uploads: use `busboy` for streaming multipart parsing instead of `multer` memory storage (avoids OOM on 2GB files)
- Connection pool: increase `maxPoolSize` in Mongoose options to handle concurrent streaming cursors

---

## R-002: Real-Time Chat Architecture

**Decision**: Gateway + Service + Repository layered pattern. Socket.io for transport, HTTP for file uploads, MongoDB as the message queue (no separate queue system).

**Rationale**: Messages are persisted to MongoDB on send regardless of recipient status. The messages collection **is** the offline queue — simpler than a separate queuing system and inherently durable.

**Alternatives considered**:
- Redis pub/sub as message broker: Useful for multi-instance scaling but adds infrastructure; defer to scaling phase
- Separate message queue (RabbitMQ/Bull): Over-engineered for 1:1 chat at this scale
- Binary file upload via Socket.io: Rejected — unreliable for large payloads, no progress tracking

**Key findings**:
- Authenticate on WebSocket handshake via JWT in `handleConnection`, not per-message
- Use `client.data.user` to attach authenticated user to socket for guards
- Deterministic room IDs: `[userA, userB].sort().join(':')` — join rooms on connect
- Message status flow: `SENT` (on persist) → `DELIVERED` (on forward to online recipient) → `READ` (on conversation open)
- On reconnect: query messages where `recipientId = userId AND status = SENT`, emit as `new_message`
- For multi-instance: add `@socket.io/redis-adapter` later when horizontal scaling is needed

---

## R-003: Authentication, Session Management & RBAC

**Decision**: Two-token strategy (short-lived access JWT 15min + opaque refresh token 7d) with MongoDB session collection for single-session enforcement.

**Rationale**: Access JWT is stateless for fast validation. Session document checked on every request via `sessionId` in JWT payload — small overhead but guarantees instant invalidation when new login occurs.

**Alternatives considered**:
- Single long-lived JWT: Rejected — cannot invalidate without blacklist, single-session enforcement impossible
- Redis session store: Faster lookups but adds infrastructure; MongoDB adequate at this scale
- Session-only (no JWT): Rejected — requires DB lookup on every request without any caching benefit

**Key findings**:
- JWT payload: `{ sub: userId, role, hardwareId, sessionId }`
- Login flow: validate credentials → `deleteMany({ userId })` to kill existing sessions → create new session → issue tokens
- `JwtStrategy.validate()`: check `sessionId` exists in sessions collection (enforces single session)
- Device binding: `hardwareId` stored in both JWT and session document; validated on every request
- RBAC: `@Roles()` decorator with `SetMetadata` + `RolesGuard` reading from reflector
- TTL index on session `expiresAt` for automatic cleanup of expired sessions
- Rate limiting: `@nestjs/throttler` with custom `getTracker` keyed on `userId:hardwareId` for activation endpoint (5 attempts / 15 minutes)

---

## R-004: Bulk Activation Code Generation

**Decision**: 12-character alphanumeric codes using 32-char reduced charset (`ABCDEFGHJKLMNPQRSTUVWXYZ23456789`), formatted as `XXXX-XXXX-XXXX` for display.

**Rationale**: 32^12 ≈ 4.7 × 10^18 combinations — collision probability is effectively zero at 10K–100K batch sizes. Excluding ambiguous characters (0/O, 1/I/L) improves human readability for physical card distribution.

**Alternatives considered**:
- UUID v4: Rejected — too long for physical cards and manual entry
- 8-character codes: Rejected — insufficient entropy at scale (32^8 ≈ 1.1 × 10^12, collision risk grows with total codes)
- Sequential codes: Rejected — guessable, undermines security

**Key findings**:
- Generate with `crypto.randomBytes()` — cryptographically secure, not guessable
- `mod 32` (power of 2) gives zero bias in character selection
- Bulk insert strategy: generate locally-unique Set → `insertMany({ ordered: false })` → retry only collision failures
- MongoDB unique index on `code` field is the authoritative uniqueness guarantee
- Export: `exceljs` for both XLSX and CSV with streaming (`WorkbookWriter` → pipe to response, constant memory)
- For CSV specifically: `@fast-csv/format` as lighter alternative

---

## R-005: Offline Exam Tamper Detection

**Decision**: HMAC-SHA256 signing of canonical exam submission payload. Per-exam derived key from global secret.

**Rationale**: HMAC provides strong integrity verification. Per-exam keys (`HMAC(globalSecret, examId)`) limit blast radius if one key is extracted from an offline bundle.

**Alternatives considered**:
- No signing (trust client): Rejected — trivially tamperable
- Digital signatures (RSA/Ed25519): Stronger but requires key pair management; HMAC sufficient for this threat model
- Server-side re-scoring: Complementary but doesn't prevent timestamp/identity tampering

**Key findings**:
- Sign canonical JSON: sorted keys, sorted answers array by `questionId`
- Payload includes: `visitorId`, `examId`, `answers[]`, `submittedAt` timestamp
- Use `crypto.timingSafeEqual()` for verification to prevent timing attacks
- Key management: `EXAM_HMAC_SECRET` in environment, derive per-exam key as `HMAC(secret, examId)`
- Verification on sync: recompute HMAC, compare; reject and flag account on mismatch
