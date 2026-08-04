import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_calorie_tracker/core/error/result.dart';
import 'package:food_calorie_tracker/core/providers/firebase_providers.dart';
import 'package:food_calorie_tracker/features/auth/domain/entities/app_user.dart';
import 'package:food_calorie_tracker/features/auth/domain/repositories/user_repository.dart';
import 'package:food_calorie_tracker/features/auth/presentation/providers/auth_providers.dart';
import 'package:food_calorie_tracker/features/onboarding/presentation/screens/onboarding_screen.dart';

class _FakeUserRepository implements UserRepository {
  @override
  Future<Result<void>> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async =>
      const Result.success(null);

  @override
  Future<Result<void>> updateUser(String uid, Map<String, dynamic> updates) async =>
      const Result.success(null);

  @override
  Stream<AppUser?> watchUser(String uid) => Stream.value(null);
}

Future<void> _pumpOnboarding(WidgetTester tester) async {
  final mockAuth = MockFirebaseAuth(
    signedIn: true,
    mockUser: MockUser(uid: 'uid-1', email: 'a@example.com', displayName: ''),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockAuth),
        userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
      ],
      child: const MaterialApp(home: OnboardingScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a validation error when continuing with an empty name', (tester) async {
    await _pumpOnboarding(tester);

    expect(find.text("What's your name?"), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text("What's your name?"), findsOneWidget);
  });

  testWidgets('advances to the next step once a name is entered', (tester) async {
    await _pumpOnboarding(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Jane Doe');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Tell us about you'), findsOneWidget);
  });

  testWidgets('blocks advancing past the age/gender step until both are set', (tester) async {
    await _pumpOnboarding(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Jane Doe');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // No age entered, no gender selected yet.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('valid age'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '28');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Please select a gender'), findsOneWidget);

    await tester.tap(find.text('Female'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Height & weight'), findsOneWidget);
  });
}
