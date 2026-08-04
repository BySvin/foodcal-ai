import 'package:flutter/material.dart';

/// Single-select list of tappable option cards — used for Gender, Activity
/// Level, and Goal, where a dropdown would hide the choices and radio
/// buttons would look cramped for descriptive multi-line options.
class OptionSelector<T> extends StatelessWidget {
  const OptionSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<OnboardingOption<T>> options;
  final T? selected;
  final void Function(T) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        for (final option in options) ...[
          _OptionCard(
            option: option,
            isSelected: option.value == selected,
            onTap: () => onSelected(option.value),
            theme: theme,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class OnboardingOption<T> {
  const OnboardingOption({required this.value, required this.label, this.description});

  final T value;
  final String label;
  final String? description;
}

class _OptionCard<T> extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  final OnboardingOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? theme.colorScheme.primary : theme.dividerColor;
    final backgroundColor =
        isSelected ? theme.colorScheme.primary.withValues(alpha: 0.08) : theme.colorScheme.surface;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.label, style: theme.textTheme.bodyMedium),
                    if (option.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.description!,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
