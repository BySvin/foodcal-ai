import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_calorie_tracker/features/auth/data/repositories/user_repository_impl.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = UserRepositoryImpl(firestore);
  });

  group('createUserProfile', () {
    test('creates a new users/{uid} doc with onboardingCompleted=false', () async {
      final result = await repository.createUserProfile(
        uid: 'uid-1',
        email: 'a@example.com',
        displayName: 'A User',
      );

      expect(result.isSuccess, isTrue);

      final doc = await firestore.collection('users').doc('uid-1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['email'], 'a@example.com');
      expect(doc.data()!['displayName'], 'A User');
      expect(doc.data()!['onboardingCompleted'], isFalse);
    });

    test('is a no-op if the profile already exists', () async {
      await firestore.collection('users').doc('uid-1').set({
        'email': 'a@example.com',
        'displayName': 'Original Name',
        'onboardingCompleted': true,
      });

      await repository.createUserProfile(
        uid: 'uid-1',
        email: 'a@example.com',
        displayName: 'Should Not Overwrite',
      );

      final doc = await firestore.collection('users').doc('uid-1').get();
      expect(doc.data()!['displayName'], 'Original Name');
      expect(doc.data()!['onboardingCompleted'], isTrue);
    });
  });

  group('watchUser', () {
    test('emits null when the doc does not exist', () async {
      final stream = repository.watchUser('missing-uid');
      expect(await stream.first, isNull);
    });

    test('emits the mapped AppUser when the doc exists', () async {
      await firestore.collection('users').doc('uid-1').set({
        'email': 'a@example.com',
        'displayName': 'A User',
        'onboardingCompleted': true,
        'dailyCalorieTarget': 2000,
      });

      final user = await repository.watchUser('uid-1').first;

      expect(user, isNotNull);
      expect(user!.uid, 'uid-1');
      expect(user.email, 'a@example.com');
      expect(user.onboardingCompleted, isTrue);
      expect(user.dailyCalorieTarget, 2000);
    });
  });

  group('updateUser', () {
    test('merges the given fields without clobbering existing ones', () async {
      await firestore.collection('users').doc('uid-1').set({
        'email': 'a@example.com',
        'displayName': 'A User',
        'onboardingCompleted': false,
      });

      final result = await repository.updateUser('uid-1', {'onboardingCompleted': true});
      expect(result.isSuccess, isTrue);

      final doc = await firestore.collection('users').doc('uid-1').get();
      expect(doc.data()!['onboardingCompleted'], isTrue);
      expect(doc.data()!['email'], 'a@example.com');
    });
  });
}
