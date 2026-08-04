import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._firebaseAuth, this._googleSignIn);

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<String?> get uidChanges => _firebaseAuth.authStateChanges().map((u) => u?.uid);

  @override
  String? get currentUid => _firebaseAuth.currentUser?.uid;

  @override
  bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  @override
  Future<Result<String>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.sendEmailVerification();
      final uid = credential.user?.uid;
      if (uid == null) return const Result.failure(AuthFailure('Sign up failed.'));
      return Result.success(uid);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }

  @override
  Future<Result<String>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) return const Result.failure(AuthFailure('Sign in failed.'));
      return Result.success(uid);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }

  @override
  Future<Result<String>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Result.failure(AuthFailure('Google sign-in was cancelled.'));
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final uid = userCredential.user?.uid;
      if (uid == null) return const Result.failure(AuthFailure('Google sign-in failed.'));
      return Result.success(uid);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    } catch (_) {
      return const Result.failure(UnknownFailure('Google sign-in failed. Please try again.'));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> sendEmailVerification() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
      return const Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }

  @override
  Future<void> reloadCurrentUser() async {
    await _firebaseAuth.currentUser?.reload();
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Failure _mapAuthException(FirebaseAuthException e) {
    final message = switch (e.code) {
      'email-already-in-use' => 'An account already exists for that email.',
      'invalid-email' => 'That email address looks invalid.',
      'weak-password' => 'Choose a stronger password (at least 8 characters).',
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        'Incorrect email or password.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' => 'Too many attempts. Please wait a moment and try again.',
      'network-request-failed' => 'No internet connection. Please try again.',
      _ => e.message ?? 'Authentication failed. Please try again.',
    };
    return AuthFailure(message);
  }
}
