import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/calorie_calculator.dart';
import '../../domain/entities/app_user.dart';

/// Maps between the `users/{uid}` Firestore document shape and the
/// [AppUser] domain entity.
class AppUserModel {
  const AppUserModel._();

  static AppUser fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      onboardingCompleted: map['onboardingCompleted'] as bool? ?? false,
      age: (map['age'] as num?)?.toInt(),
      gender: _genderFromString(map['gender'] as String?),
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      currentWeightKg: (map['currentWeightKg'] as num?)?.toDouble(),
      activityLevel: _activityLevelFromString(map['activityLevel'] as String?),
      goal: _goalFromString(map['goal'] as String?),
      dailyCalorieTarget: (map['dailyCalorieTarget'] as num?)?.toInt(),
      macroTargets: map['macroTargets'] is Map
          ? MacroTargets.fromMap(Map<String, dynamic>.from(map['macroTargets'] as Map))
          : null,
      dailyWaterTargetMl: (map['dailyWaterTargetMl'] as num?)?.toInt(),
      unitPreference:
          map['unitPreference'] == 'imperial' ? UnitPreference.imperial : UnitPreference.metric,
    );
  }

  static AppUser? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) return null;
    return fromMap(snapshot.id, data);
  }

  static Map<String, dynamic> newProfileMap({
    required String email,
    required String displayName,
    String? photoUrl,
  }) {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'onboardingCompleted': false,
      'unitPreference': 'metric',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Gender? _genderFromString(String? value) => switch (value) {
        'male' => Gender.male,
        'female' => Gender.female,
        'other' => Gender.other,
        _ => null,
      };

  static ActivityLevel? _activityLevelFromString(String? value) => switch (value) {
        'sedentary' => ActivityLevel.sedentary,
        'light' => ActivityLevel.light,
        'moderate' => ActivityLevel.moderate,
        'active' => ActivityLevel.active,
        'veryActive' => ActivityLevel.veryActive,
        _ => null,
      };

  static Goal? _goalFromString(String? value) => switch (value) {
        'lose' => Goal.lose,
        'maintain' => Goal.maintain,
        'gain' => Goal.gain,
        _ => null,
      };
}
