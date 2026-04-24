# Quickstart — NA-Academy Mobile App (local dev)

Target: a new engineer goes from clone to a working "unlock a subject" happy-path on a real device (or simulator) in under 10 minutes.

## Prerequisites

- **Flutter SDK** 3.24+ (Dart 3.11+). Confirm: `flutter --version`.
- **Node.js** 20+ and **npm** 10+.
- **MongoDB** 7+ running locally (or a reachable Atlas URI).
- **Xcode** 15+ (for iOS simulator) and/or **Android Studio** with an AVD (API 26+).
- **MailHog** (optional, for the password-reset flow): `docker run -p 8025:8025 -p 1025:1025 mailhog/mailhog`.

## 1. Backend (`back/`)

```bash
cd back
npm install
cp .env.example .env   # fill in values
# minimum env:
#   MONGODB_URI=mongodb://localhost:27017/na-academy
#   JWT_SECRET=<any long random string>
#   JWT_ACCESS_EXPIRES_IN=15m
#   JWT_REFRESH_EXPIRES_IN=30d
#   MAIL_HOST=localhost
#   MAIL_PORT=1025
#   MAIL_FROM=no-reply@naacademy.local
npm run start:dev      # boots on :3000 by default
```

Visit `http://localhost:3000/api` to confirm Swagger is up.

### Seed a student + a subject + an activation code

Either use the admin dashboard at `admin-dashboard/` (run `npm run dev` there and sign in as admin via `POST /auth/register-admin`), or hit the API directly:

```bash
# 1. Register an admin
curl -X POST http://localhost:3000/auth/register-admin \
  -H 'content-type: application/json' \
  -d '{"name":"Admin","email":"admin@na.local","password":"Passw0rd!","hardwareId":"admin-dev"}'

# 2. Register a student
curl -X POST http://localhost:3000/auth/register \
  -H 'content-type: application/json' \
  -d '{"name":"Test Student","email":"stu@na.local","password":"Passw0rd!","hardwareId":"stu-dev"}'

# 3. Create a subject (use the admin token)
curl -X POST http://localhost:3000/subjects \
  -H 'authorization: Bearer <admin-access-token>' \
  -H 'content-type: application/json' \
  -d '{"title":"Calculus II","description":"Integrals and series","teacherId":"<an-admin-or-teacher-id>"}'

# 4. Generate subject activation codes
curl -X POST http://localhost:3000/activation-codes/subject/generate \
  -H 'authorization: Bearer <admin-access-token>' \
  -H 'content-type: application/json' \
  -d '{"subjectId":"<subject-id>","count":5}'
# → response contains a batchId; list the codes:
curl -H 'authorization: Bearer <admin-access-token>' \
  http://localhost:3000/activation-codes/batch/<batchId>?page=1&limit=5
# copy one code string (e.g. "NA24CH") for the app test.
```

## 2. Mobile app (`na_app/`)

```bash
cd na_app
flutter pub get
```

Configure the API base URL. The app reads `API_BASE_URL` from a dart-define:

```bash
# iOS simulator on the same machine:
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000

# Android emulator on the same machine (10.0.2.2 is the host loopback):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Physical device on the same Wi-Fi:
flutter run --dart-define=API_BASE_URL=http://<your-lan-ip>:3000
```

The Socket.IO chat namespace reuses the same base URL — no second setting needed.

## 3. Walk the P1 happy-path

1. Launch app → Splash → Onboarding pager → tap **Get started**.
2. On Register, enter `Test Student` / `stu@na.local` / `Passw0rd!` and accept terms. The app should land on the Subjects tab with every subject shown as **locked**.
3. Tap **Enter code**. Type the code you generated in step 1.4 (e.g. `NA24CH`). Watch the Code Accepted → unlocking transition (verifying → linking → downloading).
4. You should land on the Subject detail screen for Calculus II.
5. Open any Active lesson to confirm media streams.

## 4. Walk the P1 exam path

1. As admin, `POST /exams` and then `POST /activation-codes/exam/generate` to seed an exam and a code.
2. In the app, go to Exams → tap the exam → enter the exam code → tap **Unlock and start exam**.
3. Answer every question. The app calls `POST /exams/sessions/:id/answer` on every tap — tail `back/`'s logs to confirm.
4. Submit. The Result screen shows score, score ring, and per-question review.

## 5. Walk the password-reset path (optional)

Requires MailHog running (step 0).

1. On Login, tap **Forgot password?**.
2. Enter `stu@na.local` → "Check your inbox" state.
3. Open MailHog at `http://localhost:8025` and click the reset link in the email.
4. The app deep-links to the Reset Password screen; enter a new password; sign-in happens on success.

## 6. Walk the P2 chat path (when B5 backend gap lands)

1. Seed a teacher user (`POST /auth/register`, then an admin promotes via the users controller when that lands, or create a teacher via the `register-admin` endpoint with `role: 'teacher'` body override in dev).
2. Attach that teacher to the subject the student unlocked.
3. Open the Chat tab on the student app — the tutor thread should appear.
4. On a second device (simulator OK) sign in as the tutor (the `front/` or a separate run of `na_app` with a different `hardwareId`) and exchange messages.

## 7. Run checks before committing

```bash
cd back && npm run lint && npm test
cd na_app && flutter analyze && flutter test
```

Both MUST pass before opening a PR (per the constitution's Technology & Quality Standards).

## Troubleshooting

- **"You need to activate this exam code before starting the full exam" (403)** on `POST /exams/:id/start` — make sure you hit `POST /activation-codes/activate` with the exam code first, AND that the `hardwareId` on the activate call matches the one stored in the app's secure storage. If you reinstalled the app, the stored UUID regenerated and the code is now locked to the old install. Ask an admin to run `PATCH /users/:id/device-reset`.
- **Socket.IO disconnects immediately** — verify the Dio-issued access token is still valid; the gateway's `handleConnection` `jwtService.verify` throws on any signature/expiry problem.
- **Password-reset email never arrives** — in dev, check MailHog at `:8025`. In prod, check `MAIL_*` env vars and the `MailModule` logs.
- **Subjects list shows everything as locked even after activating** — ensure backend gap **B2** (`GET /subjects` adds `isUnlocked`) has landed. Until B2 merges, the client has no way to render the unlocked state; a temporary workaround is to derive unlock state from a separate per-user activation-codes endpoint, but the canonical fix is B2.
