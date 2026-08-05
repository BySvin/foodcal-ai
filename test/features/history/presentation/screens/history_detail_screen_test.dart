import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_calorie_tracker/core/error/result.dart';
import 'package:food_calorie_tracker/core/providers/firebase_providers.dart';
import 'package:food_calorie_tracker/features/auth/domain/entities/app_user.dart';
import 'package:food_calorie_tracker/features/auth/domain/repositories/user_repository.dart';
import 'package:food_calorie_tracker/features/auth/presentation/providers/auth_providers.dart';
import 'package:food_calorie_tracker/features/food_logging/domain/entities/food_log_entry.dart';
import 'package:food_calorie_tracker/features/food_logging/domain/repositories/food_log_repository.dart';
import 'package:food_calorie_tracker/features/food_logging/presentation/providers/food_log_providers.dart';
import 'package:food_calorie_tracker/features/history/presentation/screens/history_detail_screen.dart';

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

AppUser _fixtureUser() => const AppUser(
      uid: 'uid-1',
      email: 'a@example.com',
      displayName: 'Test User',
      onboardingCompleted: true,
      dailyCalorieTarget: 2000,
      macroTargets: MacroTargets(proteinG: 150, carbsG: 200, fatG: 65),
    );

Future<void> _pumpDetail(
  WidgetTester tester, {
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
        userRepositoryProvider.overrideWithValue(_FakeUserRepository(_fixtureUser())),
        foodLogRepositoryProvider.overrideWithValue(_FakeFoodLogRepository(logs)),
      ],
      child: MaterialApp(home: HistoryDetailScreen(date: DateTime(2026, 8, 4))),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the empty-day state when nothing was logged', (tester) async {
    await _pumpDetail(tester, logs: []);

    expect(find.text('No logs for this day'), findsOneWidget);
    expect(find.text('Nothing was recorded on this date.'), findsOneWidget);
  });

  testWidgets('shows the nutrition summary when food was logged', (tester) async {
    await _pumpDetail(tester, logs: [
      FoodLogEntry(
        id: 'id',
        userId: 'uid-1',
        foodId: 'food-1',
        foodName: 'Oatmeal',
        servingSize: 1,
        servingUnit: 'bowl',
        quantity: 1,
        calories: 300,
        proteinG: 10,
        carbsG: 50,
        fatG: 5,
        mealType: MealType.breakfast,
        loggedDate: '2026-08-04',
        loggedAt: DateTime(2026, 8, 4, 8),
        source: LogSource.search,
      ),
    ]);

    expect(find.text('No logs for this day'), findsNothing);
    expect(find.text('300 / 2000 kcal consumed'), findsOneWidget);
  });
}
