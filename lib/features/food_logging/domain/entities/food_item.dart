/// A `foods/{id}` catalog entry — either seeded (`isCustom: false`,
/// `createdBy: null`) or user-submitted (M5).
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.category,
    required this.isCustom,
    this.brand,
    this.createdBy,
  });

  final String id;
  final String name;
  final String? brand;
  final num servingSize;
  final String servingUnit;
  final num calories;
  final num proteinG;
  final num carbsG;
  final num fatG;
  final String category;
  final bool isCustom;
  final String? createdBy;
}
