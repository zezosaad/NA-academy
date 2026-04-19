# Data Model: Admin Dashboard

## Entities

### DashboardMetric

Represents a single platform statistic displayed on the dashboard.

| Field | Type | Description |
|-------|------|-------------|
| label | string | Display label for the metric (e.g., "Active Students") |
| value | number | Current count/value |
| change | number (optional) | Change indicator (+/- from previous period) |

---

### Activation

Represents a recently activated code event.

| Field | Type | Description |
|-------|------|-------------|
| id | string | Unique identifier |
| activatedBy | object | Student who activated (name, email) |
| activatedAt | datetime | When the code was activated |

---

### SecurityFlag

Represents a security alert that needs review.

| Field | Type | Description |
|-------|------|-------------|
| id | string | Unique identifier |
| studentId | object | Student associated (name, email) |
| description | string | What triggered the flag |
| createdAt | datetime | When the flag was created |
| actionTaken | enum | NONE, REVIEWED, DISMISSED |

---

### DashboardResponse

API response from `/admin/dashboard` endpoint.

| Field | Type | Description |
|-------|------|-------------|
| activeStudentsNow | number | Count of active sessions |
| ongoingExams | number | Count of exams in progress |
| recentActivations | Activation[] | List of recent activations (max 10) |
| securityFlags | SecurityFlag[] | List of unreviewed flags (max 20) |

---

## Validation Rules

- All numeric values must be >= 0
- datetime fields must be valid ISO 8601 format
- actionTaken must be one of: NONE, REVIEWED, DISMISSED

---

## Relationships

- DashboardMetric: Derived from DashboardResponse fields
- Activation: Linked to User via activatedBy
- SecurityFlag: Linked to User via studentId

---

**Generated**: 2026-04-19