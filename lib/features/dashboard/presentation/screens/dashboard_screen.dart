import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/date_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/date_nav_header.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/macro_bar.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../food_logging/presentation/providers/food_log_providers.dart';
import '../../../water_tracker/presentation/widgets/water_tracker_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final appUserAsync = ref.watch(appUserProvider);

    return Scaffold(
      appBar: AppBar(title: DateNavHeader(date: date)),
      body: SafeArea(
        child: appUserAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: 'Could not load your profile.',
            onRetry: () => ref.invalidate(appUserProvider),
          ),
          data: (appUser) {
            if (appUser == null) return const LoadingView();
            return _DashboardBody(
              date: date,
              calorieTarget: appUser.dailyCalorieTarget ?? 2000,
              proteinTarget: appUser.macroTargets?.proteinG ?? 0,
              carbsTarget: appUser.macroTargets?.carbsG ?? 0,
              fatTarget: appUser.macroTargets?.fatG ?? 0,
            );
          },
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
    required this.date,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
  });

  final DateTime date;
  final int calorieTarget;
  final int proteinTarget;
  final int carbsTarget;
  final int fatTarget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dailyNutritionSummaryProvider(date));
    final theme = Theme.of(context);

    final remaining = calorieTarget - summary.calories;
    final isOverBudget = remaining < 0;
    final progress = calorieTarget <= 0
        ? 0.0
        : summary.calories / calorieTarget;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Center(
          child: ProgressRing(
            progress: progress,
            color: isOverBudget ? AppColors.danger : theme.colorScheme.primary,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${remaining.abs().round()}',
                  style: AppTextStyles.display.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  isOverBudget ? 'kcal over' : 'kcal remaining',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            '${summary.calories.round()} / $calorieTarget kcal consumed',
            style: theme.textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                MacroBar(
                  label: 'Protein',
                  consumed: summary.proteinG,
                  target: proteinTarget,
                  unit: 'g',
                  color: AppColors.proteinColor,
                ),
                const SizedBox(height: AppSpacing.md),
                MacroBar(
                  label: 'Carbs',
                  consumed: summary.carbsG,
                  target: carbsTarget,
                  unit: 'g',
                  color: AppColors.carbsColor,
                ),
                const SizedBox(height: AppSpacing.md),
                MacroBar(
                  label: 'Fat',
                  consumed: summary.fatG,
                  target: fatTarget,
                  unit: 'g',
                  color: AppColors.fatColor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        WaterTrackerCard(date: date),
      ],
    );
  }
}
