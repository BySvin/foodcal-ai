# FoodCal AI

**[Live demo →](https://foodcal-ai-app.web.app)**

A clean, minimalist calorie tracker built with Flutter and Firebase — fast food logging, a Notion/Apple Health-inspired interface, Material 3, light & dark mode, on Android, iOS, and Web from a single codebase.

## About this project

FoodCal AI is a solo portfolio project, built end-to-end by a final-year Diploma in Information Technology (Software Development) student — architecture, Firebase backend, and UI design all done independently — to demonstrate a production-shaped Flutter app rather than a tutorial clone. It covers the full surface area of a real product: authentication, a multi-step onboarding flow that computes personalized calorie/macro targets, live-updating dashboards, food logging with search and favorites, water and weight tracking, a 30-day history view, and profile/settings.

A few things worth noting if you're reviewing the code:

- **Feature-first clean architecture** — every feature is self-contained with its own `data`/`domain`/`presentation` layers (see [docs/architecture.md](docs/architecture.md)), and each one has a companion doc in [docs/features/](docs/features/) covering its data model, providers, and states in detail.
- **Riverpod done reactively** — auth and profile state flow through `StreamProvider`s watched directly, not read once and cached, so the UI (including router redirects) updates immediately on sign-in/out rather than on next rebuild.
- **Firestore modeled for atomicity, not just structure** — daily water/weight logs use deterministic `{uid}_{date}` document IDs so "log today" is a natural upsert, and quick-add water uses `FieldValue.increment` for race-free concurrent writes.
- **85 tests, offline** — repository and widget tests run against `fake_cloud_firestore`/`firebase_auth_mocks`, no real Firebase project required to develop or CI against.
- **A visual identity, not just Material defaults** — a gradient progress ring (the app's signature element, echoed in the app icon), a deliberate Inter/Space Grotesk type pairing, and orchestrated entrance motion on the dashboard.

This is the **V1 (MVP)** release, deliberately scoped to exclude AI features, barcode scanning, push notifications, and payments — see [docs/architecture.md](docs/architecture.md) for the architecture overview.

## Features

- **Authentication** — email/password, Google Sign-In, password reset, email verification
- **Onboarding** — a 6-step guided flow computing your daily calorie/macro/water targets (Mifflin-St Jeor)
- **Dashboard** — calorie progress ring, macro bars, water card, all live-updating
- **Food Logging** — catalog search, manual entries, favorites, recent foods, meal-sectioned log
- **Water Tracker** — one-tap quick-add against a daily goal, with one-step undo
- **Weight Tracking** — daily log with a trend chart
- **Daily History** — the last 30 days, with full per-day detail
- **Profile & Settings** — edit info/goals, light/dark/system theme, sign out

## Tech stack

Flutter · Dart · Riverpod · Go Router · Material 3 · Firebase (Auth, Firestore, Analytics, Crashlytics) · fl_chart

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.44+) and Dart 3.12+
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) (`dart pub global activate flutterfire_cli`)
- A Google account with access to the [Firebase Console](https://console.firebase.google.com/)
- Node.js (only needed if you plan to re-seed the food catalog — see below)

## Setup (fresh clone)

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Connect a Firebase project

This app needs its own Firebase project — `lib/firebase_options.dart` in this repo is tied to the original project and won't work for a new clone until you regenerate it.

```bash
firebase login
firebase projects:create your-project-id
flutterfire configure --project=your-project-id
```

`flutterfire configure` will ask which platforms to set up (select Android, iOS, and Web) and will regenerate `lib/firebase_options.dart` plus drop `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` into place. These files are safe to commit — they're client config protected by Firebase Security Rules, not secrets.

### 3. Enable Firebase services

In the [Firebase Console](https://console.firebase.google.com/) for your project:

1. **Authentication → Sign-in method** → enable **Email/Password**, and **Google** if you want that button working (it needs a support email set).
2. **Firestore Database → Create database** → production mode, pick a region.

For Google Sign-In on Android, you'll also need to register your debug keystore's SHA-1 fingerprint:

```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Add the SHA-1 under **Project Settings → your Android app → Add fingerprint**, then re-download `google-services.json` and replace the one in `android/app/`.

### 4. Deploy security rules and indexes

```bash
firebase use your-project-id
firebase deploy --only firestore:rules,firestore:indexes
```

### 5. Seed the food catalog

Food search returns nothing until the shared `foods` collection is populated:

```bash
cd tool/seed
npm install
```

Download a service account key (Firebase Console → **Project Settings → Service Accounts → Generate new private key**) and save it as `tool/seed/serviceAccountKey.json` — this file is gitignored and must never be committed, it grants full database access.

```bash
node seedFoods.js
```

This seeds ~184 curated common foods. Re-running it is safe (each food has a stable id, so it upserts rather than duplicating).

### 6. Run the app

```bash
flutter run              # pick a connected device/emulator
flutter run -d chrome    # web
```

## Running tests

```bash
flutter analyze   # static analysis — should report no issues
flutter test      # unit + widget tests
```

Tests use `fake_cloud_firestore` and `firebase_auth_mocks`, so they run fully offline without touching a real Firebase project.

## Project structure

Feature-first clean architecture — see [docs/architecture.md](docs/architecture.md) for the full rationale.

```
lib/
├── core/           # theme, shared widgets, error types, pure utilities, base Firebase providers
├── routing/        # Go Router config, auth/onboarding redirect guard, responsive shell
└── features/       # one folder per feature, each with data/ domain/ presentation/
```

## Known environment notes

These were specific to the machine this project was originally built on — they may not apply to yours, but are documented here in case they do:

- If your Flutter SDK is installed under a path containing a space, `flutter test`'s native-assets build hook can fail (`objective_c` package, Java compile step). `pubspec.yaml` pins `path_provider_foundation` to 2.5.1 to sidestep this; see the comment there for details and how to remove the pin once it's no longer needed.
- The Firestore Emulator requires a working `java` on `PATH`. If `firebase emulators:start` fails with a Java error, check `java -version` resolves to a real JDK — a stale/broken `PATH` entry pointing at a nonexistent install is a common cause on Windows.

## Deployment

The live demo at [foodcal-ai-app.web.app](https://foodcal-ai-app.web.app) is deployed with:

```bash
flutter build web --release
firebase deploy --only hosting
```

See `firebase.json` for hosting config, and the Firebase Console's Analytics/Crashlytics dashboards once the app has real traffic.
