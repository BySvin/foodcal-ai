# Dashboard

## User Story

As a user, I want to open the app and immediately see how my day is going — calories remaining, macro progress, and water intake — without digging through menus, and have it update the moment I log something from anywhere else in the app.

## User Flow

1. `/dashboard` is the default landing tab after sign-in (or the redirect target once onboarding completes).
2. Date arrows in the app bar move between days, same convention as `/log`.
3. Logging food (`/log`) or water (inline on this screen) anywhere in the app updates the ring, macro bars, and water card here immediately — all driven by the same Firestore streams, no manual refresh.
4. Going over the calorie target flips the ring and center label from "kcal remaining" to "kcal over" in the danger color, rather than just showing a negative number.

## Screen Layout

Single scrollable column: centered calorie `ProgressRing` (remaining/over figure in the center), a "`consumed` / `target` kcal consumed" caption underneath, a card with three `MacroBar`s (protein/carbs/fat), then the `WaterTrackerCard` from the Water Tracker milestone.

## Flutter Widget Structure

```
DashboardScreen (ConsumerWidget)
  AppBar(title: DateNavHeader)
  appUserProvider.when(...)
    _DashboardBody (ConsumerWidget)
      ProgressRing (core/widgets)
      MacroBar x3 (core/widgets, reused from Water Tracker's card too)
      WaterTrackerCard (water_tracker feature)
```

`DateNavHeader` was extracted from Log Logging's screen into `core/widgets/` in this milestone, since Dashboard needed the identical prev/today/next control — the same de-duplication pattern as `OptionSelector`'s move in the Food Logging milestone.

## Firestore Database Design

No new collections — purely a composition layer over data other features already own: `dailyNutritionSummaryProvider` (from Food Logging, summing that day's `food_logs`), `appUserProvider` (from Auth, for `dailyCalorieTarget`/`macroTargets`), and `WaterTrackerCard`'s own `dailyWaterProvider` (from Water Tracker).

## Riverpod Providers

Composes existing providers rather than introducing new Firestore-backed ones:
- `appUserProvider` — calorie/macro targets.
- `dailyNutritionSummaryProvider(date)` — today's consumed totals.
- `selectedDateProvider` — which day is showing.

No dashboard-specific repository or controller — this screen is read-only composition; all mutations (logging food, adding water) happen through the widgets/screens that own that data.

## Repository Structure

None — no `features/dashboard/data/` or `domain/` layers exist; the feature is presentation-only (`features/dashboard/presentation/screens/dashboard_screen.dart`).

## Navigation Flow

`/dashboard` is a shell-branch root with no child routes. It's also one of the router's "entry route" targets — onboarded users landing on `/splash`, a public route, or `/onboarding` get redirected here.

## Validation Rules

None — display-only.

## Loading States

Whole-screen `LoadingView` while `appUserProvider` resolves (this normally only shows briefly on cold start, since the stream is already warm from routing's own use of it). `dailyNutritionSummaryProvider` is a derived `Provider` (not itself async), so once `appUserProvider` has resolved, the ring/macros render immediately from whatever `dailyFoodLogsProvider` currently has cached — no separate spinner for that layer.

## Error States

`ErrorView` with retry if `appUserProvider` errors. `WaterTrackerCard` handles its own error state internally.

## Empty States

Not applicable — 0 consumed against a real target is a normal, fully-rendered state (full ring showing "target kcal remaining"), not a distinct empty branch.

## Responsive Design Considerations

Single-column `ListView` reflows naturally at any width; on wide/web viewports (≥900px) it sits inside the side-rail shell's remaining space rather than stretching full-bleed, consistent with the rest of the app's shell layout.

## Future Extension Points

- A settings toggle for "hide over-budget styling" or alternate ring metrics (e.g. macros-first view) would slot into `_DashboardBody` without touching the underlying providers.
- Streaks / weekly trend surfaces (V2) would add new derived providers over the same `food_logs`/`water_logs` data this screen already reads.

## Verification

Verified via automated tests (`flutter analyze` clean, `dashboard_screen_test.dart` asserting the ring's remaining/over figure and each macro bar's text against known `NutritionSummary` fixtures) plus a live check that the app compiles and connects to the real Firebase project with no console errors. A full manual click-through (log food/water elsewhere, confirm the Dashboard updates live) is best done on the connected physical device, since this session's browser pane wasn't rendering screenshots at the time — the underlying stream wiring (`dailyFoodLogsProvider` → `dailyNutritionSummaryProvider`, `dailyWaterProvider`) is the same Firestore `snapshots()` pattern already proven live end-to-end in the Auth/Onboarding milestones.
