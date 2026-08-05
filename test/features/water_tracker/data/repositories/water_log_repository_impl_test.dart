import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_calorie_tracker/features/water_tracker/data/repositories/water_log_repository_impl.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late WaterLogRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = WaterLogRepositoryImpl(firestore);
  });

  group('watchDay', () {
    test('emits null when no doc exists yet for that day', () async {
      final day = await repository.watchDay('uid-1', '2026-08-04').first;
      expect(day, isNull);
    });
  });

  group('addWater', () {
    test('creates the doc on the first add of the day', () async {
      final result = await repository.addWater('uid-1', '2026-08-04', amountMl: 250, goalMl: 2000);
      expect(result.isSuccess, isTrue);

      final day = await repository.watchDay('uid-1', '2026-08-04').first;
      expect(day, isNotNull);
      expect(day!.totalMl, 250);
      expect(day.goalMl, 2000);
      expect(day.lastAddedMl, 250);
    });

    test('atomically increments totalMl on subsequent adds', () async {
      await repository.addWater('uid-1', '2026-08-04', amountMl: 250, goalMl: 2000);
      await repository.addWater('uid-1', '2026-08-04', amountMl: 500, goalMl: 2000);

      final day = await repository.watchDay('uid-1', '2026-08-04').first;
      expect(day!.totalMl, 750);
      expect(day.lastAddedMl, 500); // most recent add only
    });

    test('uses the deterministic uid_date doc id', () async {
      await repository.addWater('uid-1', '2026-08-04', amountMl: 250, goalMl: 2000);
      final doc = await firestore.collection('water_logs').doc('uid-1_2026-08-04').get();
      expect(doc.exists, isTrue);
    });

    test('keeps separate totals per day and per user', () async {
      await repository.addWater('uid-1', '2026-08-04', amountMl: 250, goalMl: 2000);
      await repository.addWater('uid-1', '2026-08-05', amountMl: 500, goalMl: 2000);
      await repository.addWater('uid-2', '2026-08-04', amountMl: 999, goalMl: 2000);

      final day1 = await repository.watchDay('uid-1', '2026-08-04').first;
      final day2 = await repository.watchDay('uid-1', '2026-08-05').first;
      expect(day1!.totalMl, 250);
      expect(day2!.totalMl, 500);
    });
  });

  group('undoLastAdd', () {
    test('reverts the most recent add and clears lastAddedMl', () async {
      await repository.addWater('uid-1', '2026-08-04', amountMl: 250, goalMl: 2000);
      await repository.addWater('uid-1', '2026-08-04', amountMl: 500, goalMl: 2000);

      final result = await repository.undoLastAdd('uid-1', '2026-08-04');
      expect(result.isSuccess, isTrue);

      final day = await repository.watchDay('uid-1', '2026-08-04').first;
      expect(day!.totalMl, 250); // only the 500 add was undone
      expect(day.lastAddedMl, isNull);
    });

    test('is a no-op when there is nothing to undo', () async {
      final result = await repository.undoLastAdd('uid-1', '2026-08-04');
      expect(result.isSuccess, isTrue);

      final day = await repository.watchDay('uid-1', '2026-08-04').first;
      expect(day, isNull);
    });

    test('cannot be applied twice in a row (second undo is a no-op)', () async {
      await repository.addWater('uid-1', '2026-08-04', amountMl: 250, goalMl: 2000);

      await repository.undoLastAdd('uid-1', '2026-08-04');
      final result = await repository.undoLastAdd('uid-1', '2026-08-04');
      expect(result.isSuccess, isTrue);

      final day = await repository.watchDay('uid-1', '2026-08-04').first;
      expect(day!.totalMl, 0);
    });

    test('never drops totalMl below zero', () async {
      await repository.addWater('uid-1', '2026-08-04', amountMl: 250, goalMl: 2000);
      // Simulate totalMl having been reduced by some other means so the
      // undo amount would overshoot below zero.
      await firestore.collection('water_logs').doc('uid-1_2026-08-04').update({'totalMl': 100});

      await repository.undoLastAdd('uid-1', '2026-08-04');

      final day = await repository.watchDay('uid-1', '2026-08-04').first;
      expect(day!.totalMl, greaterThanOrEqualTo(0));
    });
  });
}
