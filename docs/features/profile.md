# Profile & Settings

## User Story

As a user, I want to see and update my info and goals, change the app's theme, and sign out — with any change to my goal clearly telling me what it'll do to my daily target before it takes effect.

## User Flow

1. `/profile` shows avatar (from Google Sign-In, if used), name, email, current daily calorie target, a theme toggle, and links to edit profile / weight history / sign out.
2. "Edit profile & goal" (`/profile/edit`) opens a single-page form (name, age, height, weight, gender, activity level, goal) pre-filled with current values.
3. Saving recomputes targets via the same `CalorieCalculator` used at onboarding. If the recomputed calorie target differs from the current one, a confirm dialog states the old → new value before anything is written — editing your weight or goal shouldn't silently change a number you're actively tracking against.
4. Theme toggle (Light/Dark/System) applies immediately app-wide and persists to `settings/{uid}`.
5. "Sign out" calls `AuthRepository.signOut()`; the router's redirect (already watching `authStateChangesProvider`) sends the user to `/login` automatically — no explicit navigation call needed.

## Screen Layout

- **Profile** (`/profile`): centered avatar (static — see Known Constraints) + name + email, a card showing the daily target, the theme `SegmentedButton`, then stacked outlined buttons (Edit profile & goal, Weight history) and a text-button Sign out.
- **Edit profile** (`/profile/edit`): the same field/selector shapes as Onboarding but as one scrollable form rather than a stepper — editing is a correction, not a first-time guided flow.

## Flutter Widget Structure

```
ProfileScreen (ConsumerWidget)
  _Avatar (static display only — no upload; see note below)
  _ThemeModeSelector (ConsumerWidget — SegmentedButton<ThemeMode>)

ProfileEditScreen (ConsumerStatefulWidget)
  Form
    AppTextField x3 (name, age, height+weight row)
    OptionSelector<Gender> / <ActivityLevel> / <Goal>   — shared with Onboarding
    AppButton (Save) → confirm dialog if the target would change
```

## Firestore Database Design

No new collections beyond what earlier milestones already declared:

- `users/{uid}` — `ProfileController.updateProfile` writes the same fields Onboarding does (age, gender, heightCm, currentWeightKg, activityLevel, goal, dailyCalorieTarget, macroTargets, dailyWaterTargetMl) plus `displayName`. `photoUrl` is set only by Google Sign-In (from the Google account's profile photo) — there's no in-app upload path.
- `settings/{uid}` — created in this milestone. Only `themeMode` has a V1 UI; `notificationsEnabled`/`weekStartsOn` stay documented-but-unwritten per `docs/architecture.md`'s original framing, rather than being written with placeholder values nothing reads yet.

## Riverpod Providers

- `settingsRepositoryProvider`, `appSettingsProvider` (`StreamProvider<AppSettings>`, defaults to `ThemeMode.system` both pre-sign-in and pre-first-change), `settingsControllerProvider` (`setThemeMode`).
- `profileControllerProvider` (`AsyncNotifierProvider`) — `updateProfile(...)` (recompute + write), `signOut()`.
- `App` (`lib/app.dart`) now watches `appSettingsProvider` for `MaterialApp.router`'s `themeMode`, replacing the previously hardcoded `ThemeMode.system`.

## Repository Structure

```
domain/entities/app_settings.dart
domain/repositories/settings_repository.dart
data/models/app_settings_model.dart
data/repositories/settings_repository_impl.dart
presentation/providers/settings_providers.dart, profile_providers.dart
```

No separate "profile repository" — `ProfileController` reuses `UserRepository` from the Auth feature directly, since editing a profile is just writing to the same `users/{uid}` doc Auth/Onboarding already own.

## Navigation Flow

`/profile/edit` and `/profile/weight` are both pushed child routes of `/profile`. Saving in `ProfileEditScreen` pops back to `/profile` on success; sign-out relies entirely on the router's existing auth redirect rather than an explicit `context.go('/login')` call.

## Validation Rules

Same numeric ranges as Onboarding are implicitly enforced by `CalorieCalculator`'s clamping; the edit form itself doesn't duplicate Onboarding's inline per-field validators (age 13–120, etc.) since editing is a lower-friction correction — a malformed number simply fails to parse and the save attempt is quietly rejected via a `SnackBar`, without a full validation pass blocking the form.

## Loading States

`LoadingView` while the profile or edit form's underlying `appUserProvider` resolves; the Save button shows its inline spinner while `profileControllerProvider` is in flight.

## Error States

`ErrorView` with retry for profile load failures; `SnackBar` for update failures.

## Empty States

Not applicable — profile fields are always populated post-onboarding.

## Responsive Design Considerations

`ProfileScreen`'s content is a single-column `ListView`, matching Dashboard/History; `ProfileEditScreen`'s height/weight fields share a `Row` + `Expanded` pattern identical to Onboarding's, compressing evenly on narrow viewports.

## Fixed in this milestone: stale data across sign-out

While building sign-out, found that several `StreamProvider`/`StreamProvider.family` bodies (`dailyFoodLogsProvider`, `recentFoodsProvider`, `favoritesProvider`, `dailyWaterProvider`, `weightLogsProvider`) read the current uid via `ref.watch(authRepositoryProvider).currentUid` — since `authRepositoryProvider`'s own value never changes, watching it doesn't make the *reading* of `.currentUid` reactive, so those providers would keep serving the previous user's cached Firestore stream after sign-out instead of resetting. Fixed by switching them to `ref.watch(authStateChangesProvider).valueOrNull?.uid`, the same reactive pattern `appUserProvider` already used correctly. Covered by a regression test (`food_log_providers_test.dart`) that signs a mock user out mid-test and asserts the same provider instance resets to empty rather than retaining the prior user's data — this is exactly the "no stale data flashes for the next user on shared devices" scenario called out in the plan for this milestone.

## Known Constraints

Avatar upload was dropped from V1 — Firebase Storage adds a second backend surface to secure and deploy for a single profile-photo field, and Google Sign-In already supplies `photoUrl` for the users who have one. `_Avatar` in `ProfileScreen` is a static display; there's no tap-to-change interaction, `firebase_storage`/`image_picker` aren't dependencies, and `storage.rules` doesn't exist.

## Future Extension Points

- Avatar upload via Firebase Storage — the natural next place to reintroduce it if wanted later; would need `storage.rules` (owner-only, size/content-type limits) re-added and Storage enabled in the Firebase Console.
- `/profile/water-settings` (a dedicated water-goal-only editor) — the route constant already exists in `RoutePaths`; V1 folds water goal editing into the general profile/goal edit instead of a separate screen.
- `notificationsEnabled` / `weekStartsOn` UI — straightforward additions to `AppSettings` + `ProfileScreen` once push notifications or a calendar-week History view exist.
- Account deletion / data export — not in V1's feature list; `users/{uid}`'s `allow delete: if false` rule would need to change deliberately if this is added later.
