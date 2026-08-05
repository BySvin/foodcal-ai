import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/option_selector.dart';
import '../../../../routing/route_paths.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/food_log_entry.dart';
import '../providers/food_log_providers.dart';
import '../providers/food_providers.dart';
import '../widgets/meal_section.dart';

/// Reached either with [food] already known (normal search flow) or with
/// only [foodId] (a deep link / page refresh on web) — falls back to a
/// Firestore lookup in the latter case.
class FoodQuantityScreen extends ConsumerStatefulWidget {
  const FoodQuantityScreen({
    super.key,
    required this.foodId,
    required this.mealType,
    required this.date,
    this.food,
  });

  final String foodId;
  final MealType mealType;
  final DateTime date;
  final FoodItem? food;

  @override
  ConsumerState<FoodQuantityScreen> createState() => _FoodQuantityScreenState();
}

class _FoodQuantityScreenState extends ConsumerState<FoodQuantityScreen> {
  num _quantity = 1;
  late MealType _mealType = widget.mealType;

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(foodLogControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Log food')),
      body: SafeArea(
        child: widget.food != null
            ? _buildContent(context, widget.food!, isLoading)
            : FutureBuilder<FoodItem?>(
                future: ref.read(foodRepositoryProvider).getById(widget.foodId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LoadingView();
                  }
                  final food = snapshot.data;
                  if (food == null) {
                    return const ErrorView(message: 'This food could not be found.');
                  }
                  return _buildContent(context, food, isLoading);
                },
              ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FoodItem food, bool isLoading) {
    final theme = Theme.of(context);
    final favoritesAsync = ref.watch(favoritesProvider);
    final isFavorite = favoritesAsync.valueOrNull?.any((f) => f.foodId == food.id) ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.name, style: theme.textTheme.headlineLarge),
                    Text(
                      '${food.servingSize} ${food.servingUnit} · ${food.calories} kcal',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(isFavorite ? Icons.star_rounded : Icons.star_outline_rounded),
                tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                color: isFavorite ? theme.colorScheme.primary : null,
                onPressed: () => ref
                    .read(foodLogControllerProvider.notifier)
                    .toggleFavorite(food, isCurrentlyFavorite: isFavorite),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Quantity', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Decrease quantity',
                onPressed: _quantity > 1 ? () => setState(() => _quantity -= 1) : null,
              ),
              SizedBox(
                width: 60,
                child: Text('$_quantity', textAlign: TextAlign.center, style: AppTextStyles.statNumber),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Increase quantity',
                onPressed: () => setState(() => _quantity += 1),
              ),
            ],
          ),
          Center(
            child: Text(
              '${(food.calories * _quantity).round()} kcal',
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Meal', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          OptionSelector<MealType>(
            selected: _mealType,
            onSelected: (m) => setState(() => _mealType = m),
            options: [
              for (final type in MealType.values)
                SelectorOption(value: type, label: mealTypeLabels[type]!),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Add to log',
            isLoading: isLoading,
            onPressed: () async {
              final failure = await ref.read(foodLogControllerProvider.notifier).logFood(
                    foodId: food.id,
                    foodName: food.name,
                    servingSize: food.servingSize,
                    servingUnit: food.servingUnit,
                    quantity: _quantity,
                    caloriesPerServing: food.calories,
                    proteinPerServing: food.proteinG,
                    carbsPerServing: food.carbsG,
                    fatPerServing: food.fatG,
                    mealType: _mealType,
                    loggedDate: widget.date,
                    source: LogSource.search,
                  );
              if (!context.mounted) return;
              if (failure != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(failure.message)));
              } else {
                context.go(RoutePaths.log);
              }
            },
          ),
        ],
      ),
    );
  }
}
