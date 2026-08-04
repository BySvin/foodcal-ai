import '../../../../core/error/result.dart';
import '../entities/app_user.dart';

/// Abstract interface over the `users/{uid}` Firestore document.
abstract class UserRepository {
  Stream<AppUser?> watchUser(String uid);

  Future<Result<void>> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  });

  Future<Result<void>> updateUser(String uid, Map<String, dynamic> updates);
}
