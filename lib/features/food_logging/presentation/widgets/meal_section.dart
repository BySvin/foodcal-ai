import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/food_log_entry.dart';

const Map<MealType, String> mealTypeLabels = {
  MealType.breakfast: 'Breakfast',
  MealType.lunch: 'Lunch',
  MealType.dinner: 'Dinner',
  MealType.snack: 'Snacks',
};

/// One meal group in the /log screen — header with subtotal, an entry per
/// logged food (swipe to delete, tap to edit quantity), and an "Add food"
/// row.
class MealSection extends StatelessWidget {
  const MealSection({
    super.key,
    required this.mealType,
    required this.entries,
    required this.onAddFood,
    required this.onEditEntry,
    required this.onDeleteEntry,
  });

  final MealType mealType;
  final List<FoodLogEntry> entries;
  final VoidCallback onAddFood;
  final void Function(FoodLogEntry) onEditEntry;
  final void Function(FoodLogEntry) onDeleteEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = entries.fold<num>(0, (sum, e) => sum + e.calories);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(mealTypeLabels[mealType]!, style: theme.textTheme.titleLarge),
                if (entries.isNotEmpty)
                  Text('${subtotal.round()} kcal', style: theme.textTheme.labelLarge),
              ],
            ),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text('No foods logged yet', style: theme.textTheme.labelLarge),
              )
            else
              for (final entry in entries)
                Dismissible(
                  key: ValueKey(entry.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => onDeleteEntry(entry),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => onEditEntry(entry),
                    title: Text(entry.foodName, style: theme.textTheme.bodyMedium),
                    subtitle: Text(
                      '${entry.quantity} x ${entry.servingSize} ${entry.servingUnit}',
                      style: theme.textTheme.labelLarge,
                    ),
                    trailing: Text(
                      '${entry.calories.round()} kcal',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ),
            TextButton.icon(
              onPressed: onAddFood,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add food'),
            ),
          ],
        ),
      ),
    );
  }
}
