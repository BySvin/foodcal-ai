import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/repositories/weight_log_repository.dart';
import '../models/weight_entry_model.dart';

class WeightLogRepositoryImpl implements WeightLogRepository {
  WeightLogRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _weightLogs =>
      _firestore.collection(FirestorePaths.weightLogs);

  String _docId(String userId, String loggedDate) => '${userId}_$loggedDate';

  @override
  Stream<List<WeightEntry>> watchRecent(String userId, {int days = 90}) {
    final cutoff = AppDateUtils.toDayKey(AppDateUtils.addDays(DateTime.now(), -days));
    return _weightLogs
        .where('userId', isEqualTo: userId)
        .where('loggedDate', isGreaterThanOrEqualTo: cutoff)
        .orderBy('loggedDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(WeightEntryModel.fromSnapshot).toList());
  }

  @override
  Future<Result<void>> logWeight({
    required String userId,
    required String loggedDate,
    required double weightKg,
    String? note,
  }) async {
    try {
      await _weightLogs.doc(_docId(userId, loggedDate)).set({
        'userId': userId,
        'weightKg': weightKg,
        'loggedDate': loggedDate,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Result.success(null);
    } catch (_) {
      return const Result.failure(ServerFailure('Could not save your weight. Please try again.'));
    }
  }
}
