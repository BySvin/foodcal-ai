import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/weight_log_repository_impl.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/repositories/weight_log_repository.dart';

final weightLogRepositoryProvider = Provider<WeightLogRepository>((ref) {
  return WeightLogRepositoryImpl(ref.watch(firestoreProvider));
});

/// Last 90 days of weight entries, oldest first — chart- and history-ready.
final weightLogsProvider = StreamProvider<List<WeightEntry>>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(weightLogRepositoryProvider).watchRecent(uid, days: 90);
});

final weightLogControllerProvider =
    AsyncNotifierProvider<WeightLogController, void>(WeightLogController.new);

class WeightLogController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Failure?> logWeight(DateTime date, double weightKg, {String? note}) async {
    final uid = ref.read(authRepositoryProvider).currentUid;
    if (uid == null) return const AuthFailure('You need to be signed in to log your weight.');
    if (weightKg <= 0 || weightKg >= 500) {
      return const ValidationFailure('Enter a valid weight in kg.');
    }

    state = const AsyncLoading();
    final result = await ref.read(weightLogRepositoryProvider).logWeight(
          userId: uid,
          loggedDate: AppDateUtils.toDayKey(date),
          weightKg: weightKg,
          note: note,
        );

    return result.fold((_) {
      state = const AsyncData(null);
      logAnalyticsEvent(ref, 'log_weight');
      return null;
    }, (failure) {
      state = AsyncError(failure, StackTrace.current);
      return failure;
    });
  }
}
