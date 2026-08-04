# MindBridge — Flutter Setup Guide

## Prerequisites

| Tool | Minimum version |
|------|----------------|
| Flutter SDK | 3.24.0 |
| Dart SDK | 3.4.0 |
| Android Studio / Xcode | Latest stable |
| Firebase CLI | 13.x |

Verify your environment:
```bash
flutter doctor -v
dart --version
```

---

## 1. Install dependencies

```bash
flutter pub get
```

---

## 2. Run code generation

This project uses **Riverpod Generator**, **Freezed**, and **JSON Serializable**.
You must run code generation before the project will compile:

```bash
dart run build_runner build --delete-conflicting-outputs
```

To watch for changes during development:
```bash
dart run build_runner watch --delete-conflicting-outputs
```

Generated files (`*.g.dart`, `*.freezed.dart`) are excluded from version control — always run the above after a fresh clone or pulling new model changes.

---

## 3. Firebase setup

### 3a. Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 3b. Create a Firebase project
Go to [Firebase Console](https://console.firebase.google.com/), create a project named **mindbridge-prod** (and optionally **mindbridge-dev** for staging).

### 3c. Configure the app
```bash
flutterfire configure \
  --project=mindbridge-prod \
  --platforms=android,ios
```

This generates `lib/firebase_options.dart`. Import and call it in `main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Inside main():
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### 3d. Enable services in Firebase Console
- **Authentication** → Email/Password (+ Anonymous if needed)
- **Cloud Messaging** (push notifications)

---

## 4. Environment variables

API URLs are injected at build time via `--dart-define`:

```bash
# Development
flutter run \
  --dart-define=API_BASE_URL=https://dev-api.mindbridge.gr/api/v1 \
  --dart-define=WS_BASE_URL=wss://dev-api.mindbridge.gr/api/v1

# Production build (Android AAB)
flutter build appbundle \
  --dart-define=API_BASE_URL=https://api.mindbridge.gr/api/v1 \
  --dart-define=WS_BASE_URL=wss://api.mindbridge.gr/api/v1
```

For local development against a local backend:
```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 \
  --dart-define=WS_BASE_URL=ws://10.0.2.2:8000/api/v1
```
(`10.0.2.2` routes to `localhost` from the Android emulator.)

### VS Code launch config

Create `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "MindBridge (dev)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1",
        "--dart-define=WS_BASE_URL=ws://10.0.2.2:8000/api/v1"
      ]
    }
  ]
}
```

### Android Studio run config

Go to **Edit Configurations → Additional run args** and add:
```
--dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 --dart-define=WS_BASE_URL=ws://10.0.2.2:8000/api/v1
```

---

## 5. Assets & fonts

Place files in the following directories before building:

```
assets/
  images/       → PNG/SVG illustrations (logo, onboarding images)
  animations/   → Lottie JSON files (breathing guide, loading states)
  audio/        → MP3/AAC files (guided meditation audio)
  fonts/        → .ttf font files
```

The `pubspec.yaml` already declares these asset paths. Add individual font weights under the `fonts:` section as needed:
```yaml
fonts:
  - family: MindBridge
    fonts:
      - asset: assets/fonts/MindBridge-Regular.ttf
      - asset: assets/fonts/MindBridge-Medium.ttf  weight: 500
      - asset: assets/fonts/MindBridge-Bold.ttf    weight: 700
```

---

## 6. Android configuration

### Minimum SDK
`android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdk 23        // required by flutter_secure_storage
        targetSdk 34
    }
}
```

### Permissions
`android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<!-- Push notifications (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

---

## 7. iOS configuration

### Minimum deployment target
`ios/Podfile`:
```ruby
platform :ios, '13.0'
```

### Permissions
`ios/Runner/Info.plist` — add:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>MindBridge χρησιμοποιεί το μικρόφωνο για φωνητικές σημειώσεις ημερολογίου.</string>
<key>NSUserNotificationUsageDescription</key>
<string>Ειδοποιήσεις για τις καθημερινές σας ασκήσεις.</string>
```

---

## 8. Run the app

```bash
# Android emulator / device
flutter run

# iOS simulator
flutter run -d "iPhone 15 Pro"

# Release mode (performance testing)
flutter run --release
```

---

## 9. Build for distribution

### Android (Play Store)
```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.mindbridge.gr/api/v1 \
  --dart-define=WS_BASE_URL=wss://api.mindbridge.gr/api/v1
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (App Store)
```bash
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://api.mindbridge.gr/api/v1 \
  --dart-define=WS_BASE_URL=wss://api.mindbridge.gr/api/v1
# Output: build/ios/archive/Runner.xcarchive
```

---

## 10. Project structure overview

```
lib/
├── main.dart                  # Entry point
├── app.dart                   # MaterialApp.router
├── core/
│   ├── constants/             # AppColors, AppSpacing
│   ├── network/               # Dio client, interceptors, ApiException
│   ├── routing/               # GoRouter + AppRoutes
│   ├── storage/               # SecureStorage
│   ├── theme/                 # AppTheme (light + dark)
│   └── utils/                 # Extensions (ContextX, DateTimeX, etc.)
├── features/
│   ├── auth/                  # Login, Register, AuthNotifier, AuthRepository
│   ├── chat/                  # WebSocket streaming chat
│   ├── dashboard/             # Home screen, mood chart
│   ├── exercises/             # Exercise library with category filter
│   ├── assessment/            # PHQ-9 / GAD-7 / PSS-10
│   └── onboarding/            # 3-step onboarding flow
└── shared/
    └── widgets/               # MbButton, MbCard, MbTextField, CrisisBanner, MainScaffold
```

---

## Troubleshooting

| Error | Fix |
|-------|-----|
| `Could not find generator for file` | Run `build_runner build --delete-conflicting-outputs` |
| `MissingPluginException (flutter_secure_storage)` | Run `flutter clean && flutter pub get`, rebuild |
| `firebase_options.dart not found` | Run `flutterfire configure` (step 3c) |
| `Gradle build failed minSdk` | Set `minSdk 23` in `android/app/build.gradle` |
| WebSocket `Connection refused` | Check `--dart-define=WS_BASE_URL` and that the backend is running |
| `Bad state: Stream has already been listened to` | The WebSocket channel is being subscribed twice — ensure `ChatNotifier.dispose()` cancels the subscription |

---

## Key dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` + `riverpod_generator` | State management + code-gen providers |
| `go_router` | Declarative routing + deep links |
| `dio` | HTTP client with auth interceptor + retry |
| `web_socket_channel` | Streaming AI responses |
| `flutter_secure_storage` | JWT tokens (Keychain / EncryptedSharedPrefs) |
| `hive_flutter` | Offline-first local cache |
| `fl_chart` | Mood trend charts |
| `freezed` | Immutable state models |
| `lottie` | Breathing / loading animations |
| `firebase_messaging` | Push notifications |
| `url_launcher` | Crisis helpline `tel:` links |
