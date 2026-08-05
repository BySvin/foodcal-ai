import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/error/failure.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/favorite_repository_impl.dart';
import '../../data/repositories/food_log_repository_impl.dart';
import '../../domain/entities/favorite_food.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/food_log_entry.dart';
import '../../domain/entities/nutrition_summary.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../../domain/repositories/food_log_repository.dart';
import 'food_providers.dart';

final foodLogRepositoryProvider = Provider<FoodLogRepository>((ref) {
  return FoodLogRepositoryImpl(ref.watch(firestoreProvider));
});

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepositoryImpl(ref.watch(firestoreProvider));
});

/// All of a user's log entries for a given day, ordered by time logged.
/// Empty (not an error) when the user is signed out or has no logs yet.
final dailyFoodLogsProvider = StreamProvider.family<List<FoodLogEntry>, DateTime>((ref, date) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(foodLogRepositoryProvider).watchLogsForDate(uid, AppDateUtils.toDayKey(date));
});

/// Derived calorie/macro totals for a day — the Dashboard's primary data
/// source (Dashboard milestone) and reused for meal-section subtotals here.
final dailyNutritionSummaryProvider = Provider.family<NutritionSummary, DateTime>((ref, date) {
  final logs = ref.watch(dailyFoodLogsProvider(date)).valueOrNull ?? const [];
  return NutritionSummary.fromLogs(logs);
});

final recentFoodsProvider = StreamProvider<List<FoodLogEntry>>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(foodLogRepositoryProvider).watchRecentFoods(uid);
});

final favoritesProvider = StreamProvider<List<FavoriteFood>>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(favoriteRepositoryProvider).watchFavorites(uid);
});

/// Debounced by the search screen's UI, not here — this just executes
/// whatever query it's given.
final foodSearchResultsProvider =
    FutureProvider.family<List<FoodItem>, String>((ref, query) {
  return ref.watch(foodRepositoryProvider).search(query);
});

final foodLogControllerProvider =
    AsyncNotifierProvider<FoodLogController, void>(FoodLogController.new);

class FoodLogController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  String? get _uid => ref.read(authRepositoryProvider).currentUid;

  Future<Failure?> logFood({
    required String? foodId,
    required String foodName,
    required num servingSize,
    required String servingUnit,
    required num quantity,
    required num caloriesPerServing,
    required num proteinPerServing,
    required num carbsPerServing,
    required num fatPerServing,
    required MealType mealType,
    required DateTime loggedDate,
    required LogSource source,
  }) async {
    final uid = _uid;
    if (uid == null) return const AuthFailure('You need to be signed in to log food.');

    state = const AsyncLoading();
    final result = await ref.read(foodLogRepositoryProvider).logFood(
          userId: uid,
          foodId: foodId,
          foodName: foodName,
          servingSize: servingSize,
          servingUnit: servingUnit,
          quantity: quantity,
          calories: caloriesPerServing * quantity,
          proteinG: proteinPerServing * quantity,
          carbsG: carbsPerServing * quantity,
          fatG: fatPerServing * quantity,
          mealType: mealType,
          loggedDate: AppDateUtils.toDayKey(loggedDate),
          source: source,
        );

    return result.fold((_) {
      state = const AsyncData(null);
      return null;
    }, (failure) {
      state = AsyncError(failure, StackTrace.current);
      return failure;
    });
  }

  Future<Failure?> updateQuantity(FoodLogEntry entry, num newQuantity) async {
    if (newQuantity <= 0) return const ValidationFailure('Quantity must be greater than 0.');

    final perServingFactor = newQuantity / entry.quantity;
    state = const AsyncLoading();
    final result = await ref.read(foodLogRepositoryProvider).updateLogQuantity(
          logId: entry.id,
          quantity: newQuantity,
          calories: entry.calories * perServingFactor,
          proteinG: entry.proteinG * perServingFactor,
          carbsG: entry.carbsG * perServingFactor,
          fatG: entry.fatG * perServingFactor,
        );

    return result.fold((_) {
      state = const AsyncData(null);
      return null;
    }, (failure) {
      state = AsyncError(failure, StackTrace.current);
      return failure;
    });
  }

  Future<Failure?> deleteLog(String logId) async {
    state = const AsyncLoading();
    final result = await ref.read(foodLogRepositoryProvider).deleteLog(logId);
    return result.fold((_) {
      state = const AsyncData(null);
      return null;
    }, (failure) {
      state = AsyncError(failure, StackTrace.current);
      return failure;
    });
  }

  Future<Failure?> toggleFavorite(FoodItem food, {required bool isCurrentlyFavorite}) async {
    final uid = _uid;
    if (uid == null) return const AuthFailure('You need to be signed in to save favorites.');

    final repository = ref.read(favoriteRepositoryProvider);
    final result = isCurrentlyFavorite
        ? await repository.removeFavorite(uid, food.id)
        : await repository.addFavorite(uid, food);

    return result.fold((_) => null, (failure) => failure);
  }
}
