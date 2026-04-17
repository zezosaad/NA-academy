# Feature Specification: NA-Academy Backend Platform

**Feature Branch**: `001-academy-backend-platform`  
**Created**: 2026-04-17  
**Status**: Draft  
**Input**: User description: "Build a scalable backend for an academic platform managing content, media streaming, and a dual-layered Activation Code System for Subjects and Exams."

## Clarifications

### Session 2026-04-17

- Q: Does a student's subject access expire after activation, or is it permanent? → A: Permanent access — once activated, student keeps access indefinitely. Admin can still revoke.
- Q: What automated action should the system take when security flags (screen recording, root/jailbreak) are detected? → A: Log the event and immediately suspend the active session (force re-authentication). Admin reviews for permanent action.
- Q: How should the system handle repeated failed activation code attempts (brute-force prevention)? → A: 5 failed attempts per 15-minute window locks activation for that student/device, then auto-unlocks.
- Q: Can a student message any teacher, or only teachers of their activated subjects? → A: Subject-gated — student can only message teachers assigned to subjects the student has activated.
- Q: Are multiple simultaneous sessions allowed on the same device? → A: Single active session — new login invalidates any existing session on the same device.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Admin Generates and Distributes Subject Activation Codes (Priority: P1)

An administrator needs to generate batches of activation codes that unlock access to specific subjects (courses) or subject bundles for students. After generating the codes, the admin exports them as CSV or Excel files for physical printing or digital distribution to students through external sales channels.

**Why this priority**: Activation codes are the primary monetization and access-control mechanism for the entire platform. Without code generation and distribution, no student can access any paid content.

**Independent Test**: Can be fully tested by logging in as admin, generating a batch of codes for a subject, exporting them, and verifying the exported file contains valid unique codes with correct metadata.

**Acceptance Scenarios**:

1. **Given** an admin is logged in and has selected a subject, **When** they request bulk generation of 500 codes, **Then** the system generates 500 unique alphanumeric codes linked to that subject, all with "Available" status.
2. **Given** an admin has generated a batch of codes, **When** they request an export, **Then** the system produces a downloadable CSV or Excel file containing code value, linked subject, status, and generation date.
3. **Given** an admin views the code management dashboard, **When** they inspect a specific code batch, **Then** they see each code's status (Available, Used, or Expired), the student who activated it (if used), and the activation date.
4. **Given** an admin needs to revoke a code, **When** they select a code and revoke it, **Then** the code status changes to Expired and can no longer be activated by any student.

---

### User Story 2 - Student Activates a Subject Code and Accesses Course Content (Priority: P1)

A student who has purchased an activation code enters it into the platform to unlock access to a subject's video lessons and related content. The system verifies the code is valid, unused, and binds it to the student's account and device. Once activated, the student can stream video content with full playback controls.

**Why this priority**: This is the core student-facing flow that delivers the product's primary value — accessing educational content through a legitimate code.

**Independent Test**: Can be fully tested by registering a student account, entering a valid subject code, verifying access is granted, and streaming a video from the unlocked subject with seeking and speed controls.

**Acceptance Scenarios**:

1. **Given** a student has a valid, unused subject code, **When** they enter the code on their registered device, **Then** the system marks the code as "Used", links it to the student's account and device, records the activation date, and grants access to all content within that subject.
2. **Given** a student has activated a subject code, **When** they navigate to that subject's content, **Then** they can browse and stream all videos with support for forward/backward seeking and playback speed control.
3. **Given** a student enters an already-used code, **When** the system validates it, **Then** the activation is rejected with a clear message indicating the code has already been used.
4. **Given** a student enters a valid code on a different device than their registered one, **When** the system validates it, **Then** the activation is rejected and the student is informed the code can only be used on their registered device.
5. **Given** a student without an active subject code attempts to access that subject's videos, **When** the system checks authorization, **Then** the video content is not served and the student is prompted to activate a code.

---

### User Story 3 - Student Activates an Exam Code and Takes an MCQ Assessment (Priority: P1)

A student enters an exam-specific activation code to unlock access to a multiple-choice exam. Exam codes may be single-use or multi-use, and some are time-limited (e.g., valid for 24 hours after first activation). The student takes the exam with per-question timers, and results are recorded.

**Why this priority**: Exams are a core academic feature that drive student engagement and measure learning outcomes, directly tied to the activation code monetization model.

**Independent Test**: Can be fully tested by activating an exam code, starting the exam, answering questions within per-question time limits, submitting results, and verifying the score is recorded correctly.

**Acceptance Scenarios**:

1. **Given** a student has a valid single-use exam code, **When** they activate it, **Then** the code is consumed, the exam becomes accessible, and the code cannot be reused.
2. **Given** a student has a valid multi-use exam code, **When** they activate it, **Then** the exam becomes accessible and the code's remaining use count decrements by one.
3. **Given** a student has activated a time-limited exam code (e.g., 24-hour validity), **When** they attempt to access the exam after the time window expires, **Then** access is denied with a message indicating the activation period has elapsed.
4. **Given** a student is taking an exam, **When** a per-question timer expires, **Then** the system automatically advances to the next question and the unanswered question is marked accordingly.
5. **Given** a student completes an exam, **When** they submit their answers, **Then** the system scores the exam, records the results, and displays the score to the student.
6. **Given** a student is in an area with intermittent connectivity, **When** they are taking an exam and lose connection, **Then** their progress is preserved locally and synchronized with the server when connectivity is restored.

---

### User Story 4 - Admin Manages Academic Content (Subjects, Exams, Videos) (Priority: P1)

An administrator creates, updates, and organizes subjects, uploads video lessons and images, creates MCQ exams with questions and options, and manages all academic content from a centralized control panel.

**Why this priority**: Content management is foundational — without subjects, exams, and videos, there is nothing for codes to unlock or students to access.

**Independent Test**: Can be fully tested by creating a subject, uploading a video to it, creating an MCQ exam with questions, and verifying all content is correctly stored and retrievable.

**Acceptance Scenarios**:

1. **Given** an admin is logged in, **When** they create a new subject with a title, description, and category, **Then** the subject is created and appears in the subject listing.
2. **Given** an admin has selected a subject, **When** they upload a video file, **Then** the video is stored and associated with the subject, ready for streaming.
3. **Given** an admin is creating an exam, **When** they add multiple-choice questions with options, correct answers, and per-question time limits, **Then** the exam is saved with all question configurations.
4. **Given** an admin uploads an image for course material, **When** the upload completes, **Then** the image is stored and can be referenced within subject content.

---

### User Story 5 - Real-Time Chat Between Students and Teachers (Priority: P2)

Students and teachers communicate through a real-time messaging system. Messages have delivery status indicators (Sent, Delivered, Read), and participants can share images within the chat. The chat enables academic support and student-teacher interaction.

**Why this priority**: Chat enhances the learning experience by enabling direct communication, but the platform can function without it for initial launch.

**Independent Test**: Can be fully tested by a student sending a message to a teacher, verifying delivery status updates, the teacher responding, and both parties sharing an image in the conversation.

**Acceptance Scenarios**:

1. **Given** a student is logged in and has activated a subject, **When** they select a teacher assigned to that subject to message, **Then** the message is delivered in real time and shows "Sent" status, transitioning to "Delivered" when the teacher's client receives it, and "Read" when the teacher opens it.
2. **Given** a student is in a chat conversation, **When** they upload and send an image, **Then** the image is stored, delivered to the teacher, and displayed inline in the conversation.
3. **Given** a teacher has received a message, **When** they reply, **Then** the student receives the reply in real time with the same status indicator progression.
4. **Given** a participant is offline, **When** a message is sent to them, **Then** the message is stored and delivered when the participant comes back online.

---

### User Story 6 - Student Performance Analytics (Priority: P2)

Administrators and teachers can view aggregated analytics for each student, including exam performance (scores, attempts, pass/fail rates), video watch-time per subject, and a summary of activated subjects and exams. Students can also view their own performance summary.

**Why this priority**: Analytics provide visibility into student progress and platform usage, but are not required for the core access-and-learn flow.

**Independent Test**: Can be fully tested by having a student complete exams and watch videos, then verifying the analytics dashboard accurately reflects their exam scores, watch-time, and activated content.

**Acceptance Scenarios**:

1. **Given** an admin or teacher views a specific student's analytics, **When** the data loads, **Then** they see exam scores and attempt history, total video watch-time per subject, and a list of all activated subjects and exams with activation dates.
2. **Given** a student views their own analytics dashboard, **When** the data loads, **Then** they see their exam performance history, total watch-time, and activated content summary.
3. **Given** an admin views aggregate platform analytics, **When** the dashboard loads, **Then** they see overall code usage statistics, active student counts, and sales metrics derived from code activations.

---

### User Story 7 - Admin Monitors Platform Activity in Real Time (Priority: P2)

An administrator can view a real-time dashboard showing currently active students, ongoing exam sessions, recent code activations, and sales statistics based on code usage patterns.

**Why this priority**: Real-time monitoring enables business oversight and operational awareness, supporting but not blocking core academic functionality.

**Independent Test**: Can be fully tested by having multiple students actively using the platform and verifying the admin dashboard reflects their activity accurately and in near real time.

**Acceptance Scenarios**:

1. **Given** an admin opens the monitoring dashboard, **When** students are active on the platform, **Then** the dashboard shows the count of currently active students updated in near real time.
2. **Given** codes are being activated by students, **When** the admin views sales statistics, **Then** they see a breakdown of code activations by subject, exam, date range, and revenue equivalent.
3. **Given** exam sessions are in progress, **When** the admin views active sessions, **Then** they see the number of ongoing exams and can identify suspicious activity flags.

---

### User Story 8 - Device Locking and Anti-Piracy Protection (Priority: P2)

When a student registers or activates their first code, the platform captures their device's hardware identifier. All subsequent code activations and content access are restricted to that specific device. The system detects and flags suspicious activities such as screen recording or rooted/jailbroken devices.

**Why this priority**: Anti-piracy protections safeguard the business model but are layered on top of the core access control; the platform functions without them, just with less protection.

**Independent Test**: Can be fully tested by registering on one device, attempting to log in or activate a code on a different device, and verifying the system blocks the second device.

**Acceptance Scenarios**:

1. **Given** a student activates their first code on a device, **When** the system records the device hardware identifier, **Then** the student's account is locked to that device.
2. **Given** a student is locked to Device A, **When** they attempt to activate a code or access content from Device B, **Then** the system rejects the request and notifies the student.
3. **Given** a student's client application detects a screen recording tool or root/jailbreak status, **When** the client reports these flags to the server, **Then** the server logs the suspicious activity, immediately terminates the student's active session (forcing re-authentication), and queues the event for administrator review.
4. **Given** a student submits exam results from an offline session, **When** the server receives the results, **Then** the server validates the integrity and timestamp of the submitted data before accepting the results.

---

### User Story 9 - Free Exam Sections with Limited Attempts (Priority: P3)

Some exams or sections of exams are available without an activation code as a "free trial." These free sections have a limited number of attempts per student to encourage purchasing full access.

**Why this priority**: Free trials are a marketing and conversion tool, enhancing but not essential to the core platform.

**Independent Test**: Can be fully tested by a student accessing a free exam section, using all allowed attempts, and verifying the system blocks further attempts without a paid code.

**Acceptance Scenarios**:

1. **Given** an exam has a free section with 3 allowed attempts, **When** a student without an exam code accesses it, **Then** they can take the free section up to 3 times.
2. **Given** a student has exhausted their free attempts, **When** they try to access the free section again, **Then** the system blocks the attempt and prompts them to activate a code for full access.

---

### Edge Cases

- What happens when a student's device is lost or replaced? The admin must have the ability to reset the device lock for a student's account.
- How does the system handle bulk code generation for very large quantities (e.g., 10,000+ codes)? The operation must complete within a reasonable time and guarantee uniqueness.
- What happens when a time-limited exam code's window expires while the student is mid-exam? The student should be allowed to complete the current exam session but cannot start a new one.
- How does the system handle concurrent chat messages from many students to the same teacher? Messages must be queued and delivered in order without loss.
- What happens if a student's offline exam data is tampered with before sync? The server must reject data that fails integrity verification and flag the student's account.
- What happens when a student activates a bundle code but already has access to some subjects in the bundle? The overlapping subjects retain their longest-remaining access, and newly unlocked subjects are added.
- How does the system handle a video upload that exceeds the maximum allowed file size? The upload is rejected with a clear size-limit error before significant transfer occurs.
- What happens when a student hits the activation rate limit (5 failed attempts in 15 minutes)? The system blocks further activation attempts from that student/device and displays the remaining cooldown time. The lock auto-releases after the window elapses.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support two distinct types of activation codes: Subject Codes (granting access to subjects or subject bundles) and Exam Codes (granting access to specific MCQ assessments).
- **FR-002**: Each Subject Code MUST be linked to a specific subject or a defined bundle of subjects and carry a status of Available, Used, or Expired. Once a Subject Code is activated (Used), the student's access to the linked subject(s) is permanent and does not expire unless explicitly revoked by an administrator.
- **FR-003**: System MUST record which student activated which code, the activation date, and the device identifier used during activation.
- **FR-004**: Exam Codes MUST support single-use and multi-use configurations, with an optional time-limited validity window (e.g., 24 hours from first activation).
- **FR-005**: Administrators MUST be able to bulk-generate alphanumeric activation codes for any subject or exam, specifying the quantity and type.
- **FR-006**: System MUST provide export functionality for generated codes in CSV and Excel formats, including code value, linked entity, status, and generation date.
- **FR-007**: System MUST validate activation codes against the student's registered device identifier to prevent code sharing across devices.
- **FR-007a**: System MUST enforce rate limiting on activation code entry: after 5 failed attempts within a 15-minute window, activation is locked for that student/device pair. The lock auto-releases after the 15-minute window elapses. Failed attempts MUST be logged with student identifier, device identifier, and timestamp.
- **FR-008**: System MUST store and serve video and image content with support for byte-range requests enabling smooth seeking (forward/backward) and playback speed control.
- **FR-009**: System MUST enforce access control on all media content, verifying the student holds an active Subject Code for the requested content before serving any data.
- **FR-010**: System MUST support MCQ exam creation with configurable per-question timers, multiple-choice options, and designated correct answers.
- **FR-011**: System MUST support offline exam-taking with local progress preservation and server synchronization upon connectivity restoration.
- **FR-012**: System MUST provide real-time chat functionality between students and teachers with Sent, Delivered, and Read status indicators. A student may only initiate a conversation with a teacher who is assigned to a subject the student has activated. Teachers can respond to any student who has messaged them.
- **FR-013**: Chat MUST support image sharing, with images stored alongside other media content.
- **FR-014**: System MUST aggregate and display student analytics: exam performance (scores, attempts, pass/fail), video watch-time per subject, and activated subjects/exams.
- **FR-015**: System MUST capture and bind a hardware device identifier to each student's account, restricting all code activations and content access to that device. Only one active session is permitted per student at any time; a new login MUST invalidate any existing active session on the same device.
- **FR-016**: System MUST accept and evaluate client-reported security flags (screen recording detection, root/jailbreak detection) and log suspicious activity per student. Upon receiving a security flag, the system MUST immediately terminate the student's active session, requiring re-authentication. The flagged event is recorded for administrator review, who may then take permanent action (e.g., account suspension or ban).
- **FR-017**: System MUST verify the integrity and timestamps of offline exam submissions to detect tampering.
- **FR-018**: Administrators MUST be able to create, update, and delete subjects, exams, and video content from a centralized management interface.
- **FR-019**: Administrators MUST be able to revoke individual codes or entire batches, changing their status to Expired.
- **FR-020**: System MUST provide a real-time monitoring view showing active student count, ongoing exam sessions, recent activations, and code usage sales statistics.
- **FR-021**: System MUST support designating exam sections as "free" with a configurable per-student attempt limit, accessible without an activation code.
- **FR-022**: System MUST provide comprehensive interactive documentation for all exposed service interfaces.
- **FR-023**: Administrators MUST be able to reset a student's device lock to allow migration to a new device.
- **FR-024**: System MUST support subject bundles — named groupings of multiple subjects that can be unlocked with a single activation code.

### Key Entities

- **Student**: A registered user who activates codes and consumes academic content. Key attributes: unique identifier, name, email, registered device identifier, account status, registration date.
- **Teacher**: A user who creates academic content and communicates with students. Key attributes: unique identifier, name, email, assigned subjects.
- **Administrator**: A privileged user who manages all platform entities, generates/revokes codes, and monitors platform activity. Key attributes: unique identifier, name, email, role permissions.
- **Subject**: An academic course or topic containing video lessons and related materials. Key attributes: unique identifier, title, description, category, associated media, creation date.
- **Subject Bundle**: A named collection of multiple subjects sold/activated as a unit. Key attributes: unique identifier, bundle name, list of included subjects.
- **Exam**: An MCQ assessment linked to a subject with configurable settings. Key attributes: unique identifier, title, linked subject, list of questions, free-section flag, attempt limit for free sections.
- **Question**: An individual MCQ item within an exam. Key attributes: unique identifier, question text, list of answer options, correct answer, time limit in seconds.
- **Subject Activation Code**: A code granting access to a subject or bundle. Key attributes: unique identifier, code string, linked subject or bundle, status (Available/Used/Expired), generation date, batch identifier, activating student (if used), activation date, activation device.
- **Exam Activation Code**: A code granting access to a specific exam. Key attributes: unique identifier, code string, linked exam, usage type (single/multi), remaining uses (for multi-use), time-limit duration, first activation timestamp, status, activating student, activation device.
- **Media Asset**: A video or image stored for streaming or display. Key attributes: unique identifier, file name, content type, file size, associated subject, upload date.
- **Chat Message**: A message exchanged between a student and a teacher. Key attributes: unique identifier, sender, recipient, message text, optional image attachment, timestamp, delivery status (Sent/Delivered/Read).
- **Device Record**: A registered hardware identifier tied to a student's account. Key attributes: unique identifier, student, hardware fingerprint, registration date, active status.
- **Security Flag**: A logged event for suspicious client-side activity. Key attributes: unique identifier, student, flag type (screen recording/root/jailbreak), timestamp, device identifier, action taken.
- **Analytics Record**: Aggregated student activity data. Key attributes: student, exam scores history, video watch-time per subject, activation history.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Administrators can generate a batch of 1,000 activation codes and export them within 30 seconds.
- **SC-002**: Students can activate a code and begin accessing content within 10 seconds of code entry.
- **SC-003**: Video playback supports seeking to any position in the video within 2 seconds, with no rebuffering on stable connections.
- **SC-004**: 100% of activation attempts from non-registered devices are blocked and logged.
- **SC-005**: Chat messages are delivered to online recipients within 1 second of sending, with accurate status indicator progression.
- **SC-006**: Offline exam results synchronize successfully within 30 seconds of connectivity restoration, with 100% rejection rate for tampered submissions.
- **SC-007**: The platform supports at least 500 concurrent students streaming video and taking exams without degradation in response time or playback quality.
- **SC-008**: Student analytics dashboards accurately reflect all exam attempts, watch-time, and activations within 5 minutes of the activity occurring.
- **SC-009**: All exported code files (CSV/Excel) contain complete and accurate data matching the system records, with zero duplicate codes across all generated batches.
- **SC-010**: Administrators can view real-time platform activity (active users, ongoing exams, recent activations) with data refreshed at least every 10 seconds.
- **SC-011**: Free exam sections correctly enforce per-student attempt limits with 100% accuracy — no student can exceed the configured limit.
- **SC-012**: Device lock reset by an administrator takes effect immediately, allowing the student to register a new device on their next login.

## Assumptions

- **Student Registration**: Students self-register using email and password. There is no social login or SSO requirement for the initial version.
- **Subject Access Duration**: Subject access granted by an activated code is permanent. There is no automatic expiration or renewal cycle. Access can only be removed through explicit admin revocation.
- **External Distribution**: Activation codes are distributed and sold through external channels (e.g., physical cards, point-of-sale). No in-app payment or e-commerce system is in scope.
- **Teacher Role**: Teachers are a distinct user role created by administrators. Teachers can manage content for their assigned subjects and communicate with students, but cannot generate codes or access admin monitoring.
- **Device Identifier**: The client application is responsible for generating and transmitting a stable hardware identifier (e.g., a device fingerprint). The backend stores and validates this identifier but does not define how it is generated on the client.
- **Single Device Policy**: Each student account is locked to one device at a time. Only one active session is permitted per student — a new login invalidates any existing session. Device migration requires an admin-initiated reset.
- **Bundle Composition**: Subject bundles are curated by administrators and consist of a fixed list of subjects at creation time. Adding or removing subjects from a bundle does not retroactively affect students who already activated that bundle.
- **Chat Scope**: Chat is limited to one-on-one conversations between a student and a teacher. Students can only message teachers assigned to subjects the student has activated. Group chats or student-to-student messaging are out of scope.
- **Offline Exam Scope**: Offline exam support applies to the client application storing exam questions locally and submitting results upon reconnection. The backend provides the exam data for local caching and validates submissions.
- **Security Flags**: Screen recording and root/jailbreak detection are client-side responsibilities. The backend receives and logs these flags but does not implement client-side detection logic.
- **Data Retention**: Student records, exam results, and analytics are retained indefinitely. Code records are retained for auditing purposes even after expiration.
- **File Size Limits**: Video uploads are capped at 2 GB per file. Image uploads are capped at 20 MB per file. These limits can be configured by administrators.
- **Concurrency Target**: The platform targets 500 concurrent active users for the initial deployment, with architecture supporting horizontal scaling.
- **Localization**: The initial version supports a single language (Arabic, given the project context). Multi-language support is out of scope for v1.
- **Interactive Documentation**: All service interfaces will be documented with an interactive exploration tool accessible to developers.
