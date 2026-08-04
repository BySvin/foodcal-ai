import '../../../../core/error/result.dart';
import '../entities/food_log_entry.dart';

abstract class FoodLogRepository {
  Stream<List<FoodLogEntry>> watchLogsForDate(String userId, String loggedDate);

  /// Most recent distinct-by-food log entries for the user, most recent
  /// first — powers the "Recent" section of the food search screen.
  Stream<List<FoodLogEntry>> watchRecentFoods(String userId, {int limit = 20});

  Future<Result<String>> logFood({
    required String userId,
    required String? foodId,
    required String foodName,
    required num servingSize,
    required String servingUnit,
    required num quantity,
    required num calories,
    required num proteinG,
    required num carbsG,
    required num fatG,
    required MealType mealType,
    required String loggedDate,
    required LogSource source,
  });

  /// Callers recompute [calories]/[proteinG]/[carbsG]/[fatG] from the
  /// per-serving ratio before calling this — the repository stores
  /// whatever totals it's given, it doesn't derive them.
  Future<Result<void>> updateLogQuantity({
    required String logId,
    required num quantity,
    required num calories,
    required num proteinG,
    required num carbsG,
    required num fatG,
  });

  Future<Result<void>> deleteLog(String logId);
}
