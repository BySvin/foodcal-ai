import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/food_log_entry.dart';
import '../../domain/repositories/food_log_repository.dart';
import '../models/food_log_entry_model.dart';

class FoodLogRepositoryImpl implements FoodLogRepository {
  FoodLogRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _logs =>
      _firestore.collection(FirestorePaths.foodLogs);

  @override
  Stream<List<FoodLogEntry>> watchLogsForDate(String userId, String loggedDate) {
    return _logs
        .where('userId', isEqualTo: userId)
        .where('loggedDate', isEqualTo: loggedDate)
        .orderBy('loggedAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(FoodLogEntryModel.fromSnapshot).toList());
  }

  @override
  Stream<List<FoodLogEntry>> watchRecentFoods(String userId, {int limit = 20}) {
    // Over-fetch since multiple logs can share the same food; dedupe below.
    return _logs
        .where('userId', isEqualTo: userId)
        .orderBy('loggedAt', descending: true)
        .limit(limit * 4)
        .snapshots()
        .map((snapshot) {
      final entries = snapshot.docs.map(FoodLogEntryModel.fromSnapshot);
      final seen = <String>{};
      final distinct = <FoodLogEntry>[];
      for (final entry in entries) {
        final dedupeKey = entry.foodId ?? entry.foodName;
        if (seen.add(dedupeKey)) {
          distinct.add(entry);
          if (distinct.length == limit) break;
        }
      }
      return distinct;
    });
  }

  @override
  Future<Result<String>> logFood({
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
  }) async {
    try {
      final doc = await _logs.add(
        FoodLogEntryModel.toCreateMap(
          userId: userId,
          foodId: foodId,
          foodName: foodName,
          servingSize: servingSize,
          servingUnit: servingUnit,
          quantity: quantity,
          calories: calories,
          proteinG: proteinG,
          carbsG: carbsG,
          fatG: fatG,
          mealType: mealType,
          loggedDate: loggedDate,
          source: source,
        ),
      );
      return Result.success(doc.id);
    } catch (_) {
      return const Result.failure(ServerFailure('Could not log this food. Please try again.'));
    }
  }

  @override
  Future<Result<void>> updateLogQuantity({
    required String logId,
    required num quantity,
    required num calories,
    required num proteinG,
    required num carbsG,
    required num fatG,
  }) async {
    try {
      await _logs.doc(logId).update({
        'quantity': quantity,
        'calories': calories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Result.success(null);
    } catch (_) {
      return const Result.failure(ServerFailure('Could not update this entry. Please try again.'));
    }
  }

  @override
  Future<Result<void>> deleteLog(String logId) async {
    try {
      await _logs.doc(logId).delete();
      return const Result.success(null);
    } catch (_) {
      return const Result.failure(ServerFailure('Could not delete this entry. Please try again.'));
    }
  }
}
