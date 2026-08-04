import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_calorie_tracker/core/error/result.dart';
import 'package:food_calorie_tracker/core/providers/firebase_providers.dart';
import 'package:food_calorie_tracker/core/utils/calorie_calculator.dart';
import 'package:food_calorie_tracker/features/auth/domain/entities/app_user.dart';
import 'package:food_calorie_tracker/features/auth/domain/repositories/user_repository.dart';
import 'package:food_calorie_tracker/features/auth/presentation/providers/auth_providers.dart';
import 'package:food_calorie_tracker/features/onboarding/presentation/providers/onboarding_providers.dart';

class FakeUserRepository implements UserRepository {
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
  late FakeUserRepository fakeUserRepository;

  setUp(() {
    fakeUserRepository = FakeUserRepository();
    final mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'uid-1', email: 'a@example.com', displayName: 'A User'),
    );

    container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockAuth),
        userRepositoryProvider.overrideWithValue(fakeUserRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('build() seeds the name from the current Firebase user', () async {
    final form = await container.read(onboardingControllerProvider.future);
    expect(form.name, 'A User');
  });

  test('setters update individual fields without touching others', () async {
    final notifier = container.read(onboardingControllerProvider.notifier);
    await container.read(onboardingControllerProvider.future);

    notifier.setAge(28);
    notifier.setGender(Gender.female);
    notifier.setHeightCm(165);
    notifier.setWeightKg(60);
    notifier.setActivityLevel(ActivityLevel.moderate);
    notifier.setGoal(Goal.maintain);

    final form = container.read(onboardingControllerProvider).value!;
    expect(form.age, 28);
    expect(form.gender, Gender.female);
    expect(form.heightCm, 165);
    expect(form.weightKg, 60);
    expect(form.activityLevel, ActivityLevel.moderate);
    expect(form.goal, Goal.maintain);
    expect(form.name, 'A User'); // untouched by the setters above
  });

  test('computedTargets is null until every required field is set', () async {
    final notifier = container.read(onboardingControllerProvider.notifier);
    await container.read(onboardingControllerProvider.future);

    expect(container.read(onboardingControllerProvider).value!.computedTargets, isNull);

    notifier.setAge(30);
    notifier.setGender(Gender.male);
    notifier.setHeightCm(180);
    notifier.setWeightKg(80);
    notifier.setActivityLevel(ActivityLevel.moderate);
    notifier.setGoal(Goal.maintain);

    expect(container.read(onboardingControllerProvider).value!.computedTargets, isNotNull);
  });

  test('submit() writes the computed profile fields and flips onboardingCompleted', () async {
    final notifier = container.read(onboardingControllerProvider.notifier);
    await container.read(onboardingControllerProvider.future);

    notifier.setName('Jane Doe');
    notifier.setAge(30);
    notifier.setGender(Gender.female);
    notifier.setHeightCm(165);
    notifier.setWeightKg(60);
    notifier.setActivityLevel(ActivityLevel.light);
    notifier.setGoal(Goal.lose);

    final error = await notifier.submit();

    expect(error, isNull);
    expect(fakeUserRepository.lastUpdateUid, 'uid-1');
    final updates = fakeUserRepository.lastUpdate!;
    expect(updates['displayName'], 'Jane Doe');
    expect(updates['gender'], 'female');
    expect(updates['activityLevel'], 'light');
    expect(updates['goal'], 'lose');
    expect(updates['onboardingCompleted'], isTrue);
    expect(updates['dailyCalorieTarget'], isA<int>());
    expect(updates['macroTargets'], isA<Map>());
  });

  test('submit() returns an error and does not write when fields are incomplete', () async {
    final notifier = container.read(onboardingControllerProvider.notifier);
    await container.read(onboardingControllerProvider.future);

    final error = await notifier.submit();

    expect(error, isNotNull);
    expect(fakeUserRepository.lastUpdate, isNull);
  });
}
