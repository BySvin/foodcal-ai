import '../../../../core/utils/calorie_calculator.dart';

class MacroTargets {
  const MacroTargets({required this.proteinG, required this.carbsG, required this.fatG});

  final int proteinG;
  final int carbsG;
  final int fatG;

  factory MacroTargets.fromMap(Map<String, dynamic> map) => MacroTargets(
        proteinG: (map['proteinG'] as num?)?.toInt() ?? 0,
        carbsG: (map['carbsG'] as num?)?.toInt() ?? 0,
        fatG: (map['fatG'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {'proteinG': proteinG, 'carbsG': carbsG, 'fatG': fatG};
}

/// Domain entity for `users/{uid}` — account/profile data plus onboarding
/// results. Fields populated at onboarding are nullable until then.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.onboardingCompleted,
    this.photoUrl,
    this.age,
    this.gender,
    this.heightCm,
    this.currentWeightKg,
    this.activityLevel,
    this.goal,
    this.dailyCalorieTarget,
    this.macroTargets,
    this.dailyWaterTargetMl,
    this.unitPreference = UnitPreference.metric,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool onboardingCompleted;
  final int? age;
  final Gender? gender;
  final double? heightCm;
  final double? currentWeightKg;
  final ActivityLevel? activityLevel;
  final Goal? goal;
  final int? dailyCalorieTarget;
  final MacroTargets? macroTargets;
  final int? dailyWaterTargetMl;
  final UnitPreference unitPreference;

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    bool? onboardingCompleted,
    int? age,
    Gender? gender,
    double? heightCm,
    double? currentWeightKg,
    ActivityLevel? activityLevel,
    Goal? goal,
    int? dailyCalorieTarget,
    MacroTargets? macroTargets,
    int? dailyWaterTargetMl,
    UnitPreference? unitPreference,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      macroTargets: macroTargets ?? this.macroTargets,
      dailyWaterTargetMl: dailyWaterTargetMl ?? this.dailyWaterTargetMl,
      unitPreference: unitPreference ?? this.unitPreference,
    );
  }
}

enum UnitPreference { metric, imperial }
