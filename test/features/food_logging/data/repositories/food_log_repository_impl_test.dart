import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_calorie_tracker/features/food_logging/data/repositories/food_log_repository_impl.dart';
import 'package:food_calorie_tracker/features/food_logging/domain/entities/food_log_entry.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FoodLogRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FoodLogRepositoryImpl(firestore);
  });

  Future<String> logSample({
    String userId = 'uid-1',
    String foodId = 'apple',
    String foodName = 'Apple',
    String loggedDate = '2026-08-04',
    MealType mealType = MealType.breakfast,
    num quantity = 1,
  }) async {
    final result = await repository.logFood(
      userId: userId,
      foodId: foodId,
      foodName: foodName,
      servingSize: 1,
      servingUnit: 'medium',
      quantity: quantity,
      calories: 95 * quantity,
      proteinG: 0.5 * quantity,
      carbsG: 25 * quantity,
      fatG: 0.3 * quantity,
      mealType: mealType,
      loggedDate: loggedDate,
      source: LogSource.search,
    );
    return result.valueOrNull!;
  }

  group('logFood', () {
    test('creates a doc and returns its id on success', () async {
      final id = await logSample();
      final doc = await firestore.collection('food_logs').doc(id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['foodName'], 'Apple');
      expect(doc.data()!['mealType'], 'breakfast');
      expect(doc.data()!['source'], 'search');
    });
  });

  group('watchLogsForDate', () {
    test('returns only logs matching userId and loggedDate', () async {
      await logSample(loggedDate: '2026-08-04');
      await logSample(loggedDate: '2026-08-05'); // different day
      await logSample(userId: 'uid-2', loggedDate: '2026-08-04'); // different user

      final logs = await repository.watchLogsForDate('uid-1', '2026-08-04').first;
      expect(logs.length, 1);
      expect(logs.first.loggedDate, '2026-08-04');
      expect(logs.first.userId, 'uid-1');
    });

    test('returns an empty list when there are no logs for that day', () async {
      final logs = await repository.watchLogsForDate('uid-1', '2026-08-04').first;
      expect(logs, isEmpty);
    });
  });

  group('watchRecentFoods', () {
    test('dedupes repeated foods by foodId, keeping the most recent entry', () async {
      await logSample(foodId: 'apple', foodName: 'Apple');
      await logSample(foodId: 'apple', foodName: 'Apple'); // logged again, same food
      await logSample(foodId: 'banana', foodName: 'Banana');

      final recent = await repository.watchRecentFoods('uid-1').first;

      expect(recent.length, 2);
      expect(recent.map((e) => e.foodId).toSet(), {'apple', 'banana'});
    });

    test('only returns foods for the given user', () async {
      await logSample(userId: 'uid-1', foodId: 'apple');
      await logSample(userId: 'uid-2', foodId: 'banana');

      final recent = await repository.watchRecentFoods('uid-1').first;
      expect(recent.map((e) => e.foodId), ['apple']);
    });
  });

  group('updateLogQuantity', () {
    test('updates quantity and recomputed totals', () async {
      final id = await logSample(quantity: 1);

      final result = await repository.updateLogQuantity(
        logId: id,
        quantity: 2,
        calories: 190,
        proteinG: 1,
        carbsG: 50,
        fatG: 0.6,
      );

      expect(result.isSuccess, isTrue);
      final doc = await firestore.collection('food_logs').doc(id).get();
      expect(doc.data()!['quantity'], 2);
      expect(doc.data()!['calories'], 190);
    });
  });

  group('deleteLog', () {
    test('removes the doc', () async {
      final id = await logSample();
      final result = await repository.deleteLog(id);
      expect(result.isSuccess, isTrue);
      final doc = await firestore.collection('food_logs').doc(id).get();
      expect(doc.exists, isFalse);
    });
  });
}
