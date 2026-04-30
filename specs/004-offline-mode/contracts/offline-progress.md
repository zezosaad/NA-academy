# Contract: Batched Offline Progress Sync

Owns FR-008, FR-009, FR-015, FR-016 — drains the client's `pending_progress_events` queue on reconnect, with idempotent dedup and "further-along wins" merge semantics.

---

## `POST /lesson-progress/batch`

### Request

```ts
// back/src/lesson-progress/dto/batch-progress-events.dto.ts
class BatchProgressEventsDto {
  @ArrayMinSize(1)
  @ArrayMaxSize(100)
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ProgressEventDto)
  events!: ProgressEventDto[];
}

class ProgressEventDto {
  @IsString()
  @Length(20, 32)         // ULID length range; loose to allow either ULID or UUID-style ids
  clientEventId!: string;

  @IsMongoId()
  lessonId!: string;

  @IsMongoId()
  subjectId!: string;

  @IsInt()
  @Min(0)
  watchedSeconds!: number;

  @IsBoolean()
  isCompleted!: boolean;

  @IsISO8601()
  recordedAt!: string;     // wall-clock ISO 8601 from client; informational only — server uses its own time + further-along-wins merge

  @IsString()
  @IsOptional()
  bootId?: string;         // for client diagnostics; server may log but does not gate on it
}
```

### Response

```ts
class BatchProgressEventsResultDto {
  acceptedClientEventIds!: string[];   // events the server merged (or treated as no-op duplicates)
  rejectedClientEventIds!: { clientEventId: string; reason: string }[]; // e.g., unknown lessonId, no access
  serverTimestamp!: string;             // ISO 8601, UTC
}
```

### Auth

- `@ApiBearerAuth()`, `@Roles('student', 'teacher')`.
- The authenticated user owns *all* events in the batch — the server uses `req.user.userId` as the `userId` for the merge; clients MUST NOT and CANNOT specify a `userId` per event.

### Service contract

`LessonProgressService.mergeBatch(userId, events)`:

1. Group by `lessonId`.
2. For each group, **load the existing `LessonProgress` document once**, then iterate the group's events applying:
   - `watchedSeconds = max(existing, ...incoming)`
   - `isCompleted = existing OR any(incoming)`
   - `completedAt = earliest non-null among (existing.completedAt, incoming-events-where-isCompleted-was-newly-set)`
   - `lastWatchedAt = max(existing, ...incoming.recordedAt)`
3. `upsert` the merged document atomically.
4. Maintain a per-user ring buffer of recently-seen `clientEventId`s (in-memory, last 1000 ids per active session, plus a 7-day persisted set) to suppress duplicate-replay warnings.

### Errors

- `400 Bad Request` — DTO validation; invalid ULID; > 100 events.
- `401 Unauthorized` — missing/invalid JWT.
- `403 Forbidden` — admin role rejected.

Per-event rejection (e.g., `lessonId` no longer exists or user lost access) returns `200` with the offending id under `rejectedClientEventIds`. The client deletes those rows from `pending_progress_events` to prevent infinite retry.

### Throttling

Default `@nestjs/throttler` bucket is sufficient. Realistic worst case: cold reconnect after 2 weeks offline → ~5 batches (500 events) within a few seconds, well under standard throttling limits.

### Swagger placement

`@ApiTags('Lesson Progress')`; `@ApiOperation({ summary: 'Ingest a batched set of offline-recorded lesson progress events' })`.

### Client contract (Flutter)

- `OfflineProgressSyncWorker` runs on reconnect and on app resume; reads up to 100 rows from `pending_progress_events`, posts, then deletes accepted rows. Rejected rows are also deleted (since they are unrecoverable on this account).
- Failure modes:
  - Network failure → keep all rows, retry with exponential backoff capped at 5 min.
  - `400` → log, drop the offending events; never retry indefinitely.
  - `401` → trigger silent token refresh; on refresh failure, surface "sign in to sync your progress" banner.

### Sample

```http
POST /lesson-progress/batch
Authorization: Bearer <jwt>
Content-Type: application/json

{
  "events": [
    {
      "clientEventId": "01HZ8B5T2W4...",
      "lessonId": "65a...",
      "subjectId": "65b...",
      "watchedSeconds": 412,
      "isCompleted": false,
      "recordedAt": "2026-04-29T18:11:20Z",
      "bootId": "boot-65f8..."
    }
  ]
}
```

```json
{
  "acceptedClientEventIds": ["01HZ8B5T2W4..."],
  "rejectedClientEventIds": [],
  "serverTimestamp": "2026-04-30T14:22:01.000Z"
}
```
