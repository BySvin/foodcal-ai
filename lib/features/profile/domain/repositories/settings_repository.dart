import 'package:flutter/material.dart' show ThemeMode;

import '../../../../core/error/result.dart';
import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Stream<AppSettings> watchSettings(String userId);

  Future<Result<void>> setThemeMode(String userId, ThemeMode themeMode);
}
