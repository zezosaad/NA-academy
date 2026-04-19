# Feature Specification: Admin Dashboard with shadcn

**Feature Branch**: `[002-admin-dashboard]`
**Created**: 2026-04-19
**Status**: Draft
**Input**: User description: "create a complete admin dashboard using shadcn and link it to the existing backend"

## Clarifications

### Session 2026-04-19

- Q: What user roles should have access to the admin dashboard? → A: Admin only (admin role has full dashboard access)
- Q: What actions can admin take on security flags? → A: Mark as reviewed/dismissed
- Q: What is the expected concurrent user scale for the dashboard? → A: Up to 1,000 concurrent users

## User Scenarios & Testing

### User Story 1 - View Platform Overview Dashboard (Priority: P1)

As an administrator, I want to see a real-time overview of platform activity so that I can monitor system health and user engagement.

**Why this priority**: This is the primary view administrators see upon login and provides immediate visibility into platform metrics.

**Independent Test**: Can be tested by loading the dashboard and verifying all statistic cards display values within 3 seconds of page load.

**Acceptance Scenarios**:

1. **Given** the user is authenticated as admin, **When** they navigate to the dashboard, **Then** they see four key metrics: active students, ongoing exams, recent activations count, and pending security flags
2. **Given** the dashboard loads successfully, **When** data is available, **Then** each metric displays its numeric value with a descriptive label

---

### User Story 2 - View Recent Activations (Priority: P2)

As an administrator, I want to see a list of recently activated codes so that I can track code usage patterns.

**Why this priority**: Enables administrators to monitor which activation codes have been used recently and by whom.

**Independent Test**: Can be tested by navigating to the activations section and verifying a list of at most 10 recent activations displays with student information.

**Acceptance Scenarios**:

1. **Given** dashboard data loads, **When** there are recent activations, **Then** a list of up to 10 activations displays with student name, email, and activation timestamp
2. **Given** no activations exist, **When** the dashboard loads, **Then** the section displays an empty state message

---

### User Story 3 - View Security Alerts (Priority: P2)

As an administrator, I want to see pending security flags so that I can investigate suspicious activity.

**Why this priority**: Security monitoring is essential for maintaining platform integrity.

**Independent Test**: Can be tested by viewing the security flags section and verifying unreviewed flags display with student information.

**Acceptance Scenarios**:

1. **Given** there are unreviewed security flags, **When** the dashboard loads, **Then** up to 20 flags display with student details and timestamp
2. **Given** the user views a security flag, **When** they take action, **Then** the flag is marked as reviewed

---

### User Story 4 - Auto-Refresh Dashboard Data (Priority: P3)

As an administrator, I want dashboard data to refresh automatically so that I see current information without manual refresh.

**Why this priority**: Reduces the need for manual page reloads and ensures administrators always see near-real-time data.

**Independent Test**: Can be tested by leaving the dashboard open and verifying data updates at regular intervals.

**Acceptance Scenarios**:

1. **Given** the dashboard is open, **When** 60 seconds pass, **Then** the data refreshes automatically
2. **Given** a refresh is in progress, **When** user clicks refresh, **Then** the refresh is queued until current refresh completes

---

### Edge Cases

- What happens when the backend API is unreachable?
- How does the system handle authentication token expiration?
- What displays when there are no metrics to show (all zeros/null)?
- How does the interface handle very large numbers (e.g., 10,000+ active students)?

## Requirements

### Functional Requirements

- **FR-001**: System MUST display four key platform metrics: active students count, ongoing exams count, recent activations list, and pending security flags
- **FR-002**: System MUST fetch dashboard data from the existing `/admin/dashboard` endpoint
- **FR-003**: System MUST display recent activations with student name, email, and activation timestamp
- **FR-004**: System MUST display unreviewed security flags with student details and timestamp
- **FR-005**: System MUST show loading indicators while data is being fetched
- **FR-006**: System MUST display user-friendly error messages when the API is unreachable
- **FR-007**: System MUST auto-refresh dashboard data every 60 seconds
- **FR-008**: System MUST gracefully handle authentication failures by redirecting to login
- **FR-009**: System MUST allow admin to review and dismiss security flags
- **FR-010**: System MUST update security flag status when admin marks it as reviewed

### Key Entities

- **DashboardMetric**: Represents a single statistic (label, value, change indicator)
- **Activation**: Represents an activation code usage event (student, timestamp, code details)
- **SecurityFlag**: Represents a flagged security event (student, description, timestamp, status)

## Success Criteria

### Measurable Outcomes

- **SC-001**: Dashboard loads and displays all metrics within 3 seconds on first load
- **SC-002**: Users can view all dashboard sections without page errors
- **SC-003**: Auto-refresh occurs every 60 seconds without user intervention
- **SC-004**: Error states display within 2 seconds of API failure
- **SC-005**: Dashboard supports up to 1,000 concurrent admin users without degradation

## Assumptions

- The existing `/admin/dashboard` endpoint remains available and returns the expected data structure
- shadcn components work in a web environment (the frontend is mobile-focused with Expo, so a new web admin interface will be built)
- Authentication is handled via existing JWT tokens passed to API calls
- The admin dashboard will be a new standalone web application, not integrated into the existing mobile app
- The backend returns the same data structure currently defined in the admin service