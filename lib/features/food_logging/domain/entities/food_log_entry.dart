enum MealType { breakfast, lunch, dinner, snack }

enum LogSource { search, manual, favorite }

/// A `food_logs/{id}` entry — a denormalized snapshot of what was eaten,
/// independent of later edits to the source `foods` doc (historical
/// accuracy: if a catalog food's calories are corrected later, past logs
/// are unaffected).
class FoodLogEntry {
  const FoodLogEntry({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.servingSize,
    required this.servingUnit,
    required this.quantity,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.mealType,
    required this.loggedDate,
    required this.loggedAt,
    required this.source,
    this.foodId,
  });

  final String id;
  final String userId;
  final String? foodId;
  final String foodName;
  final num servingSize;
  final String servingUnit;
  final num quantity;
  final num calories;
  final num proteinG;
  final num carbsG;
  final num fatG;
  final MealType mealType;
  final String loggedDate;
  final DateTime loggedAt;
  final LogSource source;

  FoodLogEntry copyWith({num? quantity, num? calories, num? proteinG, num? carbsG, num? fatG}) {
    return FoodLogEntry(
      id: id,
      userId: userId,
      foodId: foodId,
      foodName: foodName,
      servingSize: servingSize,
      servingUnit: servingUnit,
      quantity: quantity ?? this.quantity,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      mealType: mealType,
      loggedDate: loggedDate,
      loggedAt: loggedAt,
      source: source,
    );
  }
}
