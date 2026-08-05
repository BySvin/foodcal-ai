import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.watch(firestoreProvider));
});

/// Defaults to system theme, both before sign-in and before the user has
/// ever changed it (no settings doc yet).
final appSettingsProvider = StreamProvider<AppSettings>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const AppSettings());
  return ref.watch(settingsRepositoryProvider).watchSettings(uid);
});

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, void>(SettingsController.new);

class SettingsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Failure?> setThemeMode(ThemeMode mode) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return const AuthFailure('You need to be signed in to change this.');

    final result = await ref.read(settingsRepositoryProvider).setThemeMode(uid, mode);
    return result.fold((_) => null, (failure) => failure);
  }
}
