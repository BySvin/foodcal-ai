import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/widgets/nutrition_summary_view.dart';
import '../../../food_logging/presentation/providers/food_log_providers.dart';
import '../../../water_tracker/presentation/providers/water_providers.dart';
import '../../../water_tracker/presentation/widgets/water_tracker_card.dart';
import '../../../weight_tracking/domain/entities/weight_entry.dart';
import '../../../weight_tracking/presentation/providers/weight_providers.dart';

/// Read-only(-ish) view of a past day, reusing Dashboard's
/// NutritionSummaryView. WaterTrackerCard is still interactive — it's
/// already date-aware, so this doubles as a way to backfill a missed day's
/// water, consistent with /log already allowing past-date food entries.
class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(appUserProvider);
    final label = AppDateUtils.isToday(date)
        ? 'Today'
        : '${date.month}/${date.day}/${date.year}';

    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: SafeArea(
        child: appUserAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: 'Could not load this day.',
            onRetry: () => ref.invalidate(appUserProvider),
          ),
          data: (appUser) {
            if (appUser == null) return const LoadingView();
            return _HistoryDetailBody(
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

class _HistoryDetailBody extends ConsumerWidget {
  const _HistoryDetailBody({
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
    final logsAsync = ref.watch(dailyFoodLogsProvider(date));

    return logsAsync.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        message: 'Could not load this day.',
        onRetry: () => ref.invalidate(dailyFoodLogsProvider(date)),
      ),
      data: (logs) {
        final summary = ref.watch(dailyNutritionSummaryProvider(date));
        final water = ref.watch(dailyWaterProvider(date)).valueOrNull;
        final dayKey = AppDateUtils.toDayKey(date);
        final weightEntries = ref.watch(weightLogsProvider).valueOrNull ?? const [];
        WeightEntry? weightEntry;
        for (final entry in weightEntries) {
          if (entry.loggedDate == dayKey) {
            weightEntry = entry;
            break;
          }
        }

        final hasAnyLogs = logs.isNotEmpty || (water?.totalMl ?? 0) > 0 || weightEntry != null;

        if (!hasAnyLogs) {
          return const EmptyStateView(
            icon: Icons.event_busy_rounded,
            title: 'No logs for this day',
            subtitle: 'Nothing was recorded on this date.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            NutritionSummaryView(
              summary: summary,
              calorieTarget: calorieTarget,
              proteinTarget: proteinTarget,
              carbsTarget: carbsTarget,
              fatTarget: fatTarget,
            ),
            const SizedBox(height: AppSpacing.md),
            WaterTrackerCard(date: date),
            if (weightEntry != null) ...[
              const SizedBox(height: AppSpacing.md),
              _WeightSummaryCard(weightKg: weightEntry.weightKg),
            ],
          ],
        );
      },
    );
  }
}

class _WeightSummaryCard extends StatelessWidget {
  const _WeightSummaryCard({required this.weightKg});

  final double weightKg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Weight', style: theme.textTheme.bodyMedium),
            Text('$weightKg kg', style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
