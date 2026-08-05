import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/weight_entry.dart';
import '../providers/weight_providers.dart';
import '../widgets/weight_chart.dart';

class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({super.key});

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _logToday() async {
    final weightKg = double.tryParse(_weightController.text.trim());
    if (weightKg == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid weight in kg.')));
      return;
    }

    final note = _noteController.text.trim();
    final failure = await ref.read(weightLogControllerProvider.notifier).logWeight(
          DateTime.now(),
          weightKg,
          note: note.isEmpty ? null : note,
        );

    if (!mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    } else {
      _weightController.clear();
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Weight logged.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(weightLogsProvider);
    final isLoading = ref.watch(weightLogControllerProvider).isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Weight')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Today's weight", style: theme.textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _weightController,
                            label: 'Weight (kg)',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(controller: _noteController, label: 'Note (optional)'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(label: 'Save', isLoading: isLoading, onPressed: _logToday),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            entriesAsync.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: 'Could not load your weight history.',
                onRetry: () => ref.invalidate(weightLogsProvider),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.show_chart_rounded,
                    title: 'No entries yet',
                    subtitle: 'Log your weight above to start tracking your trend.',
                  );
                }
                final reversed = entries.reversed.toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WeightChart(entries: entries),
                    const SizedBox(height: AppSpacing.lg),
                    Text('History', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    for (final entry in reversed) _WeightHistoryTile(entry: entry),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightHistoryTile extends StatelessWidget {
  const _WeightHistoryTile({required this.entry});

  final WeightEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = AppDateUtils.fromDayKey(entry.loggedDate);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${entry.weightKg} kg', style: theme.textTheme.bodyMedium),
      subtitle: entry.note != null ? Text(entry.note!, style: theme.textTheme.labelLarge) : null,
      trailing: Text(
        '${date.month}/${date.day}/${date.year}',
        style: theme.textTheme.labelLarge,
      ),
    );
  }
}
