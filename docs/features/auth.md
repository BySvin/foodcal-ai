# Authentication

## User Story

As a new or returning user, I want to create an account or sign in quickly (with email/password or Google), reset my password if I forget it, and be gently reminded to verify my email — without that verification blocking me from using the app.

## User Flow

1. New user opens the app → redirected to `/login` (no session).
2. Taps "Sign up" → fills name/email/password/confirm → account created, `users/{uid}` doc created with `onboardingCompleted: false`, verification email sent automatically.
3. Router redirect detects `onboardingCompleted == false` → sends user to `/onboarding` (Onboarding milestone).
4. Returning user with an incomplete profile write (rare race) stays on the current screen until the doc loads, rather than bouncing to onboarding prematurely.
5. Existing user opens the app → session restored → redirected straight to `/dashboard` if onboarded.
6. User forgets password → `/login` → "Forgot password?" → `/forgot-password` → enters email → reset email sent → confirmation state shown → "Back to sign in".
7. Unverified user sees a dismissible-per-session banner above the app shell with a "Verify" action → `/verify-email` → can resend the email or just continue using the app (soft gate).
8. User signs out (Profile & Settings milestone) → returns to `/login`.

## Screen Layout

- **Login** (`/login`): centered card (max-width 420), headline + subtext, email field, password field (show/hide toggle), "Forgot password?" link, primary "Sign In" button, divider, "Continue with Google" button, "Don't have an account? Sign up" footer.
- **Sign up** (`/signup`): same layout shape, adds Name field and Confirm password field.
- **Forgot password** (`/forgot-password`): email field + "Send reset link"; after submit, swaps to a confirmation state (icon, message, "Back to sign in").
- **Verify email** (`/verify-email`): icon, headline, explanatory text naming the current email, "Resend email" (secondary) and "Continue to app" (primary) buttons.
- **Email verification banner**: thin bar pinned above the shell content (below the top safe area), primary-container color, icon + message + "Verify" + dismiss (×).

## Flutter Widget Structure

```
LoginScreen (ConsumerStatefulWidget)
  Form
    AppTextField (email)
    PasswordField (auth-specific, show/hide toggle)
    TextButton (forgot password)
    AppButton (Sign In)
    GoogleSignInButton
SignupScreen — same shape + Name + confirm PasswordField
ForgotPasswordScreen — Form | confirmation Column, swapped via local bool state
VerifyEmailScreen — static Column with two AppButtons
EmailVerificationBanner (ConsumerStatefulWidget, local `_dismissed` state) — mounted in AppShell above `navigationShell`
```

## Firestore Database Design

`users/{uid}` (see `docs/architecture.md` for the full field list). This milestone writes on create:

```
email, displayName, photoUrl, onboardingCompleted: false,
unitPreference: 'metric', createdAt, updatedAt
```

All onboarding-specific fields (age, gender, targets, etc.) are absent until the Onboarding milestone.

## Riverpod Providers

- `authRepositoryProvider` → `AuthRepositoryImpl` (wraps `FirebaseAuth` + `GoogleSignIn`)
- `userRepositoryProvider` → `UserRepositoryImpl` (wraps `FirebaseFirestore`, `users` collection)
- `appUserProvider` (`StreamProvider<AppUser?>`) — derives from `authStateChangesProvider`'s uid, watches `users/{uid}`; the app-wide source of truth for onboarding status
- `authControllerProvider` (`AsyncNotifierProvider<AuthController, void>`) — `signUp`, `signIn`, `signInWithGoogle`, `sendPasswordResetEmail`, `resendVerificationEmail`, `signOut`; each returns a `Failure?` so screens can show it in a `SnackBar` without the controller throwing

## Repository Structure

```
domain/entities/app_user.dart        — AppUser, MacroTargets, UnitPreference
domain/repositories/auth_repository.dart
domain/repositories/user_repository.dart
data/models/app_user_model.dart      — Firestore <-> AppUser mapping
data/repositories/auth_repository_impl.dart
data/repositories/user_repository_impl.dart
```

`AuthRepository` never leaks `FirebaseAuthException` — `_mapAuthException` translates known codes to user-facing messages wrapped in `AuthFailure`.

## Navigation Flow

`goRouterProvider`'s `redirect` callback, re-evaluated via `RouterRefreshNotifier` listening to both `authStateChangesProvider` and `appUserProvider`:

1. Auth loading → `/splash`.
2. No user → only `/login`, `/signup`, `/forgot-password` allowed; anything else → `/login`.
3. User present, profile doc loading → `/splash`.
4. Profile doc missing → stay put (avoids a flash to onboarding mid-write).
5. `onboardingCompleted == false` → forced to `/onboarding`.
6. Onboarded user hitting an entry route (`/splash`, public routes, `/onboarding`) → `/dashboard`.

## Validation Rules

- Email: non-empty, matches a basic `local@domain.tld` pattern (`Validators.email`).
- Password: non-empty, minimum 8 characters on sign-up (`Validators.password`); sign-in only checks non-empty (Firebase is the source of truth for correctness there).
- Confirm password: must match (`Validators.confirmPassword`).
- Name: required, non-empty.

## Loading States

- Auth buttons (`AppButton`, `GoogleSignInButton`) show an inline spinner and disable themselves while `authControllerProvider` is `AsyncLoading`.
- Router shows `SplashScreen` (centered spinner) while auth/profile state is resolving.

## Error States

- Field-level: red border + message under the field (standard `TextFormField` validator).
- Operation-level: `Failure.message` surfaced via `SnackBar` (e.g. "An account already exists for that email.", "Incorrect email or password.", "No internet connection. Please try again.").

## Empty States

Not applicable — auth screens are always populated forms, not data lists.

## Responsive Design Considerations

All auth screens center content in a `ConstrainedBox(maxWidth: 420)`, so on wide/web viewports the form doesn't stretch edge-to-edge; on narrow/mobile viewports it naturally fills available width with 24px horizontal padding.

## Future Extension Points

- Phone-number auth or additional OAuth providers (Apple, Facebook) — add to `AuthRepository` alongside `signInWithGoogle`.
- Hard email-verification gate — the router redirect already has the profile-load structure needed; would add one more condition before the onboarding check.
- MFA — `FirebaseAuth` supports it natively; would surface as an additional step in `AuthController`.

## Known Constraints

- `GoogleSignInButton` uses a lightweight lettermark, not the official Google brand asset — swap before any store submission requiring exact brand-guideline compliance.
- Google Sign-In's native platform flow cannot be exercised in the Chrome preview; verify on an Android emulator/device once M0 (Firebase Bootstrap) is complete.
