# Water Tracker

## User Story

As a user, I want to log my water intake in one tap against a daily goal, see my progress at a glance, and undo a mis-tap immediately, without it interrupting whatever else I'm doing on the Dashboard.

## User Flow

1. The water card (embedded on the Dashboard, built in the next milestone) shows today's progress against the goal from onboarding.
2. Tapping `+250 ml` or `+500 ml` logs instantly; "Custom" opens a small dialog for any other amount.
3. Right after an add, an "Undo +N ml" link appears in the card — tapping it reverts exactly that add. It disappears once used (single-step undo, not a full history).
4. No dedicated screen or nav destination — water tracking is a Dashboard-only surface, per the product brief's minimal 4-tab nav.

## Screen Layout

`WaterTrackerCard`: a `MacroBar`-style progress row ("Water — N / goal ml"), a row of quick-add buttons (+250, +500, Custom), and a conditional "Undo" link beneath.

## Flutter Widget Structure

```
WaterTrackerCard (ConsumerWidget, takes a `date`)
  MacroBar (reused from core/widgets, color: AppColors.waterColor)
  Row of OutlinedButton (quick-add x2 + Custom)
  AlertDialog (custom amount, via showDialog)
  TextButton ("Undo +N ml", conditional on lastAddedMl != null)
```

## Firestore Database Design

`water_logs/{uid}_{date}` — one aggregate doc per user per day (deterministic id, natural upsert target):

```
userId, date ('yyyy-MM-dd'), totalMl, goalMl (snapshot of the target at
time of add), lastAddedMl (nullable — the single most recent add, cleared
on undo), updatedAt
```

Quick-add is a `set()` with `SetOptions(merge: true)` where `totalMl` uses `FieldValue.increment(amountMl)` — this both creates the doc on the first add of the day and atomically increments it on later adds, with no read-before-write race. `goalMl` is re-set on every add from the user's *current* target rather than truly "written once" — a deliberate simplification: it avoids an extra read to check whether the doc already exists, and in practice only differs from a strict one-time snapshot if the user changes their target mid-day, which is an edge case worth accepting for the simpler code path.

## Riverpod Providers

- `waterLogRepositoryProvider` — Firestore-backed.
- `waterGoalProvider` — the signed-in user's `dailyWaterTargetMl` from `appUserProvider`, falling back to 2000ml before onboarding has run.
- `dailyWaterProvider(date)` (`StreamProvider.family`) — never null; defaults to `WaterDay(totalMl: 0, goalMl: currentGoal)` when no doc exists yet for that day, so the UI never has to special-case "nothing logged."
- `waterLogControllerProvider` (`AsyncNotifierProvider`) — `addWater(date, amountMl)`, `undoLastAdd(date)`.

## Repository Structure

```
domain/entities/water_day.dart
domain/repositories/water_log_repository.dart
data/models/water_day_model.dart
data/repositories/water_log_repository_impl.dart
```

`undoLastAdd` uses a plain read-then-update rather than a Firestore transaction. A transaction would be the textbook-correct choice for race-safety, but the risk here — a single user racing against themselves on their own "undo my last add" tap — is negligible, and `fake_cloud_firestore`'s transaction shim doesn't properly await staged writes (a testing-library limitation, confirmed while writing this milestone's tests), so the simpler approach is both adequate for the real-world risk and reliably testable.

## Navigation Flow

None — `WaterTrackerCard` is embedded directly into the Dashboard (next milestone), not reached via its own route. `/profile/water-settings` (editing the daily goal itself) is deferred to the Profile & Settings milestone.

## Validation Rules

Custom amount dialog: must parse as a positive integer, otherwise the "Add" action is a no-op (silently ignored rather than showing a field error, since it's a lightweight dialog rather than a form).

## Loading States

A centered `CircularProgressIndicator` while `dailyWaterProvider` resolves its first snapshot.

## Error States

A plain "Could not load water intake." message in place of the progress row if the stream errors; add/undo failures surface via `SnackBar`.

## Empty States

Not applicable — the card always renders (0 / goal is the empty state, not a separate branch).

## Responsive Design Considerations

The quick-add buttons use `Expanded` in a `Row`, so they compress evenly regardless of container width — no fixed sizing to break on narrow viewports.

## Future Extension Points

- `/profile/water-settings` for editing the daily goal directly (Profile & Settings milestone) — `waterGoalProvider`'s fallback chain already anticipates this.
- A full add/undo history (rather than single-step) would only need `lastAddedMl` to become a list, with the doc shape otherwise unchanged.

## Known Constraints

`WaterTrackerCard` has no route of its own — it can only be exercised live once the Dashboard milestone embeds it. Verified here via repository tests (including the increment/undo logic against `fake_cloud_firestore`) and a widget test pumping the card directly with provider overrides.
