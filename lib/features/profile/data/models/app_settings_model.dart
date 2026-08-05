import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show ThemeMode;

import '../../domain/entities/app_settings.dart';

class AppSettingsModel {
  const AppSettingsModel._();

  static AppSettings fromMap(Map<String, dynamic> map) {
    return AppSettings(themeMode: _themeModeFromString(map['themeMode'] as String?));
  }

  static AppSettings fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) return const AppSettings();
    return fromMap(data);
  }

  static String themeModeToString(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  static ThemeMode _themeModeFromString(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
