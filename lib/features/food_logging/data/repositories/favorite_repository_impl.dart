import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/favorite_food.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../models/favorite_food_model.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  FavoriteRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _favorites =>
      _firestore.collection(FirestorePaths.favorites);

  String _docId(String userId, String foodId) => '${userId}_$foodId';

  @override
  Stream<List<FavoriteFood>> watchFavorites(String userId) {
    return _favorites
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(FavoriteFoodModel.fromSnapshot).toList());
  }

  @override
  Future<Result<void>> addFavorite(String userId, FoodItem food) async {
    try {
      await _favorites
          .doc(_docId(userId, food.id))
          .set(FavoriteFoodModel.toCreateMap(userId, food));
      return const Result.success(null);
    } catch (_) {
      return const Result.failure(ServerFailure('Could not save this favorite. Please try again.'));
    }
  }

  @override
  Future<Result<void>> removeFavorite(String userId, String foodId) async {
    try {
      await _favorites.doc(_docId(userId, foodId)).delete();
      return const Result.success(null);
    } catch (_) {
      return const Result.failure(
        ServerFailure('Could not remove this favorite. Please try again.'),
      );
    }
  }
}
