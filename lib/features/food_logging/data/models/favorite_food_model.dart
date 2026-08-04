import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/favorite_food.dart';
import '../../domain/entities/food_item.dart';

class FavoriteFoodModel {
  const FavoriteFoodModel._();

  static FavoriteFood fromMap(String id, Map<String, dynamic> map) {
    return FavoriteFood(
      id: id,
      userId: map['userId'] as String? ?? '',
      foodId: map['foodId'] as String? ?? '',
      foodName: map['foodName'] as String? ?? '',
      servingSize: (map['servingSize'] as num?) ?? 1,
      servingUnit: map['servingUnit'] as String? ?? '',
      calories: (map['calories'] as num?) ?? 0,
      proteinG: (map['proteinG'] as num?) ?? 0,
      carbsG: (map['carbsG'] as num?) ?? 0,
      fatG: (map['fatG'] as num?) ?? 0,
    );
  }

  static FavoriteFood fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return fromMap(snapshot.id, snapshot.data()!);
  }

  static Map<String, dynamic> toCreateMap(String userId, FoodItem food) {
    return {
      'userId': userId,
      'foodId': food.id,
      'foodName': food.name,
      'servingSize': food.servingSize,
      'servingUnit': food.servingUnit,
      'calories': food.calories,
      'proteinG': food.proteinG,
      'carbsG': food.carbsG,
      'fatG': food.fatG,
      'addedAt': FieldValue.serverTimestamp(),
    };
  }
}
