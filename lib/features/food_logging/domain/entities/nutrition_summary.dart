import 'food_log_entry.dart';

/// Aggregated totals for a set of food log entries — the numbers the
/// Dashboard's calorie ring and macro bars are built from.
class NutritionSummary {
  const NutritionSummary({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final num calories;
  final num proteinG;
  final num carbsG;
  final num fatG;

  static const zero = NutritionSummary(calories: 0, proteinG: 0, carbsG: 0, fatG: 0);

  factory NutritionSummary.fromLogs(List<FoodLogEntry> logs) {
    num calories = 0, protein = 0, carbs = 0, fat = 0;
    for (final log in logs) {
      calories += log.calories;
      protein += log.proteinG;
      carbs += log.carbsG;
      fat += log.fatG;
    }
    return NutritionSummary(calories: calories, proteinG: protein, carbsG: carbs, fatG: fat);
  }
}
