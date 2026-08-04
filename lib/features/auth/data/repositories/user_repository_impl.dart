import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/app_user_model.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestorePaths.users);

  @override
  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map(AppUserModel.fromSnapshot);
  }

  @override
  Future<Result<void>> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      final doc = _users.doc(uid);
      final existing = await doc.get();
      if (existing.exists) return const Result.success(null);

      await doc.set(
        AppUserModel.newProfileMap(email: email, displayName: displayName, photoUrl: photoUrl),
      );
      return const Result.success(null);
    } catch (_) {
      return const Result.failure(ServerFailure('Could not create your profile. Please try again.'));
    }
  }

  @override
  Future<Result<void>> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _users.doc(uid).set(
        {...updates, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return const Result.success(null);
    } catch (_) {
      return const Result.failure(ServerFailure('Could not save your changes. Please try again.'));
    }
  }
}
