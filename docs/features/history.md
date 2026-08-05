# Daily History

## User Story

As a user, I want to look back at any of the last 30 days and see what I ate, drank, and weighed that day, without it needing its own dedicated data store to maintain.

## User Flow

1. `/history` lists the last 30 days, most recent (today) first, each row showing the date and that day's total calories (or "No logs" if nothing was recorded).
2. Tapping a row opens `/history/:date` — the full picture for that day: calorie ring + macro bars (reusing Dashboard's composition), water progress, and that day's weight entry if one exists.
3. A day with nothing recorded at all shows an empty state instead of a zeroed-out summary.
4. The water card on a past day is still interactive — consistent with `/log` already allowing you to add food to a past date via its date nav, this lets you backfill a missed day's water too, rather than being arbitrarily locked once the day has passed.

## Screen Layout

- **History list** (`/history`): a plain `ListView.separated` of 30 rows, each just a date and a calorie figure.
- **History detail** (`/history/:date`): identical composition to the Dashboard body (`NutritionSummaryView` + `WaterTrackerCard`), plus a small weight card when that day has a logged entry — or a single `EmptyStateView` in place of all of that when the day is entirely blank.

## Flutter Widget Structure

```
HistoryScreen (StatelessWidget)
  ListView.separated
    _HistoryDayTile (ConsumerWidget) x 30

HistoryDetailScreen (ConsumerWidget)
  appUserProvider.when(...)
    _HistoryDetailBody (ConsumerWidget)
      dailyFoodLogsProvider(date).when(...)
        EmptyStateView                              — if nothing logged
        NutritionSummaryView (dashboard feature)     — otherwise
        WaterTrackerCard (water_tracker feature)
        _WeightSummaryCard                            — if a weight entry exists
```

## Firestore Database Design

No new collection, per the architecture decision documented in `docs/architecture.md`: a history-specific write-fanout collection would be an ongoing maintenance burden for a V1. Instead, each visible day does its own lightweight aggregation query against the collections other features already own — `food_logs` (via the existing `dailyNutritionSummaryProvider`), `water_logs` (via `dailyWaterProvider`), and `weight_logs` (via `weightLogsProvider`, filtered client-side to the matching day).

## Riverpod Providers

No new providers — History is entirely a consumer of providers built in earlier milestones:
- `dailyNutritionSummaryProvider(date)` / `dailyFoodLogsProvider(date)` (Food Logging)
- `dailyWaterProvider(date)` (Water Tracker)
- `weightLogsProvider` (Weight Tracking) — the list is small (90 days) so filtering client-side to a single day is cheap and avoids adding a new per-day family provider just for this one lookup.

## Repository Structure

None — `features/history/` has only a `presentation/` layer (`history_screen.dart`, `history_detail_screen.dart`), no `data/` or `domain/`.

## Navigation Flow

`/history` is a shell-branch root; `/history/:date` is a pushed child route, with `:date` as a `yyyy-MM-dd` path parameter (parsed via `AppDateUtils.fromDayKey`) — directly linkable/shareable, and safe to deep-link into since the detail screen re-derives everything from `date` alone.

## Validation Rules

None — read-oriented; the only write path (backfilling water via the embedded `WaterTrackerCard`) reuses Water Tracker's existing validation.

## Loading States

Per-row: each `_HistoryDayTile` renders as soon as its own `dailyNutritionSummaryProvider` resolves (rows don't block each other). Detail screen: `LoadingView` while the user profile and that day's food logs resolve.

## Error States

`ErrorView` with retry if the profile or that day's food logs fail to load.

## Empty States

The list's "No logs" row label vs. the detail screen's full `EmptyStateView` — deliberately different weights: a one-word signal in a list row, a proper empty state once you've actually navigated in to look.

## Responsive Design Considerations

Same patterns as Dashboard (`NutritionSummaryView`/`WaterTrackerCard` reused directly) and the list's `ListTile` rows, both of which already reflow correctly at any width.

## Future Extension Points

- Pagination beyond 30 days (currently a fixed `List.generate(30, ...)`) — would swap the fixed list for a "load more" cursor without touching the per-day rendering.
- A calendar-grid view as an alternate History layout — would sit alongside the list, both driving the same `/history/:date` detail route.
