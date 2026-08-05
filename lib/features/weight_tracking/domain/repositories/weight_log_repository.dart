import '../../../../core/error/result.dart';
import '../entities/weight_entry.dart';

abstract class WeightLogRepository {
  /// Entries from the last [days] days, oldest first (chart-ready order).
  Stream<List<WeightEntry>> watchRecent(String userId, {int days = 90});

  /// Upserts by the deterministic `{userId}_{loggedDate}` doc id — logging
  /// the same day twice overwrites the previous entry rather than adding
  /// a second one.
  Future<Result<void>> logWeight({
    required String userId,
    required String loggedDate,
    required double weightKg,
    String? note,
  });
}
