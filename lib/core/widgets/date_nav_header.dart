import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/date_providers.dart';
import '../utils/date_utils.dart';

/// Prev/next day navigation bound to [selectedDateProvider] — shared by
/// any screen keyed off "which day am I looking at" (Dashboard, Log,
/// History).
class DateNavHeader extends ConsumerWidget {
  const DateNavHeader({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isToday = AppDateUtils.isToday(date);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous day',
          onPressed: () => ref.read(selectedDateProvider.notifier).state =
              AppDateUtils.addDays(date, -1),
        ),
        Text(isToday ? 'Today' : '${date.month}/${date.day}/${date.year}'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next day',
          onPressed: isToday
              ? null
              : () => ref.read(selectedDateProvider.notifier).state =
                    AppDateUtils.addDays(date, 1),
        ),
      ],
    );
  }
}
