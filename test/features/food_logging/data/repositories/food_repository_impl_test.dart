import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_calorie_tracker/features/food_logging/data/repositories/food_repository_impl.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FoodRepositoryImpl repository;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    repository = FoodRepositoryImpl(firestore);

    final foods = [
      {'id': 'apple', 'name': 'Apple', 'nameLower': 'apple', 'calories': 95},
      {'id': 'apple-pie', 'name': 'Apple pie', 'nameLower': 'apple pie', 'calories': 296},
      {'id': 'banana', 'name': 'Banana', 'nameLower': 'banana', 'calories': 105},
      {'id': 'avocado', 'name': 'Avocado', 'nameLower': 'avocado', 'calories': 160},
    ];
    for (final food in foods) {
      await firestore.collection('foods').doc(food['id'] as String).set({
        ...food,
        'servingSize': 1,
        'servingUnit': 'unit',
        'proteinG': 1,
        'carbsG': 1,
        'fatG': 1,
        'category': 'fruit',
        'isCustom': false,
        'createdBy': null,
      });
    }
  });

  group('search', () {
    test('returns an empty list for a blank query', () async {
      final results = await repository.search('   ');
      expect(results, isEmpty);
    });

    test('matches by case-insensitive prefix', () async {
      final results = await repository.search('App');
      final names = results.map((f) => f.name).toList();
      expect(names, containsAll(['Apple', 'Apple pie']));
      expect(names, isNot(contains('Banana')));
    });

    test('matches a distinct prefix independently', () async {
      final results = await repository.search('ba');
      expect(results.map((f) => f.name), ['Banana']);
    });

    test('respects the limit parameter', () async {
      final results = await repository.search('a', limit: 1);
      expect(results.length, 1);
    });
  });

  group('getById', () {
    test('returns the matching food', () async {
      final food = await repository.getById('avocado');
      expect(food, isNotNull);
      expect(food!.name, 'Avocado');
      expect(food.calories, 160);
    });

    test('returns null for a missing id', () async {
      final food = await repository.getById('does-not-exist');
      expect(food, isNull);
    });
  });
}
