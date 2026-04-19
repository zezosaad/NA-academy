# Admin Dashboard API Contract

## Endpoint: GET /api/admin/dashboard

**Authentication**: JWT Bearer Token (required)

**Authorization**: Requires `admin` role

---

### Response

```json
{
  "activeStudentsNow": 42,
  "ongoingExams": 5,
  "recentActivations": [
    {
      "_id": "activation-id",
      "activatedBy": {
        "name": "John Doe",
        "email": "john@example.com"
      },
      "activatedAt": "2026-04-19T10:30:00Z"
    }
  ],
  "securityFlags": [
    {
      "_id": "flag-id",
      "studentId": {
        "name": "Jane Smith",
        "email": "jane@example.com"
      },
      "description": "Multiple failed login attempts",
      "createdAt": "2026-04-19T09:00:00Z",
      "actionTaken": "NONE"
    }
  ]
}
```

---

### Error Responses

| Status | Description |
|--------|-------------|
| 401 | Unauthorized - Invalid or missing JWT token |
| 403 | Forbidden - User is not admin |
| 500 | Internal server error |

---

**Generated**: 2026-04-19