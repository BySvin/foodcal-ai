import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/food_item.dart';

class FoodItemModel {
  const FoodItemModel._();

  static FoodItem fromMap(String id, Map<String, dynamic> map) {
    return FoodItem(
      id: id,
      name: map['name'] as String? ?? '',
      brand: map['brand'] as String?,
      servingSize: (map['servingSize'] as num?) ?? 1,
      servingUnit: map['servingUnit'] as String? ?? '',
      calories: (map['calories'] as num?) ?? 0,
      proteinG: (map['proteinG'] as num?) ?? 0,
      carbsG: (map['carbsG'] as num?) ?? 0,
      fatG: (map['fatG'] as num?) ?? 0,
      category: map['category'] as String? ?? 'other',
      isCustom: map['isCustom'] as bool? ?? false,
      createdBy: map['createdBy'] as String?,
    );
  }

  static FoodItem? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) return null;
    return fromMap(snapshot.id, data);
  }
}
