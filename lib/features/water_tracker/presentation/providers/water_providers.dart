import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/water_log_repository_impl.dart';
import '../../domain/entities/water_day.dart';
import '../../domain/repositories/water_log_repository.dart';

const _defaultWaterGoalMl = 2000;

final waterLogRepositoryProvider = Provider<WaterLogRepository>((ref) {
  return WaterLogRepositoryImpl(ref.watch(firestoreProvider));
});

/// The signed-in user's current water goal — from onboarding, falling back
/// to a sane default before that's ever been computed.
final waterGoalProvider = Provider<int>((ref) {
  final appUser = ref.watch(appUserProvider).valueOrNull;
  return appUser?.dailyWaterTargetMl ?? _defaultWaterGoalMl;
});

/// A day's water progress. Never null — defaults to zero logged against
/// the user's current goal when no doc exists yet for that day.
final dailyWaterProvider = StreamProvider.family<WaterDay, DateTime>((ref, date) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  final dayKey = AppDateUtils.toDayKey(date);
  final goal = ref.watch(waterGoalProvider);

  if (uid == null) {
    return Stream.value(WaterDay(date: dayKey, totalMl: 0, goalMl: goal));
  }

  return ref.watch(waterLogRepositoryProvider).watchDay(uid, dayKey).map(
        (day) => day ?? WaterDay(date: dayKey, totalMl: 0, goalMl: goal),
      );
});

final waterLogControllerProvider =
    AsyncNotifierProvider<WaterLogController, void>(WaterLogController.new);

class WaterLogController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Failure?> addWater(DateTime date, int amountMl) async {
    final uid = ref.read(authRepositoryProvider).currentUid;
    if (uid == null) return const AuthFailure('You need to be signed in to log water.');

    final result = await ref.read(waterLogRepositoryProvider).addWater(
          uid,
          AppDateUtils.toDayKey(date),
          amountMl: amountMl,
          goalMl: ref.read(waterGoalProvider),
        );
    return result.fold((_) => null, (failure) => failure);
  }

  Future<Failure?> undoLastAdd(DateTime date) async {
    final uid = ref.read(authRepositoryProvider).currentUid;
    if (uid == null) return const AuthFailure('You need to be signed in to do that.');

    final result =
        await ref.read(waterLogRepositoryProvider).undoLastAdd(uid, AppDateUtils.toDayKey(date));
    return result.fold((_) => null, (failure) => failure);
  }
}
