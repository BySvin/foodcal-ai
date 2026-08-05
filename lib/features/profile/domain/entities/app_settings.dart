import 'package:flutter/material.dart' show ThemeMode;

/// `settings/{uid}` — app-level preferences. Only `themeMode` has a V1 UI;
/// `notificationsEnabled`/`weekStartsOn` remain documented schema fields
/// (see docs/architecture.md) reserved for V2 features (push notifications,
/// a calendar-week History view) rather than dead code today.
class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system});

  final ThemeMode themeMode;

  AppSettings copyWith({ThemeMode? themeMode}) {
    return AppSettings(themeMode: themeMode ?? this.themeMode);
  }
}
