# Feature Specification: Push Notifications & In-App Inbox

**Feature Branch**: `005-fcm-push-notifications`
**Created**: 2026-05-01
**Status**: Draft
**Input**: User description: "Implement push notifications using Firebase Cloud Messaging (FCM). Admins send notifications from the dashboard to the mobile app. Notifications are delivered instantly, persisted in the backend, and shown in an in-app inbox. Each notification has title, body, timestamp, and optional data payload. Dashboard supports targeting specific users or all users, plus a history of sent notifications. Mobile app handles foreground, background, and terminated states and displays notifications in a clean inbox screen."

## Clarifications

### Session 2026-05-01

- Q: Audience targeting model in v1 — should the dashboard support group targeting beyond "all users" and individual user picker? → A: Support **All users + specific user picker + course as a group target**. Role-based and custom-segment targeting are deferred to a later release.
- Q: Who is authorized to send notifications? → A: **Admins** can send to any audience (all users / specific users / any course). **Teachers** can send only to **their own course's enrolled students** (audience kind `course`, restricted to courses they own; they cannot use "all users" or arbitrary user picks).
- Q: How long is sent-notification history retained? → A: **Notifications themselves are retained indefinitely** (full audit trail of what was announced). **Per-recipient delivery rows are auto-pruned 365 days after the notification's send time.** After pruning, the history detail view shows the notification with aggregate counts only (no per-user delivery state).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Admin sends an announcement to all students (Priority: P1)

An academy administrator opens the admin dashboard, composes a notification (e.g., "Live Q&A starts in 10 minutes"), selects "All users" as the audience, and sends it. Every student with the mobile app receives a push notification within seconds. When the student opens the app, the announcement is also visible in the in-app notifications inbox along with its title, body, and timestamp.

**Why this priority**: This is the core value proposition — broadcast communication from the academy to its learners. Without this path, the feature delivers nothing.

**Independent Test**: An admin sends a "broadcast to all" message from the dashboard; a logged-in mobile test user receives the OS-level push within 5 seconds and finds the same message in the in-app inbox after opening the app.

**Acceptance Scenarios**:

1. **Given** the admin is on the dashboard's "Send Notification" form and has entered a valid title and body, **When** they choose "All users" and click "Send", **Then** the system confirms the send within 5 seconds and shows the notification in the dashboard's history list with status "Sent" and the recipient count.
2. **Given** a student has the mobile app installed and notification permissions granted, **When** an admin broadcasts a notification, **Then** the student sees an OS-level push notification within 10 seconds while the app is closed or in the background.
3. **Given** a student receives a notification while the app is in the foreground, **When** they tap it (or simply look at the screen), **Then** the notification is visible in the in-app inbox without disrupting their current screen with a system banner duplicate.

---

### User Story 2 - Student reviews past notifications in the in-app inbox (Priority: P1)

A student opens the notifications inbox in the mobile app. They see a chronological list of notifications they have received, including ones that arrived while they were offline or had cleared from the OS notification tray. They can tap a notification to view its full content, including any associated link or context (e.g., "Open exam"). Read and unread notifications are visually distinguished, and unread count is reflected on the bell icon on the home screen.

**Why this priority**: Without persistence and an inbox, push notifications become disposable — students who miss the OS popup lose the message entirely. This is essential for reliability of communication.

**Independent Test**: With a student account that has 5 historical notifications stored on the backend, opening the inbox shows all 5 in reverse-chronological order; tapping one marks it read and reduces the unread badge.

**Acceptance Scenarios**:

1. **Given** a student has 3 unread notifications, **When** they open the home screen, **Then** the bell icon displays an unread count badge of "3".
2. **Given** the student opens the notifications inbox, **When** the screen loads, **Then** they see all notifications they have received in reverse-chronological order with title, snippet of body, and relative timestamp (e.g., "2h ago").
3. **Given** the student taps an unread notification, **When** the detail view opens, **Then** the full body and timestamp are displayed and the notification is marked as read; the badge count decreases accordingly.
4. **Given** the student is offline when an in-app inbox load is requested, **When** they open the inbox, **Then** they see the most recently cached notifications without errors and a non-blocking indicator that newer items will appear when connectivity returns.

---

### User Story 3 - Admin targets a specific subset of users (Priority: P2)

An admin needs to message only a subset of users (e.g., students enrolled in a specific course, or a hand-picked list of users). They open the dashboard's notification form, switch from "All users" to a targeted mode, select recipients (by individual user search or by group such as a course), and send. Only those users receive the push and the in-app inbox entry.

**Why this priority**: Broadcast-only is sufficient for an MVP, but targeted messaging is essential for course-specific announcements (exam reminders, schedule changes) and avoids notification fatigue.

**Independent Test**: An admin selects 3 specific users (or one course's enrolled students) and sends a notification; only those users receive both the push and the inbox entry, and other users see nothing new.

**Acceptance Scenarios**:

1. **Given** the admin is on the notification form, **When** they choose "Specific users" and search for users by name or email, **Then** matching users appear in the picker and selected users are shown as removable chips.
2. **Given** the admin has selected a course as a target audience, **When** they send the notification, **Then** every active enrolled student of that course receives the push and inbox entry, and no one else does.
3. **Given** a targeted send was completed, **When** the admin views the dashboard's history list, **Then** the entry shows the audience description (e.g., "Course: Algebra 101 — 42 recipients") and the delivered/total counts.
4. **Given** a teacher is logged into the dashboard, **When** they open the notification form, **Then** the audience selector exposes only their own courses (no "All users" option, no arbitrary user picker), and any attempt via API to send outside that scope is rejected.

---

### User Story 4 - Admin reviews send history (Priority: P3)

An admin opens the "Notifications" section of the dashboard to see a paginated, searchable list of every notification ever sent. Each row shows the title, audience, sender (admin name), sent-at timestamp, and counts of delivered / failed / read recipients. They can click an entry for details (full body, payload, full recipient list, per-recipient delivery status).

**Why this priority**: Auditability and operational visibility — important for a multi-admin team and for supporting students who say "I didn't get the message."

**Independent Test**: After sending 10 notifications across the system, the dashboard's history page lists exactly 10 entries with correct metadata, and pagination/search works for any title keyword.

**Acceptance Scenarios**:

1. **Given** at least 25 notifications have been sent, **When** the admin opens the history list, **Then** entries are paginated (default 20 per page) in reverse-chronological order.
2. **Given** the admin types a keyword into the search field, **When** results refresh, **Then** only notifications whose title or body contains the keyword are shown.
3. **Given** the admin clicks a notification entry, **When** the detail view opens, **Then** they see full body, full audience, sender, send time, delivered count, failed count, and read count.

---

### Edge Cases

- **Permission denied on device**: Student denies OS notification permission. The app must still record incoming notifications in the in-app inbox (server-driven retrieval) so the student does not lose messages, and must surface a non-blocking prompt explaining how to re-enable system notifications.
- **App uninstalled / token invalidated**: A previously registered device token is no longer valid. The system must recognize permanent failures (e.g., `UNREGISTERED`) and stop attempting future delivery to that token without blocking sends to other recipients.
- **User logs out / switches accounts**: When a user logs out, their device token must be unsubscribed from their account so notifications don't follow the device to the next user. When a new user logs in, the token is registered to the new account.
- **Multi-device users**: A user with the app on two devices (phone + tablet) receives the push on both, but the inbox state (read/unread) is consistent across devices.
- **Send to empty audience**: If an admin sends a targeted notification but the audience resolves to zero users (e.g., a course with no enrolled students), the system must reject the send with a clear error rather than silently log a 0-recipient record.
- **Very long body text**: The push notification respects platform body length limits without truncating the persisted in-app version. The full body is always available in the inbox.
- **Network failure during send from dashboard**: If the dashboard fails to confirm send, the admin sees a clear error and can retry without producing duplicate sends (idempotent submission).
- **Duplicate delivery**: A user must never see the same notification twice in the inbox even if FCM redelivers a message.
- **Notification arrives while offline**: When the device reconnects, any messages that were queued by the platform are still visible, and any messages that exceeded platform queueing TTL are recoverable from the inbox via server fetch.
- **Tapping a notification with a deep link payload**: Tapping the push or inbox entry navigates the user to the referenced screen (e.g., a specific course or exam) when the app is opened from any state (foreground/background/terminated).
- **Scope of clarifications**: Sender role and targeting modes beyond individuals/all are flagged below.

## Requirements *(mandatory)*

### Functional Requirements

#### Composition & Sending (Dashboard)

- **FR-001**: The dashboard MUST provide a form to compose a new notification with required fields **title** and **body**, and an optional **data payload** (key-value pairs interpretable by the mobile app, e.g., `{ "type": "exam", "examId": "abc123" }`).
- **FR-002**: The dashboard form MUST allow the sender to choose between **"All users"** and **"Specific users"** as the audience.
- **FR-003**: When **"Specific users"** is selected, the form MUST allow the sender to search for and add individual users by name or email, and to remove selected users before sending.
- **FR-004**: The dashboard form MUST support **course** as a group audience target: when the sender selects a course, the system MUST resolve the audience at send time to all currently enrolled students of that course. Role-based targets (e.g., "all teachers") and custom segments are explicitly out of scope for v1.
- **FR-005**: The system MUST validate notification input before sending — title and body are non-empty, title length ≤ 100 characters, body length ≤ 1000 characters, audience non-empty.
- **FR-006**: On successful send, the system MUST return confirmation to the sender including the notification ID and the resolved recipient count, within 5 seconds for audiences up to 1,000 recipients.
- **FR-007**: The system MUST treat each send submission as **idempotent** so that an accidental retry from the dashboard does not result in duplicate delivery.
- **FR-008**: The system MUST enforce role-based authorization on send actions: **admins** may send to any audience kind (`all`, `user-list`, or `course`); **teachers** may send only with audience kind `course` and only for courses they own (i.e., are listed as instructor of). Any send attempt outside these bounds MUST be rejected with `403 Forbidden` and logged.

#### Delivery

- **FR-009**: The system MUST deliver each notification as an OS-level push to all targeted users' registered devices, with **median delivery time within 5 seconds** of the admin clicking "Send".
- **FR-010**: The system MUST persist every notification (title, body, optional data, timestamp, sender identity, audience descriptor) in the backend at the moment of send so it remains retrievable even if push delivery fails.
- **FR-011**: The system MUST track per-recipient delivery state with at minimum the states **pending → delivered | failed**, plus a **read** flag set when the user opens the notification.
- **FR-012**: The system MUST stop attempting future delivery to device tokens that the push provider reports as permanently invalid (uninstalled / disabled / unregistered) and remove those tokens from the user's account.
- **FR-013**: The system MUST guarantee a notification cannot be delivered to a user who is not in the resolved audience.

#### Mobile App: In-App Inbox

- **FR-014**: The mobile app MUST display a notifications inbox screen, accessible from the bell icon on the home screen, showing all notifications received by the current user in reverse-chronological order.
- **FR-015**: Each inbox row MUST show the title, a body snippet, a relative timestamp (e.g., "2 min ago", "yesterday"), and a visual indicator for unread items.
- **FR-016**: The bell icon on the home screen MUST display an **unread count badge** that reflects the number of unread notifications, updating in real time when a new notification arrives or one is read.
- **FR-017**: Tapping a notification (in the inbox or via the OS push) MUST open a detail view showing the full body and timestamp, mark the item as read, and decrement the unread count.
- **FR-018**: When a notification's data payload includes a deep-link target (e.g., a specific exam or course), tapping the notification MUST navigate the user to that screen, regardless of whether the app was foreground, background, or terminated when the push arrived.
- **FR-019**: The inbox MUST function while the device is **offline** by showing the most recently cached notifications; new notifications received via push while offline must still appear in the inbox once online.
- **FR-020**: The inbox MUST support pagination or lazy loading so that large histories (≥ 200 items) do not block the UI.
- **FR-021**: The user MUST be able to **mark all as read** from the inbox screen with a single action.

#### Mobile App: Permissions & Device Registration

- **FR-022**: On first launch (or when the user first reaches a screen that benefits from notifications), the app MUST request OS notification permission with an explanation of why it's needed.
- **FR-023**: When the user is logged in, the app MUST register the device's push token with the backend, associated with that user's account.
- **FR-024**: When the user logs out, the app MUST unregister the device's push token from the account so subsequent notifications for that account do not arrive on the device.
- **FR-025**: If the OS push token rotates, the app MUST update the backend registration with the new token without user action.

#### Dashboard: History & Audit

- **FR-026**: The dashboard MUST provide a paginated list of all previously sent notifications, ordered most-recent-first, with title, audience descriptor, sender name, sent timestamp, and counts of delivered/failed/read.
- **FR-027**: The history list MUST be searchable by keyword over title and body.
- **FR-028**: Clicking a history entry MUST open a detail view showing the full notification content, the resolved recipient list (or audience descriptor with count), and per-recipient delivery status.
- **FR-029**: The system MUST retain notification records (title, body, payload, sender, audience descriptor, aggregate counts) **indefinitely**. Per-recipient delivery records (`Notification Recipient` entities) MUST be auto-pruned **365 days after the notification's send timestamp**. After pruning, the dashboard's history detail view MUST still display the notification with its aggregate counts, but the per-recipient delivery list MUST be replaced by a notice that detailed delivery state has been archived.

#### Security & Compliance

- **FR-030**: All dashboard send requests MUST be authenticated and authorized; unauthenticated or unauthorized callers MUST be rejected with no side effects.
- **FR-031**: Push provider credentials (server keys / service account) MUST be stored as backend-side secrets and never exposed to the dashboard or mobile clients.
- **FR-032**: The system MUST log every send action with sender identity, timestamp, audience, and a hash of the message content for audit purposes.
- **FR-033**: Personally identifiable information in notification bodies (e.g., full names) MUST be limited to what's necessary for the message; the system MUST NOT include credentials, tokens, or one-time passcodes in push bodies.

### Key Entities *(include if feature involves data)*

- **Notification**: A single message authored by an admin. Attributes: unique ID, title, body, optional data payload (structured key-value), sender (admin user reference), audience descriptor (e.g., `all`, `users:[ids]`, `course:<id>`), created-at timestamp, status summary (delivered count, failed count, read count).
- **Notification Recipient**: A per-user record linking one notification to one targeted user. Attributes: notification ID, user ID, delivery state (`pending` | `delivered` | `failed`), failure reason (if any), delivered-at timestamp, read-at timestamp.
- **Device Token Registration**: A per-device push token associated with a user account. Attributes: token value, owning user ID, device platform (iOS / Android), last-seen-at timestamp, validity status. A user may have multiple device tokens (multi-device); a token belongs to at most one user at a time.
- **Audience Descriptor**: The serializable description of who a notification was sent to. Attributes: kind (`all` | `user-list` | `course`), payload (list of user IDs for `user-list`, or course ID for `course`; empty for `all`), resolved-recipient-count (snapshotted at send time).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An admin can compose and send a notification to all users in **under 60 seconds** from opening the dashboard, including login.
- **SC-002**: 95% of push notifications reach a connected device's notification tray within **5 seconds** of the admin clicking "Send" (measured for audiences ≤ 10,000 recipients).
- **SC-003**: 100% of notifications are retrievable from the in-app inbox by the recipient at any point within the retention window, even if the OS-level push was missed or dismissed.
- **SC-004**: When a user opens the app after receiving notifications offline, the inbox reflects all pending notifications within **3 seconds** of regaining connectivity.
- **SC-005**: 0 cross-account leakage: in usability testing across 100 multi-user / multi-device sessions, no user receives a notification that was not addressed to them.
- **SC-006**: Support tickets containing "didn't receive notification" or "didn't see announcement" are reduced by **50%** within 60 days of launch (compared to the equivalent prior 60-day window).
- **SC-007**: Admins report being able to find the cause of a "didn't get it" complaint (delivered/failed/read state for a given user) in **under 2 minutes** using the dashboard's history detail view.
- **SC-008**: The system handles a single broadcast to **10,000 recipients** without dashboard timeouts and with at least 99% per-recipient delivery success to valid tokens.

## Assumptions

- The mobile platform supports push notifications (iOS via APNs and Android via the platform's standard push mechanism); web push is **out of scope for v1**.
- The existing user authentication system is reused; no new account or session model is introduced.
- The existing role model exposes both **admin** and **teacher** identities, and a course → owning-teacher relationship is already represented in the data model. These are reused, not introduced by this feature.
- The dashboard, backend, and mobile app share a common user identifier model so audience resolution is unambiguous.
- "Instant" delivery is best-effort, bounded by the push provider's SLAs and the device's connectivity state — perceived latency targets are captured in SC-002 and SC-004.
- In-app notification inbox is the **authoritative source of truth** for what a user has received; the OS notification tray is treated as a transient surface.
- v1 does **not** include scheduled/future-dated sends, recurring sends, or A/B testing of notifications. These can be added later.
- v1 does **not** include rich media (images, action buttons) in notifications; plain title + body + optional data only.
- v1 does **not** include user-side preferences for notification categories (e.g., "mute course updates"); a single global on/off toggle in app settings is sufficient.
- Push provider configuration (project setup, certificates/keys, environment separation between dev/staging/prod) is handled as part of the implementation plan, not the spec.

## Dependencies

- Existing user account & authentication system (mobile app login state and admin dashboard login).
- Existing dashboard shell where the "Notifications" section will be added.
- A push notification provider integration (defined in the implementation plan).
- A persistent backend datastore for notifications and per-recipient delivery records.
- Course / enrollment data — required for resolving course-targeted audiences at send time (FR-004).
