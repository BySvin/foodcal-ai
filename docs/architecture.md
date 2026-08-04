# FoodCal AI — Architecture Overview

## Stack

- **Frontend**: Flutter (Android/iOS/Web), Material 3, Riverpod, Go Router
- **Backend**: Firebase (Auth, Firestore, Storage, Analytics, Crashlytics)
- **Charts**: fl_chart

## Layout

Feature-first, pragmatic clean architecture. Each feature under `lib/features/<name>/` has:

- `data/` — models (Firestore document <-> Dart) and repository implementations
- `domain/` — entities and abstract repository interfaces
- `presentation/` — Riverpod providers, screens, and feature-local widgets

There is no separate `usecases/` layer: Riverpod `AsyncNotifier` classes in `presentation/providers` orchestrate repository calls directly, keeping boilerplate proportional to an MVP while still giving a swappable/mockable seam at the repository interface.

`lib/core/` holds cross-feature building blocks: theme, reusable widgets, error types (`Failure`/`Result`), pure utilities (calorie calculator, date utils, validators), and the base Firebase provider instances. `lib/routing/` holds the Go Router configuration, including the auth/onboarding redirect guard and the responsive shell (bottom nav on mobile, side rail on wide/web).

## State management conventions

- `StreamProvider` for live Firestore-backed data (auth state, user profile, daily logs).
- `Provider.family` for derived/computed values (e.g. a day's nutrition summary from that day's food logs).
- `AsyncNotifierProvider` for mutations (logging food, adding water, submitting onboarding).
- Repositories are always accessed through a `Provider<T>` so tests can override them with fakes.

## Firestore data model

All user-owned logging collections (`food_logs`, `favorites`, `weight_logs`, `water_logs`) are top-level collections carrying a `userId` field, not subcollections — this keeps ownership-based security rules identical across collections and leaves room for future `collectionGroup` queries. `foods` is a shared global catalog (curated seed data + user-submitted custom foods). See `firestore.rules` for the access-control logic and each feature's `docs/features/<name>.md` for the exact document shape it reads/writes.

## Extension points for V2

The architecture intentionally leaves room for, without requiring a rewrite:

- AI food recognition / barcode scanning — would add a new `source` value to `food_logs` and a new entry point into the existing `foodLogControllerProvider.logFood(...)` API.
- Push notifications — `settings.notificationsEnabled` field already exists, unused.
- Subscriptions/payments — would gate features via a new `users.plan` field, checked in relevant providers.
- Full-text food search (Algolia/Typesense) — would replace `FoodRepository.search()`'s Firestore prefix query internally; callers wouldn't change.
