import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/repositories/food_repository.dart';
import '../models/food_item_model.dart';

class FoodRepositoryImpl implements FoodRepository {
  FoodRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _foods =>
      _firestore.collection(FirestorePaths.foods);

  @override
  Future<List<FoodItem>> search(String query, {int limit = 20}) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];

    // Firestore has no native full-text search; a range query on the
    // lowercase name gives prefix matching, which is sufficient for a
    // curated catalog of this size. See docs/architecture.md.
    final snapshot = await _foods
        .orderBy('nameLower')
        .startAt([normalized])
        .endAt(['$normalized'])
        .limit(limit)
        .get();

    return snapshot.docs
        .map(FoodItemModel.fromSnapshot)
        .whereType<FoodItem>()
        .toList();
  }

  @override
  Future<FoodItem?> getById(String id) async {
    final doc = await _foods.doc(id).get();
    return FoodItemModel.fromSnapshot(doc);
  }
}
