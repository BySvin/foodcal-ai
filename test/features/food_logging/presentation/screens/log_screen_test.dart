import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_calorie_tracker/core/error/result.dart';
import 'package:food_calorie_tracker/core/providers/date_providers.dart';
import 'package:food_calorie_tracker/core/providers/firebase_providers.dart';
import 'package:food_calorie_tracker/features/food_logging/domain/entities/food_log_entry.dart';
import 'package:food_calorie_tracker/features/food_logging/domain/repositories/food_log_repository.dart';
import 'package:food_calorie_tracker/features/food_logging/presentation/providers/food_log_providers.dart';
import 'package:food_calorie_tracker/features/food_logging/presentation/screens/log_screen.dart';

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
      const Result.success('new-id');

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

FoodLogEntry _entry(String id, String name, MealType mealType, num calories) {
  return FoodLogEntry(
    id: id,
    userId: 'uid-1',
    foodId: 'food-$id',
    foodName: name,
    servingSize: 1,
    servingUnit: 'serving',
    quantity: 1,
    calories: calories,
    proteinG: 1,
    carbsG: 1,
    fatG: 1,
    mealType: mealType,
    loggedDate: '2026-08-04',
    loggedAt: DateTime(2026, 8, 4, 8),
    source: LogSource.search,
  );
}

Future<void> _pumpLogScreen(WidgetTester tester, List<FoodLogEntry> logs) async {
  final mockAuth = MockFirebaseAuth(
    signedIn: true,
    mockUser: MockUser(uid: 'uid-1', email: 'a@example.com'),
  );

  // Tall enough that all 4 meal sections fit without needing to scroll —
  // off-screen ListView children aren't built even with the list
  // constructor, so `find.text` wouldn't see them otherwise.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockAuth),
        foodLogRepositoryProvider.overrideWithValue(_FakeFoodLogRepository(logs)),
        selectedDateProvider.overrideWith((ref) => DateTime(2026, 8, 4)),
      ],
      child: const MaterialApp(home: LogScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows an empty state for every meal section with no logs', (tester) async {
    await _pumpLogScreen(tester, []);

    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('Snacks'), findsOneWidget);
    expect(find.text('No foods logged yet'), findsNWidgets(4));
  });

  testWidgets('groups logged entries into their correct meal sections', (tester) async {
    await _pumpLogScreen(tester, [
      _entry('1', 'Oatmeal', MealType.breakfast, 166),
      _entry('2', 'Chicken Salad', MealType.lunch, 350),
      _entry('3', 'Almonds', MealType.snack, 164),
    ]);

    expect(find.text('Oatmeal'), findsOneWidget);
    expect(find.text('Chicken Salad'), findsOneWidget);
    expect(find.text('Almonds'), findsOneWidget);
    // Dinner had no entries — its empty-state text should still be present.
    expect(find.text('No foods logged yet'), findsOneWidget);
  });

  testWidgets('shows the calorie subtotal in a meal section header', (tester) async {
    await _pumpLogScreen(tester, [
      _entry('1', 'Oatmeal', MealType.breakfast, 166),
      _entry('2', 'Toast', MealType.breakfast, 80),
    ]);

    expect(find.text('246 kcal'), findsOneWidget);
  });
}
