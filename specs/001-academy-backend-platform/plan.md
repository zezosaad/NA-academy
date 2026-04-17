# Implementation Plan: NA-Academy Backend Platform

**Branch**: `001-academy-backend-platform` | **Date**: 2026-04-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/001-academy-backend-platform/spec.md`

## Summary

Build a modular NestJS backend serving an educational platform with MongoDB/Mongoose. The system centers on a dual-layered Activation Code System (Subject Codes for course access, Exam Codes for assessment access), GridFS-based media streaming with byte-range support, an MCQ exam engine with offline sync, real-time Socket.io chat, and comprehensive admin APIs. Security is enforced through device locking (single device + single session per student), HMAC-signed offline submissions, and rate-limited code activation. All APIs documented via Swagger.

## Technical Context

**Language/Version**: TypeScript 5.x / Node.js 20 LTS  
**Framework**: NestJS 10  
**Primary Dependencies**: `@nestjs/mongoose`, `@nestjs/swagger`, `@nestjs/jwt`, `@nestjs/passport`, `@nestjs/websockets`, `@nestjs/platform-socket.io`, `@nestjs/throttler`, `socket.io`, `class-validator`, `class-transformer`, `exceljs`, `@fast-csv/format`, `passport-jwt`, `bcrypt`  
**Storage**: MongoDB 7 with Mongoose ODM; GridFS (via native `GridFSBucket`) for video/image media  
**Testing**: Jest (NestJS default) + Supertest for e2e  
**Target Platform**: Linux server (Docker-ready, Node.js 20 LTS)  
**Project Type**: Web service (REST API + WebSocket gateway)  
**Performance Goals**: 500 concurrent users; API response <200ms p95; video seek <2s; chat delivery <1s  
**Constraints**: Single session per student; device-locked activation; rate-limited code entry (5/15min); GridFS max 2GB video upload; offline exam with HMAC tamper detection  
**Scale/Scope**: 500 concurrent users initial target; 10,000+ codes per batch; horizontal scaling via replica set + Socket.io Redis adapter

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The project constitution (`constitution.md`) contains only template placeholders — no project-specific principles or gates are defined. **All gates pass by default.** No violations to justify.

**Post-Phase 1 re-check**: No new violations introduced. Architecture follows standard NestJS modular patterns.

## Project Structure

### Documentation (this feature)

```text
specs/001-academy-backend-platform/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── rest-api.md      # REST endpoint contracts
│   └── websocket-api.md # WebSocket event contracts
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
src/
├── app.module.ts
├── main.ts
├── config/
│   └── configuration.ts          # env-based config (JWT secret, MongoDB URI, etc.)
├── common/
│   ├── decorators/               # @Roles, @CurrentUser, @Public
│   ├── guards/                   # JwtAuthGuard, RolesGuard, WsJwtGuard, ActivationThrottlerGuard
│   ├── interceptors/             # ResponseTransformInterceptor
│   ├── filters/                  # AllExceptionsFilter
│   ├── pipes/                    # ValidationPipe config
│   └── dto/                      # PaginationDto, ApiResponseDto
├── auth/
│   ├── auth.module.ts
│   ├── auth.controller.ts
│   ├── auth.service.ts
│   ├── strategies/               # jwt.strategy.ts, local.strategy.ts
│   ├── dto/                      # RegisterDto, LoginDto, TokenResponseDto
│   └── schemas/                  # session.schema.ts
├── users/
│   ├── users.module.ts
│   ├── users.controller.ts
│   ├── users.service.ts
│   ├── dto/
│   └── schemas/                  # user.schema.ts
├── subjects/
│   ├── subjects.module.ts
│   ├── subjects.controller.ts
│   ├── subjects.service.ts
│   ├── dto/
│   └── schemas/                  # subject.schema.ts, subject-bundle.schema.ts
├── exams/
│   ├── exams.module.ts
│   ├── exams.controller.ts
│   ├── exams.service.ts
│   ├── dto/
│   └── schemas/                  # exam.schema.ts, question.schema.ts, exam-attempt.schema.ts
├── activation-codes/
│   ├── activation-codes.module.ts
│   ├── activation-codes.controller.ts
│   ├── activation-codes.service.ts # Bulk generation, validation, rate-limit logic
│   ├── dto/
│   └── schemas/                  # subject-code.schema.ts, exam-code.schema.ts
├── media/
│   ├── media.module.ts
│   ├── media.controller.ts       # Upload + byte-range streaming endpoints
│   ├── media.service.ts          # GridFSBucket operations
│   └── dto/
├── chat/
│   ├── chat.module.ts
│   ├── chat.gateway.ts           # Socket.io WebSocket gateway
│   ├── chat.service.ts
│   ├── dto/
│   └── schemas/                  # message.schema.ts, conversation.schema.ts
├── analytics/
│   ├── analytics.module.ts
│   ├── analytics.controller.ts
│   ├── analytics.service.ts      # MongoDB aggregation pipelines
│   └── dto/
├── devices/
│   ├── devices.module.ts
│   ├── devices.service.ts
│   └── schemas/                  # device.schema.ts
├── security/
│   ├── security.module.ts
│   ├── security.controller.ts
│   ├── security.service.ts
│   └── schemas/                  # security-flag.schema.ts
└── admin/
    ├── admin.module.ts
    ├── admin.controller.ts       # Dashboard, monitoring, code management
    └── admin.service.ts

test/
├── e2e/
│   ├── auth.e2e-spec.ts
│   ├── activation-codes.e2e-spec.ts
│   ├── media.e2e-spec.ts
│   └── chat.e2e-spec.ts
└── unit/
    └── [per-service unit tests]
```

**Structure Decision**: Standard NestJS modular architecture with one module per domain concern. Each module is self-contained with its own controller, service, DTOs, and schemas. The `common/` directory holds cross-cutting concerns (guards, decorators, interceptors). No monorepo — single NestJS application with 11 feature modules.

## Complexity Tracking

> No constitution violations to justify — constitution contains only template placeholders.
