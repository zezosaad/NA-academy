# Feature Specification: Offline Mode (Downloaded Videos & Offline App Access)

**Feature Branch**: `004-offline-mode`
**Created**: 2026-04-30
**Status**: Draft
**Input**: User description: "I want the videos to play offline, but they have to be stored within the app. I also want to be able to open the app without internet access."

## Clarifications

### Session 2026-04-30

- Q: What level of content protection is required for downloaded videos? → A: Consumer-grade only — app-private storage, no OS share/export, encrypt-at-rest with an app-managed key, revoke on entitlement loss. No external license server, no studio-grade DRM (Widevine L1 / FairPlay).
- Q: How long can a learner stay offline before downloaded videos require re-verification? → A: 14-day offline grace — after 14 days without an online entitlement check, downloaded videos refuse to play until the device reconnects and re-verifies.
- Q: What network policy applies to starting a download (Wi-Fi only, cellular allowed, prompt, etc.)? → A: Always allow on any network with no setting and no per-download prompt. Downloads run on whatever connection is available at the time.
- Q: How many devices per account can hold offline downloads at the same time? → A: Single device only — downloads on a new device automatically wipe downloads on the previous device for that learner.
- Q: How is the deactivated previous device handled on reconnect when offline downloads are moved to a new device? → A: Sync-then-wipe — the deactivated device first uploads any pending offline progress events, then notifies the learner that downloads moved to the new device, then deletes its local offline files. Offline progress is preserved even though files are not.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Watch a downloaded lesson video without internet (Priority: P1)

A learner anticipates being offline (commute, weak signal area, travel, capped data plan). While still online, they choose specific lesson videos to download. Once downloaded, those videos are stored inside the app and play with no network connection — no buffering, no streaming dependency. Downloaded videos remain bound to the app: they cannot be exported, copied to the device gallery, or shared with other apps.

**Why this priority**: Video-based learning is the core value of the academy. Reliable offline playback is the most-requested mobility feature and the single largest blocker for students with unreliable connectivity. This story alone — even without other offline capabilities — delivers most of the value.

**Independent Test**: A learner downloads a video while online, enables airplane mode, opens the lesson, and plays the video end-to-end at full quality. Verified by completing playback with the device in airplane mode and confirming the file is accessible only inside the app (not in OS file browsers, gallery, or other apps).

**Acceptance Scenarios**:

1. **Given** the learner is enrolled in a lesson with a video and is online, **When** they tap the lesson's "Download" control, **Then** the video is saved into the app's private storage and a "Available offline" indicator appears on the lesson.
2. **Given** the learner has downloaded a video and the device has no internet connection, **When** they open the lesson and press play, **Then** the video plays from local storage without any buffering or network calls, including seeking and pausing.
3. **Given** a downloaded video, **When** the learner attempts to access the video file through the device's file manager, gallery, or via "share" from another app, **Then** the file is not visible or accessible outside the academy app.
4. **Given** a learner is offline and watches a downloaded video to completion, **When** the device next reconnects, **Then** the lesson's progress and completion are synchronized to the learner's account.
5. **Given** a learner has downloaded a video, **When** they tap "Remove download" on that lesson, **Then** the local file is deleted, storage is reclaimed, and the lesson reverts to streaming-only.

---

### User Story 2 - Open the app and browse already-loaded content with no internet (Priority: P1)

A learner launches the app while offline (e.g., subway, on a plane, in a no-signal classroom). The app opens without showing a blocking error screen, the learner stays signed in, and they can: see their enrolled courses and lesson list, open lessons whose video has been downloaded, view their existing progress, and read previously-loaded lesson text/descriptions. Features that genuinely require the network (live chat, submitting exams, fetching not-yet-cached content) are clearly marked as unavailable, but they do not break the rest of the app.

**Why this priority**: A learner who can't even open the app while offline cannot benefit from downloaded videos. This story is co-essential with Story 1 — together they form the offline MVP.

**Independent Test**: With the device in airplane mode from a cold start (app fully closed), the learner launches the app and successfully reaches the lessons list, opens an already-downloaded lesson, and sees their cached progress — all without any network error blocking the flow.

**Acceptance Scenarios**:

1. **Given** the learner has previously signed in and the device is offline, **When** they launch the app from a cold start, **Then** the app opens to the home/courses screen without forcing logout and without a full-screen error.
2. **Given** the app is open offline, **When** the learner navigates to a course they previously viewed, **Then** the course structure (lessons, titles, ordering) is shown from cached data.
3. **Given** the app is open offline, **When** the learner opens a network-required area such as live chat or an unstarted exam, **Then** that area shows a clear, contextual "You're offline — this needs a connection" state instead of crashing or freezing.
4. **Given** the app is offline and the learner attempts to open a lesson whose video is *not* downloaded, **When** they reach the lesson page, **Then** the lesson page still loads its text content (if cached) and the video player shows a clear "Not downloaded — connect to watch or download" state.
5. **Given** the device regains connectivity while the app is open, **When** the network returns, **Then** any progress, exam answers (if exams are saved offline), and pending interactions sync automatically without requiring the learner to retry manually.

---

### User Story 3 - Manage offline downloads and storage (Priority: P2)

A learner browses what they have downloaded, sees how much device storage the academy app is using for offline content, and can free space by removing individual videos, all videos in a course, or every offline download at once. They can also choose a default download quality (e.g., standard vs. high) to balance storage use against playback fidelity.

**Why this priority**: Mobile devices have finite storage, and downloaded video can grow quickly. Without controls, learners run into "device full" errors and uninstall the app to recover space — a worse outcome than not offering downloads at all.

**Independent Test**: A learner with 3+ downloaded videos opens an "Offline downloads" screen, sees a per-item list with sizes and a total, removes one item, and observes the total drop and the device storage be reclaimed.

**Acceptance Scenarios**:

1. **Given** the learner has downloaded one or more videos, **When** they open the "Offline downloads" screen, **Then** they see each downloaded item with its title, course, file size, and download date, plus a total storage used.
2. **Given** the offline downloads screen, **When** the learner taps "Remove" on a single item, **Then** that file is deleted, the total updates, and the lesson reverts to streaming-only.
3. **Given** the learner is starting a download and has set a download-quality preference, **When** the download begins, **Then** the file saved matches the chosen quality (e.g., standard vs. high).
4. **Given** the device is low on free storage, **When** the learner attempts to start a new download that would exceed available space, **Then** the app blocks the download and shows guidance on freeing space, rather than partially downloading and silently failing.

---

### Edge Cases

- **Download interrupted by network drop or app close**: The download must resume from where it stopped (or at minimum, restart cleanly) when connectivity returns and the app reopens. A partial file must never be playable as if it were complete.
- **Subscription / access revoked while offline content exists**: If a learner loses access to a course (subscription ended, enrollment revoked, content removed by admin), downloaded videos for that course must become unplayable on the next time the app verifies online (FR-013). In addition, even without an online check, downloaded videos automatically lock after 14 consecutive days offline (FR-013a), preventing indefinite "download once, never reconnect" abuse.
- **Device clock tampering to extend offline grace**: Setting the device clock backward must not extend the 14-day offline window. The grace counter is anchored to the last server-confirmed timestamp plus monotonic uptime since then, not to user-settable wall-clock time.
- **Authentication token expires while offline**: The learner remains in a "signed-in offline" state and can keep using cached content; on reconnection, the app silently refreshes credentials. The learner is not forcibly signed out mid-session for being offline.
- **Video updated/replaced by content team after a learner downloaded it**: When the app reconnects, the learner is informed the lesson has a newer version and offered to re-download. The old downloaded copy may be played until they choose to update.
- **Device storage runs out during an active download**: Download stops cleanly, partial file is removed, the learner sees a clear "Not enough space" error.
- **App reinstalled or device changed**: Offline downloads do not survive an uninstall (they live inside app private storage). The learner must re-download on the new install. This is acceptable.
- **Learner activates downloads on a second device**: The learner is allowed only one active offline device per account. Activating downloads on a new device invalidates and wipes the previous device's offline files on its next online check, with clear notifications on both sides — not a silent purge. See FR-012a / FR-012b.
- **Deactivated device reconnects with unsynced offline progress**: The reconnect flow on a deactivated previous device is sync-then-wipe (FR-012d): pending progress is uploaded first, then the learner is notified, then files are deleted. If the progress upload fails, deletion is deferred until the next successful sync — offline progress is never lost because of the device handoff.
- **Offline-modified progress conflicts with newer online progress**: When syncing, the most recent timestamp wins per lesson; if a learner watched the same lesson on two devices offline, the further-along progress wins.
- **Exam or quiz attempted offline**: Exams require live submission and are out of scope for offline mode (see Out of Scope). The exam UI shows a clear offline-blocked state.

## Requirements *(mandatory)*

### Functional Requirements

#### Downloading & storing videos

- **FR-001**: Learners MUST be able to mark an individual lesson video for download from within that lesson's screen, while online.
- **FR-002**: Downloaded videos MUST be stored inside the app's private storage area, such that they are not visible to the device's file manager, photo gallery, OS-level "Files" apps, or other applications via system share/intent mechanisms.
- **FR-003**: Downloaded videos MUST NOT be exportable, copyable to the device gallery, or shareable to other apps from within the academy app.
- **FR-003a**: Downloaded video files MUST be encrypted at rest using an app-managed key, such that pulling the raw file off-device (e.g., via developer tools, rooted/jailbroken inspection, backup extraction) yields unplayable ciphertext rather than a directly playable media file. No external license server is required for playback; the app itself manages the key.
- **FR-004**: The app MUST show a clear visual state on each downloadable item: not downloaded, downloading (with progress), downloaded, and download failed.
- **FR-005**: Downloads MUST be resumable after a network interruption, app restart, or device reboot — partial progress is not discarded silently.
- **FR-006**: The system MUST prevent a download from starting if the device does not have enough free space, and MUST show the learner a clear reason and recovery suggestion.
- **FR-006a**: Downloads MUST proceed on whatever network is available (Wi-Fi or cellular) without any network-type setting and without a per-download "you're on cellular" confirmation prompt. The app MUST NOT distinguish between connection types when starting or resuming downloads.

#### Offline playback

- **FR-007**: A downloaded lesson video MUST play fully offline, including pause, resume, seek, and playback-speed controls, without any network calls required for the playback itself.
- **FR-008**: While playing an offline video, the app MUST track watch progress locally and queue it for sync when the device reconnects.
- **FR-009**: When an offline video reaches its completion threshold, the lesson MUST be marked as completed locally, and that completion MUST sync to the server on reconnection.

#### Cold-start and offline app access

- **FR-010**: The app MUST open from a cold start while offline, without requiring any network call to render its initial home/courses screen, provided the learner has signed in at least once before.
- **FR-011**: Learners who were signed in at the time of going offline MUST remain signed in across cold starts while offline; the app MUST NOT force a sign-out solely because the network is unavailable.
- **FR-012**: Network-dependent features (live chat, exam submission, fetching not-yet-cached content) MUST display a clear, in-context offline state rather than blocking error dialogs or crashes.

#### Multi-device policy

- **FR-012a**: Each learner account MUST hold offline downloads on **at most one device at a time** ("the active offline device"). When the learner signs in to the academy app on a new device and triggers any download (or, on the back end's next sync, is detected as having downloads on a different device), the previous device's offline downloads MUST be invalidated and removed from local storage on its next online check.
- **FR-012b**: The transition from one active offline device to another MUST surface a clear, in-app notification on **both** devices: the new device confirms it is now the active offline device, and the previous device informs the learner that their offline downloads were wiped because they activated downloads on another device. This avoids silent data loss.
- **FR-012c**: Streaming (online) playback, browsing, and signing in MUST remain available on multiple devices simultaneously — the single-device limit applies **only** to offline downloads, not to general account access.
- **FR-012d**: When a deactivated previous device reconnects, the app MUST follow a strict ordering: (1) upload all locally-buffered offline progress events for that learner to the server; (2) display an in-app notification informing the learner that their offline downloads have moved to the new device; (3) only then delete the local offline files and reclaim storage. If step (1) fails, the local files MUST NOT be deleted on this reconnect cycle — the deletion is retried on the next reconnect after a successful progress sync, so that no learner-favorable progress is ever lost solely because of the device handoff.

#### Access control & content lifecycle

- **FR-013**: When the app reconnects, it MUST verify the learner still has access to each downloaded video. If access has been revoked (course unenrolled, subscription ended, admin removed content), the corresponding offline file MUST be deleted and the lesson MUST revert to a not-available state.
- **FR-013a**: Each downloaded video MUST track the timestamp of the most recent successful online entitlement verification. If the device has been offline (no successful verification) for **more than 14 consecutive days**, downloaded videos MUST refuse to play and prompt the learner to reconnect to re-verify access. Once the device reconnects and verification succeeds (or fails), the 14-day clock resets (or the file is wiped if access was revoked). The 14-day window applies even if the device clock is tampered with — the system MUST use a tamper-resistant time source (e.g., the most recent server-confirmed timestamp combined with monotonic device uptime since then) rather than relying on user-settable wall-clock time.
- **FR-014**: When content is updated server-side after a learner downloaded it, the app MUST detect the update on next reconnection and offer the learner to re-download the newer version. The previously downloaded version MAY remain playable until the learner chooses to update or remove it.

#### Sync on reconnect

- **FR-015**: On reconnection, the app MUST automatically synchronize: video watch progress, lesson completion events, and any other locally-buffered state, without requiring the learner to take a manual action.
- **FR-016**: Conflicting offline and online progress for the same lesson MUST resolve to the most-advanced position (further-along progress wins), preserving learner-favorable behavior.

#### Storage management

- **FR-017**: Learners MUST be able to view a list of all downloaded videos with title, parent course, file size, and download date, plus a running total of storage used by offline content.
- **FR-018**: Learners MUST be able to delete an individual downloaded video, all downloads for a single course, or all offline downloads, freeing the corresponding storage.
- **FR-019**: Learners MUST be able to choose a default download quality (at minimum: a standard option and a higher-fidelity option) before initiating downloads, balancing storage size against playback quality.

#### Cached non-video content (offline browsing)

- **FR-020**: The app MUST cache enough learner-specific data while online — at minimum: enrolled courses, the lesson list/structure for those courses, the learner's progress, and previously-viewed lesson text/description content — so that those views render offline without network calls.

### Key Entities *(include if feature involves data)*

- **Offline Download**: A locally-stored copy of a single lesson video, scoped to one learner on one device. Attributes: linked lesson, linked course, file size, download timestamp, chosen quality, download status (queued/downloading/complete/failed/revoked/superseded-by-other-device), last-verified-online timestamp (drives the 14-day grace), source content version identifier.
- **Offline Library**: The collection of all Offline Downloads on a given device for a given learner. Used to compute total storage, present the manage-downloads view, and drive bulk operations.
- **Cached Content Snapshot**: The locally-persisted slice of learner-visible data — enrolled courses, lesson lists, lesson text/metadata, learner progress — that allows offline cold-start and offline navigation. Refreshed opportunistically when online.
- **Pending Sync Event**: A locally-buffered change made offline (watch progress, lesson completion) that will be transmitted on reconnection. Each event has a timestamp and target entity to support last-write-wins-by-progress conflict resolution.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: From a cold start in airplane mode, a previously-signed-in learner reaches the lessons list and starts a downloaded video in under 5 seconds.
- **SC-002**: 100% of fully-downloaded videos play end-to-end offline without buffering, stalls, or network errors. Zero network calls are required during playback of a downloaded video.
- **SC-003**: 0 downloaded video files are accessible via the device's file manager, gallery, or share-to-other-app flows; the file is bound to the app.
- **SC-004**: When connectivity returns, 95% of pending offline progress events sync successfully within 30 seconds of reconnection without learner intervention.
- **SC-005**: Storage used by offline content reported in the manage-downloads view matches actual on-device usage within ±5%.
- **SC-006**: Within the first 60 days of release, at least 30% of weekly-active learners use offline mode at least once (download or offline playback), validating real demand.
- **SC-007**: Customer-support tickets that mention "no internet", "buffering", "won't open without wifi", or equivalent drop by at least 50% within 90 days of release.
- **SC-008**: When access to a course is revoked, downloaded videos for that course become unplayable within 1 reconnection cycle (next time the app comes online and verifies entitlement).
- **SC-009**: 100% of downloaded videos refuse to play after 14 consecutive days without a successful online entitlement verification, regardless of device-clock manipulation. After a successful re-verification, playback resumes immediately for content the learner is still entitled to.

## Assumptions

- Learners must sign in at least once while online before offline mode is available; a brand-new install on an offline device is out of scope.
- "Download" is a deliberate, learner-initiated action per video. Auto-downloading entire courses or background "smart" prefetching is out of scope for v1; it can be added later without changing the foundation.
- Offline scope is **video playback + browsing previously-viewed lesson content + viewing cached progress**. Live chat, exam-taking, and content discovery for not-yet-viewed material remain online-required (they show a clear offline state, not an error).
- Downloaded video files are bound to the app's private storage and to the learner's account on this device; they do not survive an uninstall, and they are not transferable to another device or another account.
- Storage limits are governed by the device's available free space and learner-driven cleanup. The app does not impose a hard cap; instead it prevents downloads that would not fit and offers clear management tools.
- Conflict resolution for progress uses "further-along progress wins" rather than strict last-write-wins, because it is more learner-favorable and consistent with how the platform already treats lesson progress.
- The existing authentication system (email + password / OAuth as already in the platform) is reused. No new auth flow is introduced for offline mode beyond keeping the learner signed in across offline cold starts.
- Content protection is **consumer-grade**: files live in app-private storage, are not exposed via OS share/file APIs, are encrypted at rest with an app-managed key, and are revoked when entitlement is lost. Studio-grade DRM (Widevine L1, FairPlay) and external license servers are **not** required in v1; they can be layered on later if the content team adopts contracts that require them.

## Out of Scope (v1)

- Offline exam taking and offline exam submission.
- Offline live chat / messaging (one-to-one or group).
- Background or "smart" auto-download (e.g., download next 3 lessons automatically).
- Sharing or transferring downloaded content between devices or learners.
- Studio-grade DRM (Widevine L1 / FairPlay / PlayReady).
- A web/desktop offline experience — this feature is for the mobile app.
- Offline downloads of non-video assets (PDFs, slide decks) — handled in a future feature.

## Dependencies

- Existing lessons / courses content model and the learner's enrollment / entitlement data must already be available via the platform — this feature consumes them; it does not redefine them.
- Existing authentication and session model must support a "signed-in but offline" state (token kept locally, refreshed on reconnect). If the current platform forces a server check on every cold start, that behavior must be relaxed for this feature.
- Existing lesson-progress sync API must accept batched / replayed progress events from a device that was offline.
