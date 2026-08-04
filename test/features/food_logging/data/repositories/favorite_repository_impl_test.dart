import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_calorie_tracker/features/food_logging/data/repositories/favorite_repository_impl.dart';
import 'package:food_calorie_tracker/features/food_logging/domain/entities/food_item.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FavoriteRepositoryImpl repository;

  const food = FoodItem(
    id: 'apple',
    name: 'Apple',
    servingSize: 1,
    servingUnit: 'medium',
    calories: 95,
    proteinG: 0.5,
    carbsG: 25,
    fatG: 0.3,
    category: 'fruit',
    isCustom: false,
  );

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FavoriteRepositoryImpl(firestore);
  });

  group('addFavorite', () {
    test('creates a doc with a deterministic uid_foodId id', () async {
      final result = await repository.addFavorite('uid-1', food);
      expect(result.isSuccess, isTrue);

      final doc = await firestore.collection('favorites').doc('uid-1_apple').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['foodName'], 'Apple');
      expect(doc.data()!['userId'], 'uid-1');
    });

    test('is idempotent — adding twice does not create a duplicate', () async {
      await repository.addFavorite('uid-1', food);
      await repository.addFavorite('uid-1', food);

      final favorites = await repository.watchFavorites('uid-1').first;
      expect(favorites.length, 1);
    });
  });

  group('watchFavorites', () {
    test('only returns favorites for the given user', () async {
      await repository.addFavorite('uid-1', food);
      await repository.addFavorite('uid-2', food);

      final favorites = await repository.watchFavorites('uid-1').first;
      expect(favorites.length, 1);
      expect(favorites.first.userId, 'uid-1');
    });
  });

  group('removeFavorite', () {
    test('deletes the doc', () async {
      await repository.addFavorite('uid-1', food);
      final result = await repository.removeFavorite('uid-1', 'apple');
      expect(result.isSuccess, isTrue);

      final favorites = await repository.watchFavorites('uid-1').first;
      expect(favorites, isEmpty);
    });
  });
}
