import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/macro_bar.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../../core/widgets/staggered_fade_in.dart';
import '../../../food_logging/domain/entities/nutrition_summary.dart';

/// The calorie ring + macro bars composition — shared by the Dashboard
/// (today, editable via the embedded WaterTrackerCard) and Daily History's
/// per-day detail (a past day, read-only aside from backfilling water).
class NutritionSummaryView extends StatelessWidget {
  const NutritionSummaryView({
    super.key,
    required this.summary,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
  });

  final NutritionSummary summary;
  final int calorieTarget;
  final int proteinTarget;
  final int carbsTarget;
  final int fatTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = calorieTarget - summary.calories;
    final isOverBudget = remaining < 0;
    final progress = calorieTarget <= 0 ? 0.0 : summary.calories / calorieTarget;

    return Column(
      children: [
        StaggeredFadeIn(
          index: 0,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isOverBudget ? AppColors.danger : AppColors.accent)
                        .withValues(alpha: 0.18),
                    blurRadius: 32,
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: ProgressRing(
                progress: progress,
                color: isOverBudget ? AppColors.danger : null,
                gradientColors:
                    isOverBudget ? null : [AppColors.accent, AppColors.accentGradientEnd],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: remaining.abs().round()),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Text(
                        '$value',
                        style: AppTextStyles.display.copyWith(color: theme.colorScheme.onSurface),
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
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        StaggeredFadeIn(
          index: 0,
          child: Center(
            child: Text(
              '${summary.calories.round()} / $calorieTarget kcal consumed',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        StaggeredFadeIn(
          index: 1,
          child: Card(
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
        ),
      ],
    );
  }
}
