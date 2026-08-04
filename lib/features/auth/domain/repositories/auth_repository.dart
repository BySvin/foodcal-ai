import '../../../../core/error/result.dart';

/// Abstract interface over Firebase Auth — presentation code depends only
/// on this, never on FirebaseAuth directly, so it's mockable in tests.
abstract class AuthRepository {
  Stream<String?> get uidChanges;

  String? get currentUid;
  bool get isEmailVerified;

  Future<Result<String>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<Result<String>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<String>> signInWithGoogle();

  Future<Result<void>> sendPasswordResetEmail(String email);

  Future<Result<void>> sendEmailVerification();

  Future<void> reloadCurrentUser();

  Future<void> signOut();
}
