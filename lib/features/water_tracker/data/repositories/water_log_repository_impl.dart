import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/water_day.dart';
import '../../domain/repositories/water_log_repository.dart';
import '../models/water_day_model.dart';

class WaterLogRepositoryImpl implements WaterLogRepository {
  WaterLogRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _waterLogs =>
      _firestore.collection(FirestorePaths.waterLogs);

  String _docId(String userId, String date) => '${userId}_$date';

  @override
  Stream<WaterDay?> watchDay(String userId, String date) {
    return _waterLogs
        .doc(_docId(userId, date))
        .snapshots()
        .map((snapshot) => WaterDayModel.fromSnapshot(snapshot, date));
  }

  @override
  Future<Result<void>> addWater(
    String userId,
    String date, {
    required int amountMl,
    required int goalMl,
  }) async {
    try {
      // FieldValue.increment is atomic: this both creates the doc on the
      // first add of the day and safely increments concurrent adds without
      // a read-modify-write race.
      await _waterLogs.doc(_docId(userId, date)).set({
        'userId': userId,
        'date': date,
        'totalMl': FieldValue.increment(amountMl),
        'goalMl': goalMl,
        'lastAddedMl': amountMl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const Result.success(null);
    } catch (_) {
      return const Result.failure(ServerFailure('Could not log water. Please try again.'));
    }
  }

  @override
  Future<Result<void>> undoLastAdd(String userId, String date) async {
    try {
      final ref = _waterLogs.doc(_docId(userId, date));
      final snapshot = await ref.get();
      final data = snapshot.data();
      final lastAdded = (data?['lastAddedMl'] as num?)?.toInt();
      if (data == null || lastAdded == null) return const Result.success(null);

      final currentTotal = (data['totalMl'] as num?)?.toInt() ?? 0;
      await ref.update({
        'totalMl': (currentTotal - lastAdded).clamp(0, currentTotal),
        'lastAddedMl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Result.success(null);
    } catch (_) {
      return const Result.failure(ServerFailure('Could not undo. Please try again.'));
    }
  }
}
