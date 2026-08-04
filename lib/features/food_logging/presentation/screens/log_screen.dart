import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/date_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_paths.dart';
import '../../domain/entities/food_log_entry.dart';
import '../providers/food_log_providers.dart';
import '../widgets/meal_section.dart';

class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final logsAsync = ref.watch(dailyFoodLogsProvider(date));

    return Scaffold(
      appBar: AppBar(title: _DateHeader(date: date)),
      body: SafeArea(
        child: logsAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: 'Could not load your food log.',
            onRetry: () => ref.invalidate(dailyFoodLogsProvider(date)),
          ),
          data: (logs) => _MealSectionList(date: date, logs: logs),
        ),
      ),
    );
  }
}

class _DateHeader extends ConsumerWidget {
  const _DateHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isToday = AppDateUtils.isToday(date);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => ref.read(selectedDateProvider.notifier).state =
              AppDateUtils.addDays(date, -1),
        ),
        Text(isToday ? 'Today' : '${date.month}/${date.day}/${date.year}'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isToday
              ? null
              : () => ref.read(selectedDateProvider.notifier).state =
                  AppDateUtils.addDays(date, 1),
        ),
      ],
    );
  }
}

class _MealSectionList extends ConsumerWidget {
  const _MealSectionList({required this.date, required this.logs});

  final DateTime date;
  final List<FoodLogEntry> logs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byMeal = <MealType, List<FoodLogEntry>>{
      for (final type in MealType.values) type: [],
    };
    for (final log in logs) {
      byMeal[log.mealType]!.add(log);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (final type in MealType.values) ...[
          MealSection(
            mealType: type,
            entries: byMeal[type]!,
            onAddFood: () => context.push(RoutePaths.logSearch, extra: {
              'mealType': type,
              'date': date,
            }),
            onEditEntry: (entry) => _showEditSheet(context, ref, entry),
            onDeleteEntry: (entry) => ref.read(foodLogControllerProvider.notifier).deleteLog(entry.id),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, FoodLogEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditQuantitySheet(entry: entry),
    );
  }
}

class _EditQuantitySheet extends ConsumerStatefulWidget {
  const _EditQuantitySheet({required this.entry});

  final FoodLogEntry entry;

  @override
  ConsumerState<_EditQuantitySheet> createState() => _EditQuantitySheetState();
}

class _EditQuantitySheetState extends ConsumerState<_EditQuantitySheet> {
  late num _quantity = widget.entry.quantity;

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(foodLogControllerProvider).isLoading;
    final perServingCalories = widget.entry.calories / widget.entry.quantity;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.entry.foodName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity = _quantity - 1)
                    : null,
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.statNumber,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _quantity = _quantity + 1),
              ),
            ],
          ),
          Center(
            child: Text(
              '${(perServingCalories * _quantity).round()} kcal',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Save',
            isLoading: isLoading,
            onPressed: () async {
              final failure = await ref
                  .read(foodLogControllerProvider.notifier)
                  .updateQuantity(widget.entry, _quantity);
              if (context.mounted) {
                if (failure != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(failure.message)));
                } else {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Delete',
            variant: AppButtonVariant.text,
            onPressed: () async {
              await ref.read(foodLogControllerProvider.notifier).deleteLog(widget.entry.id);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
