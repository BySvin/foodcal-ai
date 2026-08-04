import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:mocktail/mocktail.dart';

import 'package:food_calorie_tracker/core/error/failure.dart';
import 'package:food_calorie_tracker/features/auth/data/repositories/auth_repository_impl.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    repository = AuthRepositoryImpl(mockAuth, mockGoogleSignIn);
  });

  group('signUpWithEmail', () {
    test('returns Success with the new uid on success', () async {
      final result = await repository.signUpWithEmail(
        email: 'new@example.com',
        password: 'password123',
        displayName: 'New User',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNotNull);
      expect(mockAuth.currentUser, isNotNull);
    });

    test('maps email-already-in-use to a friendly AuthFailure', () async {
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      final result = await repository.signUpWithEmail(
        email: 'dup@example.com',
        password: 'password123',
        displayName: 'Dup User',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull!.message, contains('already exists'));
    });

    test('maps weak-password to a friendly AuthFailure', () async {
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'weak-password'));

      final result = await repository.signUpWithEmail(
        email: 'weak@example.com',
        password: '123',
        displayName: 'Weak Pw',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('stronger password'));
    });
  });

  group('signInWithEmail', () {
    test('returns Success with the uid on success', () async {
      final result = await repository.signInWithEmail(
        email: 'a@example.com',
        password: 'password123',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNotEmpty);
    });

    test('maps wrong-password to a generic "incorrect" AuthFailure', () async {
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'wrong-password'));

      final result = await repository.signInWithEmail(
        email: 'a@example.com',
        password: 'wrong',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('Incorrect email or password'));
    });

    test('maps network-request-failed to a network message', () async {
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(mockAuth)
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      final result = await repository.signInWithEmail(
        email: 'a@example.com',
        password: 'password123',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('No internet connection'));
    });
  });

  group('sendPasswordResetEmail', () {
    test('returns Success on a known email', () async {
      final result = await repository.sendPasswordResetEmail('a@example.com');
      expect(result.isSuccess, isTrue);
    });
  });

  group('uidChanges / currentUid', () {
    test('emits null then the uid after sign in', () async {
      expect(repository.currentUid, isNull);

      await repository.signInWithEmail(email: 'a@example.com', password: 'password123');

      expect(repository.currentUid, isNotNull);
    });
  });

  group('signOut', () {
    test('clears the current user', () async {
      await repository.signInWithEmail(email: 'a@example.com', password: 'password123');
      expect(repository.currentUid, isNotNull);

      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
      await repository.signOut();

      expect(repository.currentUid, isNull);
    });
  });
}
