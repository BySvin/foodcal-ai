# Weight Tracking

## User Story

As a user, I want to log my weight in a few seconds, see it plotted against recent days, and have re-logging today just correct today's entry rather than cluttering my history with duplicates.

## User Flow

1. Reached via `/profile/weight` — for now, a temporary "Weight history" link on the Profile stub screen (Profile & Settings isn't built yet; this keeps the feature reachable and testable in the meantime).
2. Enter today's weight (kg) and an optional note, tap Save.
3. Logging again the same day overwrites that day's entry — there's no way to have two entries for one day.
4. Below the form: a trend line chart (once 2+ entries exist) and a reverse-chronological history list.

## Screen Layout

`WeightScreen`: a card with the log-today form (weight + note fields, Save button) at the top, then the `WeightChart` trend line, then a plain history list — newest entry first, oldest chart point first (charts read left-to-right as time passing; history lists read top-to-bottom as most-recent-first, matching each UI convention rather than forcing one order everywhere).

## Flutter Widget Structure

```
WeightScreen (ConsumerStatefulWidget)
  Card (log-today form: AppTextField x2, AppButton)
  weightLogsProvider.when(...)
    WeightChart (fl_chart LineChart, or a placeholder text under 2 entries)
    _WeightHistoryTile x N (reverse-chronological)
```

## Firestore Database Design

`weight_logs/{uid}_{loggedDate}` — deterministic doc id, one entry per user per day:

```
userId, weightKg, loggedDate ('yyyy-MM-dd'), note (nullable), createdAt, updatedAt
```

`logWeight` does a plain `set()` (no merge) — re-logging the same day fully replaces the previous entry (weight and note both), which is the correct "upsert" semantics for a same-day correction rather than a partial field patch.

## Riverpod Providers

- `weightLogRepositoryProvider` — Firestore-backed.
- `weightLogsProvider` (`StreamProvider<List<WeightEntry>>`) — last 90 days, oldest first (chart- and history-ready; the screen reverses it for the history list).
- `weightLogControllerProvider` (`AsyncNotifierProvider`) — `logWeight(date, weightKg, note)`, validating `0 < weightKg < 500` before writing.

## Repository Structure

```
domain/entities/weight_entry.dart
domain/repositories/weight_log_repository.dart
data/models/weight_entry_model.dart
data/repositories/weight_log_repository_impl.dart
```

## Navigation Flow

`/profile/weight` is a child route of `/profile` (the shell-branch root), pushed rather than replacing the tab. No further sub-routes.

## Validation Rules

Weight must parse as a number and be `0 < weightKg < 500`; enforced both client-side (`WeightLogController.logWeight`) and at the Firestore rules layer, so a malformed request can't bypass validation even if it skips the client.

## Loading States

`LoadingView` while `weightLogsProvider` resolves; the log-today button shows its own inline spinner while `weightLogControllerProvider` is in flight.

## Error States

`ErrorView` with retry if the history stream errors; a `SnackBar` for save failures or an invalid weight value.

## Empty States

`EmptyStateView` ("No entries yet") when nothing has been logged; `WeightChart` shows its own lighter-weight "Log at least 2 days to see a trend." message rather than treating a single entry as a full empty state.

## Responsive Design Considerations

The chart is a fixed 200px-tall `SizedBox` at any width, letting `fl_chart` handle its own internal responsive layout; the form's weight/note fields sit in a `Row` with `Expanded`, compressing evenly on narrow viewports like the rest of the app's paired-field patterns.

## Future Extension Points

- Editing/deleting a past (non-today) entry — the deterministic doc id already makes this a simple `logWeight` call with an arbitrary `date` rather than always `DateTime.now()`; `WeightLogController.logWeight` already accepts any `DateTime`, just not exposed in the UI yet.
- Imperial units (lb) — same `AppUser.unitPreference` hook noted in Onboarding's future extension points.
- Correlating weight trend with calorie history (V2 insight) would read from both this collection and `food_logs` without needing new fields on either.
