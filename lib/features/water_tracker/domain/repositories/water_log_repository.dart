import '../../../../core/error/result.dart';
import '../entities/water_day.dart';

abstract class WaterLogRepository {
  /// Emits null when no doc exists yet for that day (nothing logged).
  Stream<WaterDay?> watchDay(String userId, String date);

  /// Atomically increments the day's total (creating the doc on first add)
  /// and records [amountMl] as undoable via [undoLastAdd]. [goalMl] is only
  /// used if the doc doesn't exist yet — it snapshots that day's target.
  Future<Result<void>> addWater(
    String userId,
    String date, {
    required int amountMl,
    required int goalMl,
  });

  /// Reverts the single most recent add for that day. A no-op success if
  /// there's nothing to undo.
  Future<Result<void>> undoLastAdd(String userId, String date);
}
