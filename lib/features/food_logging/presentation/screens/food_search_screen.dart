import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_paths.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/food_log_entry.dart';
import '../providers/food_log_providers.dart';
import '../providers/food_providers.dart';
import '../widgets/food_list_tile.dart';
import '../widgets/food_search_bar.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key, required this.mealType, required this.date});

  final MealType mealType;
  final DateTime date;

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  String _query = '';

  void _openFood(FoodItem food) {
    context.push(
      RoutePaths.logFood(food.id),
      extra: {'food': food, 'mealType': widget.mealType, 'date': widget.date},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FoodSearchBar(
            autofocus: true,
            onQueryChanged: (q) => setState(() => _query = q),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _query.isEmpty ? _buildBrowse(context) : _buildResults(context),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final resultsAsync = ref.watch(foodSearchResultsProvider(_query));

    return resultsAsync.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        message: 'Search failed. Please try again.',
        onRetry: () => ref.invalidate(foodSearchResultsProvider(_query)),
      ),
      data: (results) {
        if (results.isEmpty) {
          return _buildEmptyWithManualCta(
            icon: Icons.search_off_rounded,
            title: 'No matches',
            subtitle: 'Try a different search, or add it manually.',
          );
        }
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final food = results[index];
            return FoodListTile(
              name: food.name,
              servingLabel: '${food.servingSize} ${food.servingUnit}',
              calories: food.calories,
              onTap: () => _openFood(food),
            );
          },
        );
      },
    );
  }

  Widget _buildBrowse(BuildContext context) {
    final recentAsync = ref.watch(recentFoodsProvider);
    final theme = Theme.of(context);

    return ListView(
      children: [
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => context.push(
            RoutePaths.logAddManual,
            extra: {'mealType': widget.mealType, 'date': widget.date},
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add manually'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Recent', style: theme.textTheme.titleLarge),
        recentAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: LoadingView(),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (recent) {
            if (recent.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text('Foods you log will show up here.', style: theme.textTheme.labelLarge),
              );
            }
            return Column(
              children: [
                for (final entry in recent)
                  FoodListTile(
                    name: entry.foodName,
                    servingLabel: '${entry.servingSize} ${entry.servingUnit}',
                    calories: entry.foodId == null
                        ? entry.calories
                        : entry.calories / entry.quantity,
                    onTap: entry.foodId == null
                        ? null
                        : () => _openRecentFood(entry),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _openRecentFood(FoodLogEntry entry) async {
    final food = await ref.read(foodRepositoryProvider).getById(entry.foodId!);
    if (food != null && mounted) _openFood(food);
  }

  Widget _buildEmptyWithManualCta({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return EmptyStateView(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: 'Add manually',
      onAction: () => context.push(
        RoutePaths.logAddManual,
        extra: {'mealType': widget.mealType, 'date': widget.date},
      ),
    );
  }
}
