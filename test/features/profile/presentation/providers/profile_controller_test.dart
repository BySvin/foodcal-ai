import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_calorie_tracker/core/error/result.dart';
import 'package:food_calorie_tracker/core/providers/firebase_providers.dart';
import 'package:food_calorie_tracker/core/utils/calorie_calculator.dart';
import 'package:food_calorie_tracker/features/auth/domain/entities/app_user.dart';
import 'package:food_calorie_tracker/features/auth/domain/repositories/user_repository.dart';
import 'package:food_calorie_tracker/features/auth/presentation/providers/auth_providers.dart';
import 'package:food_calorie_tracker/features/profile/presentation/providers/profile_providers.dart';

class _FakeUserRepository implements UserRepository {
  Map<String, dynamic>? lastUpdate;
  String? lastUpdateUid;

  @override
  Future<Result<void>> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async =>
      const Result.success(null);

  @override
  Future<Result<void>> updateUser(String uid, Map<String, dynamic> updates) async {
    lastUpdateUid = uid;
    lastUpdate = updates;
    return const Result.success(null);
  }

  @override
  Stream<AppUser?> watchUser(String uid) => Stream.value(null);
}

void main() {
  late ProviderContainer container;
  late _FakeUserRepository fakeUserRepository;

  setUp(() {
    fakeUserRepository = _FakeUserRepository();
    final mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'uid-1', email: 'a@example.com'),
    );

    container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockAuth),
        userRepositoryProvider.overrideWithValue(fakeUserRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('updateProfile recomputes targets via CalorieCalculator and writes them alongside the '
      'edited fields', () async {
    final notifier = container.read(profileControllerProvider.notifier);

    final expectedTargets = CalorieCalculator.calculateTargets(
      gender: Gender.female,
      weightKg: 65,
      heightCm: 168,
      age: 29,
      activityLevel: ActivityLevel.active,
      goal: Goal.lose,
    );

    final error = await notifier.updateProfile(
      displayName: 'Jane Doe',
      age: 29,
      gender: Gender.female,
      heightCm: 168,
      weightKg: 65,
      activityLevel: ActivityLevel.active,
      goal: Goal.lose,
    );

    expect(error, isNull);
    expect(fakeUserRepository.lastUpdateUid, 'uid-1');
    final updates = fakeUserRepository.lastUpdate!;
    expect(updates['displayName'], 'Jane Doe');
    expect(updates['age'], 29);
    expect(updates['gender'], 'female');
    expect(updates['heightCm'], 168);
    expect(updates['currentWeightKg'], 65);
    expect(updates['activityLevel'], 'active');
    expect(updates['goal'], 'lose');
    expect(updates['dailyCalorieTarget'], expectedTargets.dailyCalorieTarget);
    expect(updates['dailyWaterTargetMl'], expectedTargets.dailyWaterTargetMl);
    final macroTargets = updates['macroTargets'] as Map;
    expect(macroTargets['proteinG'], expectedTargets.proteinG);
    expect(macroTargets['carbsG'], expectedTargets.carbsG);
    expect(macroTargets['fatG'], expectedTargets.fatG);
  });

  test('recomputed targets change when the goal changes, holding other fields equal', () async {
    final notifier = container.read(profileControllerProvider.notifier);

    await notifier.updateProfile(
      displayName: 'Jane Doe',
      age: 30,
      gender: Gender.male,
      heightCm: 180,
      weightKg: 80,
      activityLevel: ActivityLevel.moderate,
      goal: Goal.maintain,
    );
    final maintainTarget =
        (fakeUserRepository.lastUpdate!['dailyCalorieTarget'] as int);

    await notifier.updateProfile(
      displayName: 'Jane Doe',
      age: 30,
      gender: Gender.male,
      heightCm: 180,
      weightKg: 80,
      activityLevel: ActivityLevel.moderate,
      goal: Goal.lose,
    );
    final loseTarget = (fakeUserRepository.lastUpdate!['dailyCalorieTarget'] as int);

    expect(loseTarget, maintainTarget - 500);
  });
}
