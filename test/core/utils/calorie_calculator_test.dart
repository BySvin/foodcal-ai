import 'package:flutter_test/flutter_test.dart';
import 'package:food_calorie_tracker/core/utils/calorie_calculator.dart';

void main() {
  group('CalorieCalculator.bmr', () {
    test('male formula adds 5', () {
      final result = CalorieCalculator.bmr(
        gender: Gender.male,
        weightKg: 80,
        heightCm: 180,
        age: 30,
      );
      // 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
      expect(result, closeTo(1780, 0.01));
    });

    test('female formula subtracts 161', () {
      final result = CalorieCalculator.bmr(
        gender: Gender.female,
        weightKg: 65,
        heightCm: 165,
        age: 28,
      );
      // 10*65 + 6.25*165 - 5*28 - 161 = 650 + 1031.25 - 140 - 161 = 1380.25
      expect(result, closeTo(1380.25, 0.01));
    });

    test('other formula is the midpoint of male/female offsets', () {
      final male = CalorieCalculator.bmr(
        gender: Gender.male,
        weightKg: 70,
        heightCm: 170,
        age: 25,
      );
      final female = CalorieCalculator.bmr(
        gender: Gender.female,
        weightKg: 70,
        heightCm: 170,
        age: 25,
      );
      final other = CalorieCalculator.bmr(
        gender: Gender.other,
        weightKg: 70,
        heightCm: 170,
        age: 25,
      );
      expect(other, closeTo((male + female) / 2, 0.01));
    });
  });

  group('CalorieCalculator.tdee', () {
    test('applies the correct multiplier per activity level', () {
      final multipliers = {
        ActivityLevel.sedentary: 1.2,
        ActivityLevel.light: 1.375,
        ActivityLevel.moderate: 1.55,
        ActivityLevel.active: 1.725,
        ActivityLevel.veryActive: 1.9,
      };

      final bmrValue = CalorieCalculator.bmr(
        gender: Gender.male,
        weightKg: 75,
        heightCm: 175,
        age: 30,
      );

      for (final entry in multipliers.entries) {
        final tdee = CalorieCalculator.tdee(
          gender: Gender.male,
          weightKg: 75,
          heightCm: 175,
          age: 30,
          activityLevel: entry.key,
        );
        expect(tdee, closeTo(bmrValue * entry.value, 0.01));
      }
    });
  });

  group('CalorieCalculator.calculateTargets', () {
    test('lose goal subtracts 500 from TDEE', () {
      final targets = CalorieCalculator.calculateTargets(
        gender: Gender.male,
        weightKg: 85,
        heightCm: 178,
        age: 35,
        activityLevel: ActivityLevel.moderate,
        goal: Goal.lose,
      );
      final tdee = CalorieCalculator.tdee(
        gender: Gender.male,
        weightKg: 85,
        heightCm: 178,
        age: 35,
        activityLevel: ActivityLevel.moderate,
      );
      expect(targets.dailyCalorieTarget, (tdee - 500).round());
      expect(targets.wasClamped, isFalse);
    });

    test('maintain goal equals TDEE', () {
      final targets = CalorieCalculator.calculateTargets(
        gender: Gender.female,
        weightKg: 60,
        heightCm: 162,
        age: 27,
        activityLevel: ActivityLevel.light,
        goal: Goal.maintain,
      );
      final tdee = CalorieCalculator.tdee(
        gender: Gender.female,
        weightKg: 60,
        heightCm: 162,
        age: 27,
        activityLevel: ActivityLevel.light,
      );
      expect(targets.dailyCalorieTarget, tdee.round());
    });

    test('gain goal adds 400 to TDEE', () {
      final targets = CalorieCalculator.calculateTargets(
        gender: Gender.male,
        weightKg: 70,
        heightCm: 175,
        age: 24,
        activityLevel: ActivityLevel.active,
        goal: Goal.gain,
      );
      final tdee = CalorieCalculator.tdee(
        gender: Gender.male,
        weightKg: 70,
        heightCm: 175,
        age: 24,
        activityLevel: ActivityLevel.active,
      );
      expect(targets.dailyCalorieTarget, (tdee + 400).round());
    });

    test('clamps very low targets to 1200 and flags wasClamped', () {
      final targets = CalorieCalculator.calculateTargets(
        gender: Gender.female,
        weightKg: 40,
        heightCm: 150,
        age: 60,
        activityLevel: ActivityLevel.sedentary,
        goal: Goal.lose,
      );
      expect(targets.dailyCalorieTarget, 1200);
      expect(targets.wasClamped, isTrue);
    });

    test('clamps very high targets to 4000 and flags wasClamped', () {
      final targets = CalorieCalculator.calculateTargets(
        gender: Gender.male,
        weightKg: 150,
        heightCm: 200,
        age: 20,
        activityLevel: ActivityLevel.veryActive,
        goal: Goal.gain,
      );
      expect(targets.dailyCalorieTarget, 4000);
      expect(targets.wasClamped, isTrue);
    });

    test('macro split is 30/40/30 protein/carbs/fat by calories', () {
      final targets = CalorieCalculator.calculateTargets(
        gender: Gender.male,
        weightKg: 80,
        heightCm: 180,
        age: 30,
        activityLevel: ActivityLevel.moderate,
        goal: Goal.maintain,
      );
      final calories = targets.dailyCalorieTarget;
      expect(targets.proteinG, closeTo(calories * 0.30 / 4, 1));
      expect(targets.carbsG, closeTo(calories * 0.40 / 4, 1));
      expect(targets.fatG, closeTo(calories * 0.30 / 9, 1));
    });

    test('water target is weightKg * 35, clamped to [1500, 4000]', () {
      final normal = CalorieCalculator.calculateTargets(
        gender: Gender.male,
        weightKg: 80,
        heightCm: 180,
        age: 30,
        activityLevel: ActivityLevel.moderate,
        goal: Goal.maintain,
      );
      expect(normal.dailyWaterTargetMl, 2800);

      final lowClamp = CalorieCalculator.calculateTargets(
        gender: Gender.female,
        weightKg: 35,
        heightCm: 150,
        age: 25,
        activityLevel: ActivityLevel.sedentary,
        goal: Goal.maintain,
      );
      expect(lowClamp.dailyWaterTargetMl, 1500);

      final highClamp = CalorieCalculator.calculateTargets(
        gender: Gender.male,
        weightKg: 150,
        heightCm: 190,
        age: 30,
        activityLevel: ActivityLevel.moderate,
        goal: Goal.maintain,
      );
      expect(highClamp.dailyWaterTargetMl, 4000);
    });
  });
}
