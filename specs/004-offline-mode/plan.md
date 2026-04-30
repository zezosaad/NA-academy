# Implementation Plan: Offline Mode (Downloaded Videos & Offline App Access)

**Branch**: `004-offline-mode` | **Date**: 2026-04-30 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-offline-mode/spec.md`

## Summary

Bring offline learning to the Flutter `na_app` so students can download specific lesson videos to encrypted, app-private storage and play them with zero network calls, plus open the app cold-start while offline and continue browsing previously-loaded courses, lessons, and progress. On the back end (`back/`), extend the existing `media`, `lesson-progress`, and `devices` modules with: an entitlement-verification endpoint scoped to a downloaded-video set, batched offline-progress ingestion, and a single-active-offline-device handoff that wipes the previous device's downloads on next reconnect (sync-then-wipe). Content protection is consumer-grade: AES-GCM at-rest encryption with an app-managed key wrapped by the platform keystore, no studio-grade DRM, no external license server. Downloaded videos automatically lock after 14 consecutive days without an entitlement check, anchored to a tamper-resistant time source.

## Technical Context

**Language/Version**: Dart 3.11+ / Flutter 3.24+ (`na_app/`); TypeScript on NestJS 11 / Node 20+ (`back/`).
**Primary Dependencies**:
- Flutter (`na_app/`): existing `video_player` + `chewie` for playback, `dio` for HTTP, `flutter_secure_storage` for the wrapping key, `shared_preferences`, `device_info_plus`, `freezed`, `riverpod`. **New**: `path_provider` (app-private dir), `cryptography` (AES-GCM + HKDF) or `pointycastle`, `drift` (or `sqflite`) for the offline-downloads index + pending-progress queue.
- Backend (`back/`): existing NestJS 11, Mongoose, Swagger, `@nestjs/throttler`, `class-validator`. **No new core dependencies** — entitlement check, batched progress ingest, and active-offline-device handoff are added as new endpoints inside existing modules.

**Storage**:
- Server: MongoDB (existing). New collection `offline_active_devices` (single-active-offline-device tracking), additive fields on `Device` schema, no schema-breaking changes.
- Client: app-private filesystem (`getApplicationDocumentsDirectory()`) for ciphertext video files; an embedded SQLite database (drift/sqflite) for the offline-downloads index, the pending-sync queue, and the cached lesson/course snapshot; `flutter_secure_storage` for the key-wrapping key only.

**Testing**: `flutter_test` + `integration_test` for `na_app/`; existing Jest test infrastructure for `back/`.
**Target Platform**: iOS 14+ and Android API 26+ via Flutter `na_app/`. Backend runs unchanged on Node 20+.
**Project Type**: Mobile + API (per constitution structure: `na_app/` mobile + `back/` API).

**Performance Goals**:
- Cold-start (airplane mode, previously-signed-in) → lessons list visible in **< 5 s** (SC-001).
- Downloaded-video playback: **0 network calls** during playback (SC-002).
- Pending offline-progress events sync within **30 s** of reconnection for 95% of events (SC-004).
- 14-day grace lock check on every play attempt: **< 50 ms** added overhead.

**Constraints**:
- All downloaded video files MUST be ciphertext on disk; only the running app can decrypt them via a key wrapped by the platform keystore (Keychain on iOS, Android Keystore on Android).
- 14-day grace MUST NOT be defeatable by setting the device clock backward — anchor to last-server-confirmed timestamp + monotonic uptime delta.
- **Mobile-first** per Principle V; this feature is mobile-only by design (Flutter `na_app/` only). The Expo `front/` and admin dashboard are out of scope for this feature.
- Constitution Principle I: any download UI / offline banner / manage-downloads screen MUST conform to `DESIGN.md` (parchment palette, Fraunces display, Inter body, 12–18px radii, Sage-Teal rarity rule).

**Scale/Scope**: ~25 functional requirements across one mobile surface + one API surface. ~3 new endpoints, ~1 new collection, ~3 new Flutter feature folders (`offline_downloads`, plus extensions to `lessons`, `auth`, `lesson_progress`).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| **I. Scholarly Warmth by Default** | **PASS-WITH-NOTES** | Download / "Available offline" / "Offline — connect to play" / "Manage downloads" / "14-day re-verify needed" UI MUST use parchment palette, Fraunces display, Inter body, pill primary buttons, ≤10% Sage-Teal. Concrete component decisions deferred to `/speckit.tasks` and validated in implementation per Principle I. No vibrant-blue download-progress bars; no grey-on-grey "offline" banners. |
| **II. Spec-Before-Code** | **PASS** | Spec ratified, five clarifications recorded in `spec.md` under `## Clarifications` (session 2026-04-30). No tasks will be opened until this `plan.md` passes Constitution Check. |
| **III. Independent, Priority-Ordered Slices** | **PASS** | Spec defines three priority-ordered stories: P1 = play downloaded video offline; P1 = open app and browse cached content offline (co-essential MVP pair); P2 = manage downloads. Each is independently testable per the spec's acceptance scenarios. Phase-2 task breakdown will preserve this grouping. |
| **IV. Contract-Driven Multi-Surface Consistency** | **PASS-WITH-NOTES** | All new endpoints (entitlement-verify, batched progress, active-offline-device claim/release) MUST be expressed as DTOs with `class-validator` rules and registered with Swagger before any client work. Flutter client consumes only those DTO shapes — no ad-hoc types. See `contracts/` artifacts. **Note**: this feature touches `na_app/` only; the Expo `front/` keeps the existing API behavior unchanged (it does not need to learn the offline endpoints). This is intentional and not a divergence — it's surface scope. |
| **V. Mobile-First, Accessible, Calm** | **PASS** | Feature is mobile-only by design. All controls keep ≥44×44pt touch targets. Offline banners and the manage-downloads list honor `prefers-reduced-motion` and avoid low-contrast grey-on-grey. One-handed reach for the per-lesson Download / Remove control on common phone sizes is part of the UI contract. |

**Outcome**: All five gates pass (two with documented notes). No `Complexity Tracking` entries required. The "Active mobile surface" question (Flutter `na_app/` vs. Expo `front/`) is resolved in Phase 0 / `research.md` — see Decision 1 there.

## Project Structure

### Documentation (this feature)

```text
specs/004-offline-mode/
├── plan.md              # This file
├── spec.md              # Feature specification (already ratified)
├── research.md          # Phase 0 output — resolves cross-feature concerns
├── data-model.md        # Phase 1 output — entities & schemas
├── quickstart.md        # Phase 1 output — how to demo the offline flow end-to-end
├── contracts/           # Phase 1 output — REST/DTO contracts for new endpoints
│   ├── entitlement.md
│   ├── offline-progress.md
│   └── active-offline-device.md
├── checklists/
│   └── requirements.md  # Spec-quality checklist (already passing)
└── tasks.md             # Phase 2 output (NOT created here — created by /speckit.tasks)
```

### Source Code (repository root)

```text
back/
└── src/
    ├── devices/
    │   ├── devices.service.ts            # extended: single-active-offline-device claim/release
    │   ├── devices.controller.ts         # NEW: claim/release/status endpoints (offline-device-only)
    │   ├── dto/                          # NEW: ClaimActiveOfflineDeviceDto, ReleaseDto
    │   └── schemas/
    │       ├── device.schema.ts          # existing — additive fields only
    │       └── offline-active-device.schema.ts  # NEW: tracks current active-offline-device per user
    ├── lesson-progress/
    │   ├── lesson-progress.service.ts    # extended: batched ingest with "further-along wins"
    │   ├── lesson-progress.controller.ts # NEW endpoint: POST /lesson-progress/batch
    │   └── dto/                          # NEW: BatchProgressEventsDto, ProgressEventDto
    └── media/
        ├── media.service.ts              # extended: entitlement-verify (no streaming, just access decision)
        ├── media.controller.ts           # NEW endpoint: POST /media/entitlement/verify
        └── dto/                          # NEW: VerifyEntitlementDto, EntitlementVerificationResultDto

na_app/
└── lib/
    ├── core/
    │   ├── api/
    │   │   └── endpoints.dart            # extended: new offline-mode routes
    │   ├── offline/                      # NEW: shared offline plumbing
    │   │   ├── secure_box.dart           # AES-GCM at-rest encryption, key wrapped by flutter_secure_storage
    │   │   ├── monotonic_clock.dart      # tamper-resistant time source (server time + uptime delta)
    │   │   ├── connectivity_observer.dart
    │   │   └── offline_db.dart           # Drift schema: offline_downloads, pending_progress, cached_snapshot
    │   └── storage/
    │       └── prefs_store.dart          # existing — extended with single-active-offline-device flag
    └── features/
        ├── offline_downloads/            # NEW feature module (User Story 1 + 3)
        │   ├── data/
        │   │   ├── offline_downloads_repository.dart
        │   │   └── offline_video_player.dart       # decrypt-on-play wrapper around video_player
        │   ├── domain/
        │   │   └── offline_download.dart           # freezed model
        │   └── presentation/
        │       ├── controllers/                    # Riverpod controllers: download queue, entitlement
        │       ├── pages/
        │       │   └── manage_downloads_page.dart  # User Story 3
        │       └── widgets/
        │           ├── download_button.dart        # per-lesson control
        │           ├── download_progress_pill.dart
        │           └── offline_lock_banner.dart    # 14-day-expired / not-active-device banner
        ├── lessons/                       # extended: integrate download_button on lesson screen,
        │                                  # integrate offline player when downloaded
        ├── auth/                          # extended: keep signed-in offline; verify on reconnect
        └── home/                          # extended: cached snapshot drives offline cold-start

front/  (Expo flagship)                    # OUT OF SCOPE for v1 of this feature
admin-dashboard/                           # OUT OF SCOPE for this feature
```

**Structure Decision**: Flutter `na_app/` is the implementation surface for the mobile half of this feature, building on the existing `lib/features/` module convention and the existing `lib/core/{api,storage}` plumbing. The new `lib/core/offline/` package houses everything reusable across features (encryption, monotonic clock, offline DB, connectivity); the new `lib/features/offline_downloads/` module owns the user-facing download/management UI. The backend stays inside its existing module boundaries (`devices/`, `media/`, `lesson-progress/`) — no new top-level modules. The Expo `front/` surface is intentionally not touched in v1 (see Decision 1 in `research.md`).

## Complexity Tracking

> No constitution violations. This section is intentionally empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none)    | (n/a)      | (n/a)                                |

## Phase 0 — Outline & Research

See [research.md](./research.md). Key decisions resolved there:

1. **Active mobile surface** — Flutter `na_app/` (not Expo `front/`).
2. **At-rest encryption** — AES-GCM with per-file random IV, content key wrapped by platform-keystore-backed key.
3. **Tamper-resistant time** — server-confirmed timestamp + monotonic uptime delta from `boot_time_ms`.
4. **Single-active-offline-device vs. existing whole-account device lock** — keep the existing `devices` whole-account lock as-is; layer offline-active-device on top, scoped to *which* downloads are valid, not *whether the user can sign in*.
5. **Embedded local DB** — Drift (Dart-friendly, type-safe, supports the offline_downloads index + pending-progress queue + cached snapshot in one schema).
6. **Streaming vs. download URL** — reuse the existing `GET /media/:id/stream` endpoint with `Range` headers for download to avoid duplicating access control; the client just pulls the full byte range and encrypts at rest before writing.

## Phase 1 — Design & Contracts

Generated artifacts:

- [data-model.md](./data-model.md) — entities, schemas, validation rules, state transitions.
- [contracts/entitlement.md](./contracts/entitlement.md) — `POST /media/entitlement/verify` and the device-handoff revocation signal.
- [contracts/offline-progress.md](./contracts/offline-progress.md) — `POST /lesson-progress/batch` for batched offline-progress ingest with "further-along wins" semantics.
- [contracts/active-offline-device.md](./contracts/active-offline-device.md) — `POST /devices/offline/claim`, `POST /devices/offline/release`, `GET /devices/offline/status`.
- [quickstart.md](./quickstart.md) — end-to-end manual demo: enroll → download → airplane-mode play → reconnect → verify sync.

Agent context update: `na_app/` is already the recently-active mobile surface for branch `003-mobile-app-redesign`. The agent context (`CLAUDE.md`) already lists Dart 3.11/Flutter 3.24+ and NestJS 11/Node 20+. The Phase 1 update will add the offline-mode tech additions (Drift, AES-GCM, encrypted-at-rest video files) when `update-agent-context.ps1` is run — see Phase 1 step in the outline.

## Constitution Check (Post-Design Re-Evaluation)

Re-evaluated after generating `research.md`, `data-model.md`, `contracts/`, and `quickstart.md`:

| Principle | Re-Check | Notes |
|---|---|---|
| I — Scholarly Warmth | PASS-WITH-NOTES (unchanged) | UI specifics still belong in `/speckit.tasks`; no design-system divergence introduced by the data model or contracts. |
| II — Spec-Before-Code | PASS | All Phase-0/1 outputs flow from the ratified spec; no scope creep. |
| III — Independent Slices | PASS | Contracts and data model are partitioned to support each priority story independently: entitlement + batched progress + offline player serve P1; cached snapshot + auth offline path serve P1 (story 2); manage-downloads + size accounting serve P2. |
| IV — Contract-Driven | PASS | Three new endpoints fully specified in `contracts/`, each with DTO shape, validation, Swagger placement, and Flutter consumption note. No ad-hoc client types. |
| V — Mobile-First, Accessible, Calm | PASS | Quickstart explicitly demos the cold-start-in-airplane-mode and one-handed download flow on a phone-sized viewport; no desktop-first paths. |

**Outcome**: All gates pass post-design. Ready for `/speckit.tasks`.
