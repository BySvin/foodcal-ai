import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(firebaseAuthProvider), ref.watch(googleSignInProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(firestoreProvider));
});

/// The single source of truth for the signed-in user's profile, including
/// onboarding status and calorie/macro targets. Emits null when signed out.
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final uid = authState.valueOrNull?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(uid);
});

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);
  UserRepository get _userRepository => ref.read(userRepositoryProvider);

  Future<Failure?> signUp({
    required String email,
    required String displayName,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await _authRepository.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
    return result.fold(
      (uid) async {
        await _userRepository.createUserProfile(uid: uid, email: email, displayName: displayName);
        state = const AsyncData(null);
        return null;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return failure;
      },
    );
  }

  Future<Failure?> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await _authRepository.signInWithEmail(email: email, password: password);
    return result.fold(
      (_) {
        state = const AsyncData(null);
        return null;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return failure;
      },
    );
  }

  Future<Failure?> signInWithGoogle() async {
    state = const AsyncLoading();
    final result = await _authRepository.signInWithGoogle();
    return result.fold(
      (uid) async {
        // createUserProfile is a no-op if the doc already exists, so this is
        // safe to call on every Google sign-in, not just the first.
        final firebaseUser = ref.read(firebaseAuthProvider).currentUser;
        await _userRepository.createUserProfile(
          uid: uid,
          email: firebaseUser?.email ?? '',
          displayName: firebaseUser?.displayName ?? '',
          photoUrl: firebaseUser?.photoURL,
        );
        state = const AsyncData(null);
        return null;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return failure;
      },
    );
  }

  Future<Failure?> sendPasswordResetEmail(String email) async {
    state = const AsyncLoading();
    final result = await _authRepository.sendPasswordResetEmail(email);
    return result.fold(
      (_) {
        state = const AsyncData(null);
        return null;
      },
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return failure;
      },
    );
  }

  Future<Failure?> resendVerificationEmail() async {
    final result = await _authRepository.sendEmailVerification();
    return result.fold((_) => null, (failure) => failure);
  }

  Future<void> signOut() => _authRepository.signOut();
}
