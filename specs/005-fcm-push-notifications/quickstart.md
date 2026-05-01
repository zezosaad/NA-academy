# Quickstart — Push Notifications & In-App Inbox (FCM)

**Date**: 2026-05-01
**Feature**: `005-fcm-push-notifications`

This is the dev-loop walkthrough: how to send a notification end-to-end on a freshly-built local environment. Read this if you've just checked out the branch and want to verify the feature works before opening a PR.

> **Terminology bridge**: the spec talks about "courses". The codebase calls them **subjects** (the existing `Subject` collection). The composer and contract DTOs use `subject` as the canonical name — see `research.md` Decision 3.

---

## 1. Prerequisites

- Node 20+, MongoDB running (existing project setup).
- Flutter 3.24+ with Android SDK or Xcode set up (existing).
- A Firebase project with Cloud Messaging enabled. Two Firebase apps (one Android, one iOS) registered with your local debug bundle IDs:
  - Android: `package_name = com.naacademy.app` (whatever `na_app/android/app/build.gradle` declares)
  - iOS: `bundle_id = com.naacademy.app` plus an APNs auth key uploaded under the iOS app's Cloud Messaging settings.
- A Firebase **service account** JSON exported from the Firebase Console (`Project settings → Service accounts → Generate new private key`).

---

## 2. One-time backend config

1. Place the service-account JSON outside the repo, e.g. `~/.secrets/na-fcm-dev.json`. **Do not commit it.**
2. Add to `back/.env.development` (gitignored):
   ```env
   FIREBASE_SERVICE_ACCOUNT_PATH=/Users/you/.secrets/na-fcm-dev.json
   FIREBASE_PROJECT_ID=na-academy-dev
   ```
   Or, if you prefer the JSON-in-env style:
   ```env
   FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
   ```
3. From `back/`: `npm install firebase-admin @nestjs/schedule`. (`@nestjs/schedule` only if not already installed — it's needed by `retention.service.ts`.)
4. Restart the backend. On boot, `notifications.module.ts` initializes `firebase-admin` from whichever env var is present and logs `Firebase Messaging initialized for project=na-academy-dev` (or fails fast with a clear error).

---

## 3. One-time mobile config

1. Drop the Firebase config files into the Flutter app:
   - `na_app/android/app/google-services.json` (gitignored — track an `.example` or per-developer override).
   - `na_app/ios/Runner/GoogleService-Info.plist` (gitignored).
2. From `na_app/`:
   ```bash
   flutter pub add firebase_core firebase_messaging flutter_local_notifications
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs   # for freezed/drift codegen
   ```
3. Android (`android/app/build.gradle`): apply `com.google.gms.google-services` plugin per the `firebase_core` setup docs.
4. iOS (`ios/Runner.xcworkspace`): enable the **Push Notifications** and **Background Modes → Remote notifications** capabilities. Confirm the APNs key is wired up in the Firebase Console.
5. `lib/main.dart` already calls `await runZonedGuarded(...)` around `runApp`; insert the new `FirebaseBootstrap.initialize()` call **before** `runApp()`. This handles `Firebase.initializeApp()` and registers the background message handler.

---

## 4. Verify the dev loop

### 4a. Send a broadcast from the dashboard

1. Start backend: `cd back && npm run start:dev`.
2. Start dashboard: `cd admin-dashboard && npm run dev`. Log in as an admin.
3. Navigate to **Notifications → Send**.
4. Compose:
   - **Title**: `Live Q&A starts in 10 minutes`
   - **Body**: `Join from the home screen`
   - **Audience**: `All users`
5. Click **Send**. The dashboard shows a success toast and routes you to the **History** tab; the new entry is at the top with `Delivered: 0 / Pending: N` until FCM round-trips finish (usually <5 s).

### 4b. Receive on Flutter

1. Build the app on a real device or emulator: `cd na_app && flutter run`.
2. Log in as a student account that exists in the dashboard's user database.
3. The first launch presents the OS notification permission prompt — accept.
4. Send the broadcast from step 4a *while the app is in the background*.
   - Expected: an OS push appears within ~5 s. Tap it. The app opens to the **Notifications** inbox; the message is visible and marked unread.
5. Send another broadcast *while the app is in the foreground*.
   - Expected: a parchment-palette in-app banner slides in (or fades in if reduced-motion is on), auto-dismisses in 5 s. The bell badge on Home increments. The inbox shows the new message.
6. Send a third broadcast *while the app is force-killed*.
   - Expected: an OS push appears. Tapping it cold-launches the app and lands on the inbox.

### 4c. Check delivery state on the dashboard

1. Back in the dashboard, click the broadcast entry from step 4a's History list.
2. The detail drawer shows the per-recipient list with each user's state — `delivered` for the test student, `failed` (with `no-active-token`) for any users not yet registered.

---

## 5. Targeted send (subject)

1. As a teacher who owns the subject "Algebra 101", log into the dashboard.
2. Navigate to **Notifications → Send**. The audience picker is locked to **Subject → Algebra 101** (no "All users", no arbitrary user picker — Decision 5 / FR-008).
3. Compose and send. Only enrolled-student devices receive the push.

---

## 6. Inspecting the inbox state

- Bell-icon badge on Home reflects unread count, updates in real time.
- Open the inbox: rows show title, body snippet, and relative timestamp (e.g., "2 min ago").
- Tap a row → detail page → message marked read; badge decrements.
- "Mark all as read" action available from the inbox app bar.
- Toggle airplane mode and reopen the inbox: previously-cached items are visible offline (FR-019). Mark-as-read is queued and replays when connectivity returns.

---

## 7. Common issues & how to fix

| Symptom | Likely cause | Fix |
|---|---|---|
| `Firebase Messaging: Failed to initialize` on backend boot | Service-account JSON path/env mismatch | Confirm `FIREBASE_SERVICE_ACCOUNT_PATH` resolves to a readable file. |
| iOS device never gets pushes | APNs key missing in Firebase Console **or** capability not enabled in Xcode | Re-check both. The token is registered but FCM has no path to APNs. |
| Sends say "delivered" but device shows nothing | OS notification permission revoked | The inbox still holds the message. Re-grant permission in OS settings. |
| Repeated tap on "Send" creates duplicate rows | `Idempotency-Key` header missing | Confirm `notifications.api.ts` generates a UUID per submit. |
| `403 audience-forbidden` when teacher sends to "Algebra 101" | The teacher is not the `Subject.createdBy` for that subject | The current ownership rule is strict — admin must (re-)assign ownership. |
| Push works once then stops | FCM token rotated; client didn't `PATCH /me/push-tokens/:id` | Confirm `onTokenRefresh` listener is wired in `push_token_registrar.dart`. |

---

## 8. Verifying the constitution gates manually before PR

- **Principle I**: send buttons are pill-shaped, not blue rectangles; the inbox row uses Inter at body-size with Parchment background; the foreground banner does not flash neon teal.
- **Principle V**: every interactive element on the inbox screen has a hit-target ≥ 44×44 pt (use Flutter Inspector's "Show pointer hit areas").
- **Constitution Check is re-evaluated** in `plan.md` and continues to PASS after the design artifacts in `data-model.md` and `contracts/` are reviewed; no design choices made in Phase 1 introduced new violations.

---

## 9. Next step

After this quickstart passes locally, run `/speckit.tasks` to break the plan into task units and start the implementation cycle.
