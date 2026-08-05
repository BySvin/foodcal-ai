import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_calorie_tracker/features/profile/data/repositories/settings_repository_impl.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SettingsRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = SettingsRepositoryImpl(firestore);
  });

  group('watchSettings', () {
    test('defaults to ThemeMode.system when no doc exists yet', () async {
      final settings = await repository.watchSettings('uid-1').first;
      expect(settings.themeMode, ThemeMode.system);
    });

    test('reflects a previously saved theme mode', () async {
      await repository.setThemeMode('uid-1', ThemeMode.dark);
      final settings = await repository.watchSettings('uid-1').first;
      expect(settings.themeMode, ThemeMode.dark);
    });
  });

  group('setThemeMode', () {
    test('persists to settings/{uid} using the uid as the doc id', () async {
      final result = await repository.setThemeMode('uid-1', ThemeMode.light);
      expect(result.isSuccess, isTrue);

      final doc = await firestore.collection('settings').doc('uid-1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['themeMode'], 'light');
    });

    test('only affects the given user\'s doc', () async {
      await repository.setThemeMode('uid-1', ThemeMode.dark);
      final other = await repository.watchSettings('uid-2').first;
      expect(other.themeMode, ThemeMode.system);
    });
  });
}
