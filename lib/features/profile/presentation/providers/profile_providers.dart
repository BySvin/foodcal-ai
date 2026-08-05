import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/calorie_calculator.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(ProfileController.new);

class ProfileController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  String? get _uid => ref.read(authRepositoryProvider).currentUid;

  /// Writes the edited profile fields and the freshly recomputed targets in
  /// one update. The UI is responsible for confirming the target change
  /// with the user before calling this — this method just persists it.
  Future<Failure?> updateProfile({
    required String displayName,
    required int age,
    required Gender gender,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activityLevel,
    required Goal goal,
  }) async {
    final uid = _uid;
    if (uid == null) return const AuthFailure('You need to be signed in to do that.');

    final targets = CalorieCalculator.calculateTargets(
      gender: gender,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      activityLevel: activityLevel,
      goal: goal,
    );

    state = const AsyncLoading();
    final result = await ref.read(userRepositoryProvider).updateUser(uid, {
      'displayName': displayName,
      'age': age,
      'gender': _genderToString(gender),
      'heightCm': heightCm,
      'currentWeightKg': weightKg,
      'activityLevel': _activityLevelToString(activityLevel),
      'goal': _goalToString(goal),
      'dailyCalorieTarget': targets.dailyCalorieTarget,
      'macroTargets': MacroTargets(
        proteinG: targets.proteinG,
        carbsG: targets.carbsG,
        fatG: targets.fatG,
      ).toMap(),
      'dailyWaterTargetMl': targets.dailyWaterTargetMl,
    });

    return result.fold((_) {
      state = const AsyncData(null);
      return null;
    }, (failure) {
      state = AsyncError(failure, StackTrace.current);
      return failure;
    });
  }

  Future<Failure?> uploadAvatar(Uint8List bytes) async {
    final uid = _uid;
    if (uid == null) return const AuthFailure('You need to be signed in to do that.');

    state = const AsyncLoading();
    try {
      final ref0 = ref.read(firebaseStorageProvider).ref('users/$uid/profile.jpg');
      await ref0.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref0.getDownloadURL();

      final result = await ref.read(userRepositoryProvider).updateUser(uid, {'photoUrl': url});
      return result.fold((_) {
        state = const AsyncData(null);
        return null;
      }, (failure) {
        state = AsyncError(failure, StackTrace.current);
        return failure;
      });
    } catch (_) {
      const failure = ServerFailure('Could not upload your photo. Please try again.');
      state = const AsyncError(failure, StackTrace.empty);
      return failure;
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
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
