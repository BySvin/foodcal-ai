import '../entities/food_item.dart';

/// Abstract interface over the shared `foods` catalog. Search/lookup only
/// at this stage — custom-food creation is added in the Food Logging
/// milestone alongside the manual-add UI that needs it.
abstract class FoodRepository {
  Future<List<FoodItem>> search(String query, {int limit = 20});

  Future<FoodItem?> getById(String id);
}
