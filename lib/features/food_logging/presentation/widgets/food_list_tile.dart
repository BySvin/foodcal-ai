import 'package:flutter/material.dart';

/// Reusable row for a food entry — used in search results, recent foods,
/// and favorites, which each source from a different entity type but
/// render identically.
class FoodListTile extends StatelessWidget {
  const FoodListTile({
    super.key,
    required this.name,
    required this.servingLabel,
    required this.calories,
    this.onTap,
    this.trailing,
  });

  final String name;
  final String servingLabel;
  final num calories;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(name, style: theme.textTheme.bodyMedium),
      subtitle: Text(servingLabel, style: theme.textTheme.labelLarge),
      trailing: trailing ??
          Text('${calories.round()} kcal', style: theme.textTheme.labelLarge),
    );
  }
}
