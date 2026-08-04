# Onboarding

## User Story

As a newly signed-up user, I want to quickly tell the app my basic stats and goal so it can calculate a sensible daily calorie/macro/water target for me, without feeling like I'm filling out a long form.

## User Flow

1. Router redirects a signed-up-but-not-onboarded user to `/onboarding` (see `docs/features/auth.md` for the redirect logic).
2. Step 1 — Name (pre-filled from the auth display name if available).
3. Step 2 — Age + Gender.
4. Step 3 — Height (cm) + current weight (kg).
5. Step 4 — Activity level (5 descriptive options).
6. Step 5 — Goal (lose / maintain / gain).
7. Step 6 — Summary: live-computed daily calorie target, macro split, and water goal, with a note if the target was safety-clamped.
8. "Start tracking" writes the full profile to `users/{uid}` and flips `onboardingCompleted: true`. The router (watching `appUserProvider`) redirects to `/dashboard` automatically once Firestore confirms the write — no explicit navigation call needed.
9. Back button (top-left) steps backward; there's no skip — every field feeds the calorie calculation.

## Screen Layout

Single `PageView` (`NeverScrollableScrollPhysics` — navigation is button-driven, not swipe, so a step can't be skipped past validation) with 6 pages, each wrapped in `OnboardingStepScaffold`: thin progress bar (`stepIndex+1 / stepCount`), headline title, optional subtitle, scrollable content area, and a full-width primary button pinned at the bottom. Steps use either a text field (`AppTextField`) or `OptionSelector` — a column of tappable cards with a checkmark on the selected option, used for Gender, Activity Level, and Goal where a dropdown would hide the choices.

## Flutter Widget Structure

```
OnboardingScreen (ConsumerStatefulWidget)
  PageView
    OnboardingStepScaffold (title: "What's your name?")
      AppTextField
    OnboardingStepScaffold (title: "Tell us about you")
      AppTextField (age) + OptionSelector<Gender>
    OnboardingStepScaffold (title: "Height & weight")
      AppTextField (height) + AppTextField (weight)
    OnboardingStepScaffold (title: "How active are you?")
      OptionSelector<ActivityLevel>
    OnboardingStepScaffold (title: "What's your goal?")
      OptionSelector<Goal>
    OnboardingStepScaffold (title: "Your daily targets")
      _SummaryRow x5 (calories, protein, carbs, fat, water)
```

`OnboardingStepScaffold` and `OptionSelector` live in `presentation/widgets/` — both are reusable if V2 adds more guided-input flows.

## Firestore Database Design

Writes to the existing `users/{uid}` doc (created at sign-up, see `docs/features/auth.md`) via a single merge update on submit:

```
displayName, age, gender, heightCm, currentWeightKg, activityLevel, goal,
dailyCalorieTarget, macroTargets: {proteinG, carbsG, fatG}, dailyWaterTargetMl,
onboardingCompleted: true, updatedAt
```

No new collection — onboarding is purely a guided editor for fields already defined on `users/{uid}`.

## Riverpod Providers

- `onboardingControllerProvider` (`AsyncNotifierProvider<OnboardingController, OnboardingFormState>`) — holds the in-progress, not-yet-persisted form state (`OnboardingFormState`, nullable fields = unanswered).
  - `setName/setAge/setGender/setHeightCm/setWeightKg/setActivityLevel/setGoal` — synchronous field updates.
  - `OnboardingFormState.computedTargets` — a getter that runs `CalorieCalculator.calculateTargets` once every required field is present; `null` otherwise. Used for the live summary preview.
  - `submit()` — writes via `userRepositoryProvider` (reused from the auth feature, not a new onboarding-specific repository), returns an error string or `null`.

## Repository Structure

No new repository — reuses `UserRepository`/`UserRepositoryImpl` from `features/auth/data`. Onboarding is a write-heavy consumer of the same `users/{uid}` document the auth feature created.

## Navigation Flow

Entirely internal (the `PageView`'s own index) except for the final `submit()`, after which the app router's redirect (triggered by `appUserProvider` emitting `onboardingCompleted: true`) takes over and navigates to `/dashboard`. `PopScope(canPop: false)` prevents the OS back gesture from leaving onboarding mid-flow.

## Validation Rules

- Name: non-empty.
- Age: integer, 13–120.
- Gender: one of the three options selected.
- Height: 100–250 cm.
- Weight: 30–300 kg.
- Activity level / Goal: one option selected.
- Each rule is checked in `_next()` before advancing; failures set an inline error string shown under the step's content.

## Loading States

The summary step's "Start tracking" button shows an inline spinner (`AppButton.isLoading`) while `submit()`'s Firestore write is in flight.

## Error States

If `submit()` fails (e.g. network issue), the `Failure.message` is shown via `SnackBar` and the form state is rolled back to what it was before the attempt, so the user doesn't lose their inputs.

## Empty States

Not applicable — every step always has visible content (fields or options).

## Responsive Design Considerations

Content is centered in a `ConstrainedBox(maxWidth: 480)`, matching the auth screens, so long-form option lists don't stretch uncomfortably wide on tablet/web viewports.

## Future Extension Points

- Imperial units — `AppUser.unitPreference` already exists; the height/weight step would branch its input labels/conversion off that field.
- Skippable/optional fields for a "quick start" path — would require making `dailyCalorieTarget` computable from partial data with sane defaults.
- Editing targets post-onboarding is already covered by the Profile & Settings milestone reusing the same `CalorieCalculator`.
