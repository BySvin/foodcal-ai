# Food Logging

## User Story

As a user tracking my day, I want to quickly find and log what I ate — by searching a shared catalog, picking from what I've eaten recently or favorited, or typing in something one-off — organized into Breakfast/Lunch/Dinner/Snacks, so my dashboard totals stay accurate with minimal friction.

## User Flow

1. `/log` shows today's (or the selected day's) 4 meal sections, each with its logged entries and a running calorie subtotal.
2. Tapping "Add food" on a section opens `/log/search`, pre-scoped to that meal type and date.
3. Empty search: browse "Recent" (deduped by food, most recently logged first) or jump straight to "Add manually".
4. Typing a query (debounced 350ms) searches the shared `foods` catalog by prefix.
5. Tapping a result opens `/log/food/:foodId` — quantity stepper, meal-type override, favorite toggle, "Add to log".
6. "Add manually" (`/log/add-manual`) — a one-off entry not tied to any catalog food: name, serving, calories, macros, meal type.
7. Back on `/log`, tapping a logged entry opens a bottom sheet to adjust quantity or delete it; swiping an entry left also deletes it.
8. Date arrows in the app bar move between days; "today" caps forward navigation.

## Screen Layout

- **Log** (`/log`): app bar with `< Today >` date nav, a scrollable list of 4 `MealSection` cards (title + subtotal + entries + "Add food").
- **Search** (`/log/search`): app bar hosts the search field directly; body swaps between the browse view (Add manually button, Recent list) and results list as the query changes.
- **Food quantity** (`/log/food/:foodId`): food name/serving/calories header with a favorite star, quantity stepper with live calorie preview, meal-type selector, "Add to log".
- **Add manually** (`/log/add-manual`): name, serving size + unit, calories, protein/carbs/fat, meal-type selector, "Add to log".

## Flutter Widget Structure

```
LogScreen (ConsumerWidget)
  _DateHeader
  _MealSectionList
    MealSection x4
      Dismissible > ListTile  (per entry)
      "Add food" TextButton
  _EditQuantitySheet (modal bottom sheet)

FoodSearchScreen (ConsumerStatefulWidget)
  FoodSearchBar (debounced)
  _buildBrowse: Recent (FoodListTile) + "Add manually" button
  _buildResults: FoodListTile list | EmptyStateView | LoadingView | ErrorView

FoodQuantityScreen / AddManualFoodScreen
  OptionSelector<MealType>  (shared core widget, also used by Onboarding)
```

`OptionSelector` was promoted from Onboarding's presentation widgets to `core/widgets/` in this milestone since it's now used by two features — a feature-first structure shouldn't have one feature importing another's presentation layer directly.

## Firestore Database Design

- **`food_logs/{logId}`** (auto-generated id): `userId`, `foodId` (null for manual entries), denormalized `foodName`/`servingSize`/`servingUnit`, `quantity`, computed `calories`/`proteinG`/`carbsG`/`fatG` (= per-serving × quantity, stored as totals), `mealType`, `loggedDate` ('yyyy-MM-dd'), `loggedAt`, `source` ('search' | 'manual' | 'favorite').
- **`favorites/{uid}_{foodId}`**: deterministic id, denormalized food snapshot — `addFavorite` is a `set()`, so re-favoriting is idempotent rather than creating duplicates.

Quantity edits recompute `calories`/macros client-side from the entry's existing per-serving ratio (`FoodLogController.updateQuantity`) rather than the repository re-deriving them — the repository just persists whatever totals it's given.

## Riverpod Providers

- `foodLogRepositoryProvider`, `favoriteRepositoryProvider` — Firestore-backed.
- `dailyFoodLogsProvider(date)` (`StreamProvider.family`) — a day's entries, ordered by `loggedAt`.
- `dailyNutritionSummaryProvider(date)` (`Provider.family`) — sums `dailyFoodLogsProvider(date)` into a `NutritionSummary`; this is what the Dashboard milestone will consume directly.
- `recentFoodsProvider` — last 20 distinct-by-food log entries across all days.
- `favoritesProvider` — the user's favorited foods.
- `foodSearchResultsProvider(query)` (`FutureProvider.family`) — thin wrapper over `FoodRepository.search`; debouncing happens in `FoodSearchBar`, not here.
- `foodLogControllerProvider` (`AsyncNotifierProvider`) — `logFood`, `updateQuantity`, `deleteLog`, `toggleFavorite`.

## Repository Structure

```
domain/entities/food_log_entry.dart, favorite_food.dart, nutrition_summary.dart
domain/repositories/food_log_repository.dart, favorite_repository.dart
data/models/food_log_entry_model.dart, favorite_food_model.dart
data/repositories/food_log_repository_impl.dart, favorite_repository_impl.dart
```

## Navigation Flow

`/log` is a shell-branch root (bottom nav / side rail). `/log/search`, `/log/add-manual`, and `/log/food/:foodId` are pushed child routes carrying `mealType`/`date` (and `food`, when already known) via GoRouter's `extra`. `FoodQuantityScreen` falls back to a `FoodRepository.getById` lookup when `extra` is absent (a direct deep link or web page refresh landing mid-flow). Successful logging calls `context.go(RoutePaths.log)` to collapse the push stack back to the log root rather than popping through each intermediate screen.

## Validation Rules

- Manual add: name required; serving size and calories must be positive numbers; unit required; protein/carbs/fat default to 0 if left blank.
- Quantity edits: must be greater than 0 (`FoodLogController.updateQuantity` rejects otherwise).

## Loading States

`LoadingView` for the day's log stream, search results, and recent-foods stream. Buttons (`AppButton`) show inline spinners while `foodLogControllerProvider` is in flight.

## Error States

`ErrorView` with retry (via `ref.invalidate`) for the log stream and search; failures from `logFood`/`updateQuantity`/`deleteLog` surface via `SnackBar`.

## Empty States

- A day with no logs: each `MealSection` still renders with "No foods logged yet" rather than hiding the section — keeps the day's structure visible even before anything's logged.
- Search with no matches, or Recent with nothing yet: `EmptyStateView` with a direct "Add manually" call to action.

## Responsive Design Considerations

`LogScreen`'s meal list and the search/quantity/manual-add screens use standard `ListView`/`SingleChildScrollView` layouts that reflow naturally at any width; no fixed pixel widths beyond the shared 480px form constraint used elsewhere (manual-add's grouped Serving/Unit and Protein/Carbs/Fat rows use `Expanded` so they compress gracefully on narrow viewports).

## Future Extension Points

- Barcode scanning / AI food recognition would add new `source` values and populate the same `logFood` call — no schema change needed.
- A "reuse a manual entry" flow (saving a one-off manual food into the `foods` catalog as a custom entry) is a natural follow-up now that `FoodRepository`'s create path exists conceptually in the schema (`isCustom`/`createdBy`), just not wired to any UI yet.

## Known Constraints

Like Onboarding, `/log` and its sub-routes sit behind the router's auth guard, so they can't be reached through real navigation until Firebase Auth is live (M0). Verification here relied on repository tests against `fake_cloud_firestore` and widget tests pumping the screens directly with provider overrides, rather than a live Chrome walkthrough.
