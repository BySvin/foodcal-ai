/// A `favorites/{uid}_{foodId}` entry — a denormalized snapshot of a
/// catalog food the user has starred for fast re-logging.
class FavoriteFood {
  const FavoriteFood({
    required this.id,
    required this.userId,
    required this.foodId,
    required this.foodName,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final String id;
  final String userId;
  final String foodId;
  final String foodName;
  final num servingSize;
  final String servingUnit;
  final num calories;
  final num proteinG;
  final num carbsG;
  final num fatG;
}
