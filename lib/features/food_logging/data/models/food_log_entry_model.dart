import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/food_log_entry.dart';

class FoodLogEntryModel {
  const FoodLogEntryModel._();

  static FoodLogEntry fromMap(String id, Map<String, dynamic> map) {
    return FoodLogEntry(
      id: id,
      userId: map['userId'] as String? ?? '',
      foodId: map['foodId'] as String?,
      foodName: map['foodName'] as String? ?? '',
      servingSize: (map['servingSize'] as num?) ?? 1,
      servingUnit: map['servingUnit'] as String? ?? '',
      quantity: (map['quantity'] as num?) ?? 1,
      calories: (map['calories'] as num?) ?? 0,
      proteinG: (map['proteinG'] as num?) ?? 0,
      carbsG: (map['carbsG'] as num?) ?? 0,
      fatG: (map['fatG'] as num?) ?? 0,
      mealType: _mealTypeFromString(map['mealType'] as String?),
      loggedDate: map['loggedDate'] as String? ?? '',
      loggedAt: (map['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      source: _sourceFromString(map['source'] as String?),
    );
  }

  static FoodLogEntry fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return fromMap(snapshot.id, snapshot.data()!);
  }

  static Map<String, dynamic> toCreateMap({
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
  }) {
    return {
      'userId': userId,
      'foodId': foodId,
      'foodName': foodName,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'quantity': quantity,
      'calories': calories,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatG': fatG,
      'mealType': _mealTypeToString(mealType),
      'loggedDate': loggedDate,
      'loggedAt': FieldValue.serverTimestamp(),
      'source': _sourceToString(source),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static MealType _mealTypeFromString(String? value) => switch (value) {
        'breakfast' => MealType.breakfast,
        'lunch' => MealType.lunch,
        'dinner' => MealType.dinner,
        _ => MealType.snack,
      };

  static String _mealTypeToString(MealType value) => switch (value) {
        MealType.breakfast => 'breakfast',
        MealType.lunch => 'lunch',
        MealType.dinner => 'dinner',
        MealType.snack => 'snack',
      };

  static LogSource _sourceFromString(String? value) => switch (value) {
        'search' => LogSource.search,
        'favorite' => LogSource.favorite,
        _ => LogSource.manual,
      };

  static String _sourceToString(LogSource value) => switch (value) {
        LogSource.search => 'search',
        LogSource.manual => 'manual',
        LogSource.favorite => 'favorite',
      };
}
