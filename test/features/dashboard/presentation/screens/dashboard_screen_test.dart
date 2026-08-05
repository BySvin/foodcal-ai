import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_calorie_tracker/core/error/result.dart';
import 'package:food_calorie_tracker/core/providers/date_providers.dart';
import 'package:food_calorie_tracker/core/providers/firebase_providers.dart';
import 'package:food_calorie_tracker/features/auth/domain/entities/app_user.dart';
import 'package:food_calorie_tracker/features/auth/domain/repositories/user_repository.dart';
import 'package:food_calorie_tracker/features/auth/presentation/providers/auth_providers.dart';
import 'package:food_calorie_tracker/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:food_calorie_tracker/features/food_logging/domain/entities/food_log_entry.dart';
import 'package:food_calorie_tracker/features/food_logging/domain/repositories/food_log_repository.dart';
import 'package:food_calorie_tracker/features/food_logging/presentation/providers/food_log_providers.dart';

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository(this.user);
  final AppUser user;

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
  Stream<AppUser?> watchUser(String uid) => Stream.value(user);
}

class _FakeFoodLogRepository implements FoodLogRepository {
  _FakeFoodLogRepository(this.logs);
  final List<FoodLogEntry> logs;

  @override
  Stream<List<FoodLogEntry>> watchLogsForDate(String userId, String loggedDate) =>
      Stream.value(logs);

  @override
  Stream<List<FoodLogEntry>> watchRecentFoods(String userId, {int limit = 20}) =>
      Stream.value(const []);

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
  }) async =>
      const Result.success('id');

  @override
  Future<Result<void>> updateLogQuantity({
    required String logId,
    required num quantity,
    required num calories,
    required num proteinG,
    required num carbsG,
    required num fatG,
  }) async =>
      const Result.success(null);

  @override
  Future<Result<void>> deleteLog(String logId) async => const Result.success(null);
}

FoodLogEntry _entry({required num calories, required num protein, required num carbs, required num fat}) {
  return FoodLogEntry(
    id: 'id',
    userId: 'uid-1',
    foodId: 'food-1',
    foodName: 'Test Food',
    servingSize: 1,
    servingUnit: 'serving',
    quantity: 1,
    calories: calories,
    proteinG: protein,
    carbsG: carbs,
    fatG: fat,
    mealType: MealType.breakfast,
    loggedDate: '2026-08-04',
    loggedAt: DateTime(2026, 8, 4, 8),
    source: LogSource.search,
  );
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required AppUser appUser,
  required List<FoodLogEntry> logs,
}) async {
  final mockAuth = MockFirebaseAuth(
    signedIn: true,
    mockUser: MockUser(uid: 'uid-1', email: 'a@example.com'),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockAuth),
        firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
        userRepositoryProvider.overrideWithValue(_FakeUserRepository(appUser)),
        foodLogRepositoryProvider.overrideWithValue(_FakeFoodLogRepository(logs)),
        selectedDateProvider.overrideWith((ref) => DateTime(2026, 8, 4)),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

AppUser _fixtureUser() => const AppUser(
      uid: 'uid-1',
      email: 'a@example.com',
      displayName: 'Test User',
      onboardingCompleted: true,
      dailyCalorieTarget: 2000,
      macroTargets: MacroTargets(proteinG: 150, carbsG: 200, fatG: 65),
    );

void main() {
  testWidgets('shows the full remaining target when nothing logged yet', (tester) async {
    await _pumpDashboard(tester, appUser: _fixtureUser(), logs: []);

    expect(find.text('2000'), findsOneWidget);
    expect(find.text('kcal remaining'), findsOneWidget);
    expect(find.text('0 / 2000 kcal consumed'), findsOneWidget);
  });

  testWidgets('ring and macro totals match the sum of the day\'s logs', (tester) async {
    await _pumpDashboard(
      tester,
      appUser: _fixtureUser(),
      logs: [
        _entry(calories: 500, protein: 40, carbs: 50, fat: 15),
        _entry(calories: 300, protein: 20, carbs: 30, fat: 10),
      ],
    );

    // 2000 - (500 + 300) = 1200 remaining.
    expect(find.text('1200'), findsOneWidget);
    expect(find.text('kcal remaining'), findsOneWidget);
    expect(find.text('800 / 2000 kcal consumed'), findsOneWidget);

    // Macro bars: consumed sums vs the fixture's targets.
    expect(find.text('60 / 150g'), findsOneWidget); // protein
    expect(find.text('80 / 200g'), findsOneWidget); // carbs
    expect(find.text('25 / 65g'), findsOneWidget); // fat
  });

  testWidgets('shows "kcal over" once consumption exceeds the target', (tester) async {
    await _pumpDashboard(
      tester,
      appUser: _fixtureUser(),
      logs: [_entry(calories: 2500, protein: 100, carbs: 300, fat: 80)],
    );

    expect(find.text('500'), findsOneWidget); // 2500 - 2000 = 500 over
    expect(find.text('kcal over'), findsOneWidget);
  });
}
