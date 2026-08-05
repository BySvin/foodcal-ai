import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/macro_bar.dart';
import '../providers/water_providers.dart';

const _quickAddAmounts = [250, 500];

/// Self-contained water card: progress bar, quick-add buttons, and a
/// one-step undo — meant to be embedded on the Dashboard.
class WaterTrackerCard extends ConsumerWidget {
  const WaterTrackerCard({super.key, required this.date});

  final DateTime date;

  Future<void> _addWater(BuildContext context, WidgetRef ref, int amountMl) async {
    final failure = await ref.read(waterLogControllerProvider.notifier).addWater(date, amountMl);
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _promptCustomAmount(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add water'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (ml)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(int.tryParse(controller.text)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (amount != null && amount > 0 && context.mounted) {
      await _addWater(context, ref, amount);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterAsync = ref.watch(dailyWaterProvider(date));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: waterAsync.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          ),
          error: (_, _) => const Text('Could not load water intake.'),
          data: (day) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MacroBar(
                label: 'Water',
                consumed: day.totalMl,
                target: day.goalMl,
                unit: 'ml',
                color: AppColors.waterColor,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  for (final amount in _quickAddAmounts) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _addWater(context, ref, amount),
                        child: Text('+$amount ml'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _promptCustomAmount(context, ref),
                      child: const Text('Custom'),
                    ),
                  ),
                ],
              ),
              if (day.lastAddedMl != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => ref.read(waterLogControllerProvider.notifier).undoLastAdd(date),
                    child: Text('Undo +${day.lastAddedMl} ml', style: theme.textTheme.labelLarge),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
