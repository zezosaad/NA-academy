# NA-Academy Backend

NestJS 11 API server for the NA-Academy platform.

## Environment Variables

### Core

| Variable | Required | Description |
|---|---|---|
| `MONGODB_URI` | yes | MongoDB connection string |
| `JWT_SECRET` | yes | Secret for JWT token signing |
| `PORT` | no | Server port (default `3000`) |

### Firebase (Push Notifications)

| Variable | Required | Description |
|---|---|---|
| `FIREBASE_PROJECT_ID` | yes | Firebase project ID (e.g. `na-academy-dev`) |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | one of* | Absolute path to the Firebase service-account JSON file |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | one of* | Inline Firebase service-account JSON (alternative to `PATH`) |

\* Provide **either** `FIREBASE_SERVICE_ACCOUNT_PATH` **or** `FIREBASE_SERVICE_ACCOUNT_JSON`. The server fails fast at boot if neither is set when the notifications module is loaded.

### Mail

| Variable | Required | Description |
|---|---|---|
| `MAIL_HOST` | no | SMTP host (default `localhost`) |
| `MAIL_PORT` | no | SMTP port (default `1025`) |
| `MAIL_USER` | no | SMTP username |
| `MAIL_PASS` | no | SMTP password |
| `MAIL_FROM` | no | From address (default `no-reply@naacademy.local`) |

## Development

```bash
npm install
npm run start:dev
```

Swagger UI available at `http://localhost:3000/api`.
