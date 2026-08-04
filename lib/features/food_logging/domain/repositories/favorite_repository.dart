import '../../../../core/error/result.dart';
import '../entities/favorite_food.dart';
import '../entities/food_item.dart';

abstract class FavoriteRepository {
  Stream<List<FavoriteFood>> watchFavorites(String userId);

  Future<Result<void>> addFavorite(String userId, FoodItem food);

  Future<Result<void>> removeFavorite(String userId, String foodId);
}
