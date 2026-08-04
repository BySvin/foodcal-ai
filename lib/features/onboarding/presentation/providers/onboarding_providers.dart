import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/calorie_calculator.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Local, in-progress state for the multi-step onboarding form. Nullable
/// fields represent "not yet answered" — validated per-step in the UI.
class OnboardingFormState {
  const OnboardingFormState({
    this.name = '',
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.activityLevel,
    this.goal,
  });

  final String name;
  final int? age;
  final Gender? gender;
  final double? heightCm;
  final double? weightKg;
  final ActivityLevel? activityLevel;
  final Goal? goal;

  bool get hasAllFieldsForTargets =>
      age != null &&
      gender != null &&
      heightCm != null &&
      weightKg != null &&
      activityLevel != null &&
      goal != null;

  CalorieTargets? get computedTargets {
    if (!hasAllFieldsForTargets) return null;
    return CalorieCalculator.calculateTargets(
      gender: gender!,
      weightKg: weightKg!,
      heightCm: heightCm!,
      age: age!,
      activityLevel: activityLevel!,
      goal: goal!,
    );
  }

  OnboardingFormState copyWith({
    String? name,
    int? age,
    Gender? gender,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
    Goal? goal,
  }) {
    return OnboardingFormState(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
    );
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, OnboardingFormState>(OnboardingController.new);

class OnboardingController extends AsyncNotifier<OnboardingFormState> {
  @override
  Future<OnboardingFormState> build() async {
    final displayName = ref.read(firebaseAuthProvider).currentUser?.displayName ?? '';
    return OnboardingFormState(name: displayName);
  }

  void _update(OnboardingFormState Function(OnboardingFormState) updater) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(updater(current));
  }

  void setName(String name) => _update((s) => s.copyWith(name: name));
  void setAge(int age) => _update((s) => s.copyWith(age: age));
  void setGender(Gender gender) => _update((s) => s.copyWith(gender: gender));
  void setHeightCm(double heightCm) => _update((s) => s.copyWith(heightCm: heightCm));
  void setWeightKg(double weightKg) => _update((s) => s.copyWith(weightKg: weightKg));
  void setActivityLevel(ActivityLevel level) => _update((s) => s.copyWith(activityLevel: level));
  void setGoal(Goal goal) => _update((s) => s.copyWith(goal: goal));

  /// Writes the completed profile + computed targets to Firestore and
  /// flips `onboardingCompleted`. The router's redirect logic (listening to
  /// `appUserProvider`) takes the user to /dashboard once this resolves.
  Future<String?> submit() async {
    final form = state.valueOrNull;
    final targets = form?.computedTargets;
    final uid = ref.read(authRepositoryProvider).currentUid;

    if (form == null || targets == null || uid == null) {
      return 'Please complete every step before continuing.';
    }

    final previousState = state;
    state = const AsyncLoading();

    final result = await ref.read(userRepositoryProvider).updateUser(uid, {
      'displayName': form.name,
      'age': form.age,
      'gender': _genderToString(form.gender!),
      'heightCm': form.heightCm,
      'currentWeightKg': form.weightKg,
      'activityLevel': _activityLevelToString(form.activityLevel!),
      'goal': _goalToString(form.goal!),
      'dailyCalorieTarget': targets.dailyCalorieTarget,
      'macroTargets': MacroTargets(
        proteinG: targets.proteinG,
        carbsG: targets.carbsG,
        fatG: targets.fatG,
      ).toMap(),
      'dailyWaterTargetMl': targets.dailyWaterTargetMl,
      'onboardingCompleted': true,
    });

    return result.fold(
      (_) {
        state = AsyncData(form);
        return null;
      },
      (failure) {
        state = previousState;
        return failure.message;
      },
    );
  }

  String _genderToString(Gender g) => switch (g) {
        Gender.male => 'male',
        Gender.female => 'female',
        Gender.other => 'other',
      };

  String _activityLevelToString(ActivityLevel a) => switch (a) {
        ActivityLevel.sedentary => 'sedentary',
        ActivityLevel.light => 'light',
        ActivityLevel.moderate => 'moderate',
        ActivityLevel.active => 'active',
        ActivityLevel.veryActive => 'veryActive',
      };

  String _goalToString(Goal g) => switch (g) {
        Goal.lose => 'lose',
        Goal.maintain => 'maintain',
        Goal.gain => 'gain',
      };
}
