# hivtb_mobile

Flutter mobile client for the **HIV & TB Patient Monitoring System** (Dream Medical Center, Rwanda).
Companion app to the [`hivtb-monitoring-system`](../hivtb-monitoring-system) Spring Boot backend and
[`hivtb-web`](../hivtb-web) Next.js dashboard.

## Tech stack

- **State management:** Riverpod
- **Navigation:** go_router
- **HTTP:** Dio (with JWT auto-attach + refresh-token interceptor)
- **Secure storage:** flutter_secure_storage (JWT tokens)
- **Charts:** fl_chart
- **Push notifications:** Firebase Cloud Messaging + flutter_local_notifications
- **Offline cache:** sqflite
- **i18n:** custom `AppL10n` — English, French, Kinyarwanda

## Roles supported

The app is feature-first, organized under `lib/features/`:

- `auth` — login, JWT/refresh handling, FCM token registration
- `patient` — dashboard, dose confirmation, treatment progress, dose history
- `chw` — home dashboard, my patients, priority list, LTFU tracing, record home visit, screen patient, alerts, reports
- `admin` — admin-facing screens
- `shared` — widgets/components shared across roles

## Prerequisites

- Flutter SDK (3.x), matching `environment.sdk: '>=3.0.0 <4.0.0'` in `pubspec.yaml`
- A running instance of the backend (`hivtb-monitoring-system`), local or deployed
- For push notifications: `android/app/google-services.json` (Firebase config — see below)

## Running locally

```bash
flutter pub get
```

The backend base URL is injected at build/run time via `--dart-define=BASE_URL=...`
(see `lib/core/network/api_endpoints.dart`). If omitted, it defaults to
`http://10.0.2.2:8080` (Android emulator's alias for the host machine's `localhost`).

```bash
# Run against a local backend (Android emulator)
flutter run --dart-define=BASE_URL=http://10.0.2.2:8080

# Run against the deployed backend
flutter run --dart-define=BASE_URL=https://hivtb-rw-api.onrender.com
```

For a **physical device**, use your machine's LAN IP instead of `10.0.2.2`, or point at the
deployed Render backend.

## Building an APK

```bash
flutter build apk --debug --dart-define=BASE_URL=https://hivtb-rw-api.onrender.com
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`. The `--release` build type is signed with
the debug key (see `android/app/build.gradle.kts`) so `flutter run --release` also works without
extra signing setup.

## Firebase Cloud Messaging (push notifications)

The app initializes Firebase in `main.dart` and registers the device's FCM token with the backend
(`POST /api/auth/fcm-token`) after login.

To enable push notifications:

1. Create/select the Firebase project (`hiv-tb-monitor`) and register an Android app with package
   name `com.example.hivtb_mobile`.
2. Download `google-services.json` and place it at `android/app/google-services.json` (not
   committed — see `.gitignore`).
3. Ensure the backend has `FIREBASE_SERVICE_ACCOUNT_JSON` set (see backend `.env.example`).

If `google-services.json` is missing, Firebase init fails silently and the app still runs without
push notifications.

### Known Gradle/Kotlin note

If the Flutter project and the Pub cache live on different drives (e.g. project on `F:\` and
pub cache on `C:\`), Kotlin's incremental compiler can throw
`IllegalArgumentException: this and base files have different roots`. This is worked around with
`kotlin.incremental=false` in `android/gradle.properties`.

## Project structure

```
lib/
├── main.dart              # App entry point — Firebase init, FCM init
├── core/
│   ├── constants/         # Routes, colors, strings, l10n
│   ├── l10n/               # App localization (EN/FR/RW)
│   ├── network/            # ApiClient (Dio), API endpoint constants
│   ├── notifications/      # FCM service
│   ├── router/             # go_router configuration
│   ├── storage/            # Secure storage (JWT tokens)
│   ├── theme/               # Teal + Coral design system
│   └── utils/
├── features/
│   ├── auth/
│   ├── patient/
│   ├── chw/
│   ├── admin/
│   └── shared/
└── shared/                  # Cross-feature shared widgets
```
