import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../routing/route_paths.dart';
import '../../../food_logging/presentation/providers/food_log_providers.dart';

const _historyDayCount = 30;

/// Last 30 days, most recent first. Each row is a lightweight per-day
/// aggregation (calories only, via the same dailyNutritionSummaryProvider
/// the Dashboard uses) — full macro/water/weight detail lives on
/// /history/:date, reached by tapping a row.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(_historyDayCount, (i) => AppDateUtils.addDays(today, -i));

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: days.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) => _HistoryDayTile(date: days[index]),
        ),
      ),
    );
  }
}

class _HistoryDayTile extends ConsumerWidget {
  const _HistoryDayTile({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dailyNutritionSummaryProvider(date));
    final theme = Theme.of(context);
    final isToday = AppDateUtils.isToday(date);
    final hasLogs = summary.calories > 0;

    return ListTile(
      onTap: () => context.push(RoutePaths.historyDate(AppDateUtils.toDayKey(date))),
      title: Text(
        isToday ? 'Today' : '${date.month}/${date.day}/${date.year}',
        style: theme.textTheme.bodyMedium,
      ),
      trailing: Text(
        hasLogs ? '${summary.calories.round()} kcal' : 'No logs',
        style: theme.textTheme.labelLarge,
      ),
    );
  }
}
