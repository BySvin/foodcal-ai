import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_calorie_tracker/features/weight_tracking/data/repositories/weight_log_repository_impl.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late WeightLogRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = WeightLogRepositoryImpl(firestore);
  });

  group('logWeight', () {
    test('creates a doc with the deterministic uid_date id', () async {
      final result = await repository.logWeight(
        userId: 'uid-1',
        loggedDate: '2026-08-04',
        weightKg: 80.5,
      );
      expect(result.isSuccess, isTrue);

      final doc = await firestore.collection('weight_logs').doc('uid-1_2026-08-04').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['weightKg'], 80.5);
    });

    test('re-logging the same day overwrites rather than creating a duplicate', () async {
      await repository.logWeight(userId: 'uid-1', loggedDate: '2026-08-04', weightKg: 80.5);
      await repository.logWeight(
        userId: 'uid-1',
        loggedDate: '2026-08-04',
        weightKg: 81.2,
        note: 'after breakfast',
      );

      final entries = await repository.watchRecent('uid-1', days: 90).first;
      expect(entries.length, 1);
      expect(entries.first.weightKg, 81.2);
      expect(entries.first.note, 'after breakfast');
    });

    test('logging different days creates separate entries', () async {
      await repository.logWeight(userId: 'uid-1', loggedDate: '2026-08-03', weightKg: 80);
      await repository.logWeight(userId: 'uid-1', loggedDate: '2026-08-04', weightKg: 79.5);

      final entries = await repository.watchRecent('uid-1', days: 90).first;
      expect(entries.length, 2);
    });
  });

  group('watchRecent', () {
    test('returns entries oldest first', () async {
      await repository.logWeight(userId: 'uid-1', loggedDate: '2026-08-04', weightKg: 79);
      await repository.logWeight(userId: 'uid-1', loggedDate: '2026-08-02', weightKg: 81);
      await repository.logWeight(userId: 'uid-1', loggedDate: '2026-08-03', weightKg: 80);

      final entries = await repository.watchRecent('uid-1', days: 90).first;
      expect(entries.map((e) => e.loggedDate), ['2026-08-02', '2026-08-03', '2026-08-04']);
    });

    test('only returns entries for the given user', () async {
      await repository.logWeight(userId: 'uid-1', loggedDate: '2026-08-04', weightKg: 79);
      await repository.logWeight(userId: 'uid-2', loggedDate: '2026-08-04', weightKg: 99);

      final entries = await repository.watchRecent('uid-1', days: 90).first;
      expect(entries.length, 1);
      expect(entries.first.userId, 'uid-1');
    });
  });
}
