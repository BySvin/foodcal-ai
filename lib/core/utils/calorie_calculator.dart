enum Gender { male, female, other }

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

enum Goal { lose, maintain, gain }

/// Result of a target calculation: daily calorie target, macro split, and
/// whether the raw calculation had to be clamped to a safe range.
class CalorieTargets {
  const CalorieTargets({
    required this.dailyCalorieTarget,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.dailyWaterTargetMl,
    required this.wasClamped,
  });

  final int dailyCalorieTarget;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int dailyWaterTargetMl;
  final bool wasClamped;
}

/// Pure, side-effect-free calorie/macro/water target calculations using the
/// Mifflin-St Jeor equation. No Firebase or Flutter dependency — the
/// primary unit-test target in the app.
class CalorieCalculator {
  const CalorieCalculator._();

  static const int _minCalories = 1200;
  static const int _maxCalories = 4000;
  static const int _minWaterMl = 1500;
  static const int _maxWaterMl = 4000;

  static const Map<ActivityLevel, double> _activityMultipliers = {
    ActivityLevel.sedentary: 1.2,
    ActivityLevel.light: 1.375,
    ActivityLevel.moderate: 1.55,
    ActivityLevel.active: 1.725,
    ActivityLevel.veryActive: 1.9,
  };

  static const Map<Goal, int> _goalAdjustments = {
    Goal.lose: -500,
    Goal.maintain: 0,
    Goal.gain: 400,
  };

  static double bmr({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return switch (gender) {
      Gender.male => base + 5,
      Gender.female => base - 161,
      Gender.other => base - 78,
    };
  }

  static double tdee({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int age,
    required ActivityLevel activityLevel,
  }) {
    final bmrValue = bmr(gender: gender, weightKg: weightKg, heightCm: heightCm, age: age);
    return bmrValue * _activityMultipliers[activityLevel]!;
  }

  static CalorieTargets calculateTargets({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int age,
    required ActivityLevel activityLevel,
    required Goal goal,
  }) {
    final tdeeValue = tdee(
      gender: gender,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      activityLevel: activityLevel,
    );

    final rawTarget = (tdeeValue + _goalAdjustments[goal]!).round();
    final clampedTarget = rawTarget.clamp(_minCalories, _maxCalories).toInt();
    final wasClamped = clampedTarget != rawTarget;

    final proteinG = (clampedTarget * 0.30 / 4).round();
    final carbsG = (clampedTarget * 0.40 / 4).round();
    final fatG = (clampedTarget * 0.30 / 9).round();

    final rawWaterMl = (weightKg * 35).round();
    final waterMl = rawWaterMl.clamp(_minWaterMl, _maxWaterMl).toInt();

    return CalorieTargets(
      dailyCalorieTarget: clampedTarget,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      dailyWaterTargetMl: waterMl,
      wasClamped: wasClamped,
    );
  }
}
