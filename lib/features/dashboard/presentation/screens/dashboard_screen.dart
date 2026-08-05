import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/date_providers.dart';
import '../../../../core/widgets/date_nav_header.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../food_logging/presentation/providers/food_log_providers.dart';
import '../../../water_tracker/presentation/widgets/water_tracker_card.dart';
import '../widgets/nutrition_summary_view.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final appUserAsync = ref.watch(appUserProvider);

    return Scaffold(
      appBar: AppBar(title: DateNavHeader(date: date)),
      body: SafeArea(
        child: appUserAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: 'Could not load your profile.',
            onRetry: () => ref.invalidate(appUserProvider),
          ),
          data: (appUser) {
            if (appUser == null) return const LoadingView();
            return _DashboardBody(
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

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
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
    final summary = ref.watch(dailyNutritionSummaryProvider(date));

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
      ],
    );
  }
}
