# Quickstart — Offline Mode end-to-end demo

This is a step-by-step manual demo proving the feature works as specified. It maps each step to the user stories (US1, US2, US3) and acceptance scenarios in `spec.md`.

**Audience**: developer or QA validating that the implementation satisfies the spec on a real device.
**Prerequisites**: `back/` running locally, `na_app/` installed on a physical phone (iOS or Android), one student account that is enrolled in at least one course with a video lesson.

---

## Step 0 — Setup

1. `cd back && npm install && npm run start:dev` — bring up the API.
2. `cd na_app && flutter pub get && flutter run -d <device>` — launch the app on a physical phone.
3. Sign in as a student account that has access to at least one video lesson.

**Confirm**: you can play that lesson online via streaming. (Pre-existing functionality.)

---

## Step 1 — Download a video while online (US1, AS1)

1. On the lesson screen, tap the **Download** control next to the video.
2. Watch the in-line progress pill fill (FR-004 visible states).
3. When complete, the lesson now shows an **Available offline** indicator.

**Verify**:
- The download survives killing and re-launching the app (FR-005).
- Inspecting the device file system (`adb shell` on Android, Xcode device window on iOS) shows the downloaded file lives only inside the app sandbox; the file is **ciphertext** (binary noise, not a recognisable MP4).
- The system Files app, Photos, and any other app's "import from files" dialog **do not see** the file (FR-002, FR-003, AS3).

---

## Step 2 — Watch the downloaded video offline (US1, AS2 + AS4)

1. Enable airplane mode (or pull the SIM and disable Wi-Fi).
2. Cold-start the app (force-quit, then tap the icon).
3. Open the same lesson. The **Available offline** indicator should still be present.
4. Tap **Play**. The video plays end-to-end — including pause, resume, seeking, and playback-speed controls — with **no network calls** (FR-007, SC-002).
5. Watch through to the completion threshold.

**Verify**:
- App networking instrumentation (e.g., Charles Proxy with airplane disabled, or `adb logcat` filtering for HTTP) shows zero requests during playback.
- The lesson is now marked **Completed** locally (FR-009), with a small "Will sync when online" affordance.
- A row exists in `pending_progress_events` (Drift inspector or developer-only debug screen).

---

## Step 3 — Open the app cold-start while offline (US2, AS1 + AS2)

1. Still in airplane mode, fully kill the app again.
2. Cold-start it.

**Verify**:
- The app opens to the home/courses screen in **< 5 seconds** (SC-001).
- It does **not** force a sign-out or show a full-screen "no internet" error (FR-010, FR-011, AS1).
- Navigating to the previously-viewed course shows the cached lesson list (FR-020, AS2).
- Opening a lesson whose video was **not** downloaded shows the lesson text (if cached) and a clear "Not downloaded — connect to watch or download" state in the player (AS4).
- Opening **Live chat** shows a contextual offline state, not a crash (FR-012, AS3).
- Opening an **exam** shows a clear offline-blocked state (Edge Cases — exam offline).

---

## Step 4 — Reconnect and observe sync (US1, AS4 + sync FRs)

1. Disable airplane mode.
2. Bring the app to the foreground.

**Verify within 30 seconds** (SC-004):
- The "Will sync when online" affordance disappears.
- The server-side `LessonProgress` document for that lesson reflects the offline progress (`watchedSeconds` advanced; if completed, `isCompleted=true`, `completedAt` set).
- `pending_progress_events` table is now empty.
- An entitlement-verify call has succeeded (server logs); the local `last_verified_at_*` fields are updated.

---

## Step 5 — Manage downloads (US3)

1. Navigate to **Manage downloads** (Profile → Manage downloads, or equivalent).
2. The screen lists each downloaded item with title, course, file size, and download date, plus a total (AS1, FR-017).
3. Tap **Remove** on the item from Step 1.

**Verify**:
- The file is deleted (storage reclaimed, total updates).
- The lesson reverts to streaming-only.
- Total reported matches actual on-device usage within ±5% (SC-005).

---

## Step 6 — Single-active-offline-device handoff (sync-then-wipe)

1. On a **second** device (or simulator), sign in with the **same** account. (If the existing whole-account device lock is enabled, an admin must reset the device for this step. Document this prerequisite in the demo.)
2. On the second device, download a video.
3. Bring the original device online (still backgrounded). Foreground the app.

**Verify**:
- The original device shows a notification: "Your offline downloads moved to <new device>" (FR-012b).
- Any unsynced offline progress on the original device flushes to the server **before** local ciphertext is deleted (FR-012d).
- After the flush, the original device's `offline_downloads` table is empty and the local ciphertext files are gone.
- The server `OfflineActiveDevice` document has `pendingWipe=false`, `previousDeviceId=null`, `deviceId` = the new device.

---

## Step 7 — 14-day grace lock (offline-too-long)

> This is hard to demo on real time; it is included for completeness with a recommended testable shortcut.

1. While online, download a video.
2. Apply a developer override (DEBUG-only menu) that **rewinds** the recorded `last_verified_at_uptime` by `14 * 24 * 3600 * 1000` ms.
3. Enable airplane mode.
4. Try to play the downloaded video.

**Verify**:
- The player blocks playback and shows: "You've been offline for more than 14 days. Reconnect to continue." (FR-013a, SC-009).
- Disabling airplane mode and waiting briefly causes the entitlement-verify call to succeed; the lock clears and playback resumes immediately (SC-009 second half).

A real-time variant (no DEBUG override) is to leave a device offline for 14+ days; it works but is impractical to script.

---

## Step 8 — Clock tampering does not extend the grace

1. Repeat the 14-day-lock state from Step 7 via the DEBUG override.
2. While the lock is active, **set the device system clock backward by 30 days**.
3. Try to play.

**Verify**:
- The lock is **still active** (FR-013a, SC-009 — "regardless of device-clock manipulation").
- The block message is unchanged.

---

## Pass / fail summary mapping

| Step | Spec Reference | Pass When |
|---|---|---|
| 1 | US1 AS1, FR-002, FR-003, FR-004 | File present, ciphertext, sandboxed |
| 2 | US1 AS2, US1 AS4, FR-007, FR-009, SC-002 | Plays offline, no network calls, completion queued |
| 3 | US2 AS1–AS4, FR-010, FR-011, FR-012, FR-020, SC-001 | Cold-start < 5 s, signed-in, cached views render |
| 4 | FR-008, FR-015, FR-016, SC-004 | Progress synced within 30 s, queue drained |
| 5 | US3 AS1–AS2, FR-017, FR-018, SC-005 | Manage screen accurate; remove reclaims storage |
| 6 | FR-012a–d | Sync-then-wipe completes; no progress lost |
| 7 | FR-013a, SC-009 | Lock kicks in; clears on reconnect |
| 8 | FR-013a, SC-009 | Clock rewind does not bypass lock |
