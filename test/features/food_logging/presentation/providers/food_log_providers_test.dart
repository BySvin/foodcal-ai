import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_calorie_tracker/core/providers/firebase_providers.dart';
import 'package:food_calorie_tracker/features/food_logging/domain/entities/food_log_entry.dart';
import 'package:food_calorie_tracker/features/food_logging/domain/repositories/food_log_repository.dart';
import 'package:food_calorie_tracker/core/error/result.dart';
import 'package:food_calorie_tracker/features/food_logging/presentation/providers/food_log_providers.dart';

FoodLogEntry _entry(String userId) => FoodLogEntry(
      id: 'id-$userId',
      userId: userId,
      foodId: 'food-1',
      foodName: '$userId\'s food',
      servingSize: 1,
      servingUnit: 'serving',
      quantity: 1,
      calories: 100,
      proteinG: 1,
      carbsG: 1,
      fatG: 1,
      mealType: MealType.breakfast,
      loggedDate: '2026-08-04',
      loggedAt: DateTime(2026, 8, 4),
      source: LogSource.manual,
    );

/// Returns each user's own single entry, keyed by whichever userId is
/// passed in at query time — mirrors how the real Firestore-backed
/// repository would behave for different signed-in users.
class _PerUserFoodLogRepository implements FoodLogRepository {
  @override
  Stream<List<FoodLogEntry>> watchLogsForDate(String userId, String loggedDate) =>
      Stream.value([_entry(userId)]);

  @override
  Stream<List<FoodLogEntry>> watchRecentFoods(String userId, {int limit = 20}) =>
      Stream.value([_entry(userId)]);

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

void main() {
  test('dailyFoodLogsProvider clears stale data on sign-out rather than keeping the '
      'previous user\'s cached stream alive', () async {
    final mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'uid-1', email: 'a@example.com'),
    );

    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockAuth),
        foodLogRepositoryProvider.overrideWithValue(_PerUserFoodLogRepository()),
      ],
    );
    addTearDown(container.dispose);

    final date = DateTime(2026, 8, 4);
    final emissions = <List<FoodLogEntry>>[];

    // Keep the provider alive with an active listener for the whole test —
    // a bare container.read after sign-out isn't guaranteed to observe a
    // rebuild that hasn't finished propagating through the
    // mockAuth -> authStateChangesProvider -> dailyFoodLogsProvider chain.
    container.listen<AsyncValue<List<FoodLogEntry>>>(
      dailyFoodLogsProvider(date),
      (previous, next) {
        final value = next.valueOrNull;
        if (value != null) emissions.add(value);
      },
      fireImmediately: true,
    );

    // Signed in: the provider should carry uid-1's entry.
    await expectLater(
      Stream<void>.periodic(const Duration(milliseconds: 10)).firstWhere((_) => emissions.isNotEmpty),
      completes,
    );
    expect(emissions.single, hasLength(1));
    expect(emissions.single.first.userId, 'uid-1');

    // Sign out: the SAME provider instance (same date key) must reset to
    // empty, not keep serving uid-1's last-known entry — this is the
    // "no stale data flashes for the next user on a shared device" bug
    // fixed by watching authStateChangesProvider reactively instead of
    // reading authRepositoryProvider.currentUid inside ref.watch.
    await mockAuth.signOut();

    await expectLater(
      Stream<void>.periodic(const Duration(milliseconds: 10)).firstWhere((_) => emissions.length >= 2),
      completes,
    );
    expect(emissions.last, isEmpty);
  });
}
