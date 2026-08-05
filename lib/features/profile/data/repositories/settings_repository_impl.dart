import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show ThemeMode;

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../models/app_settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _firestore.collection(FirestorePaths.settings).doc(userId);

  @override
  Stream<AppSettings> watchSettings(String userId) {
    return _doc(userId).snapshots().map(AppSettingsModel.fromSnapshot);
  }

  @override
  Future<Result<void>> setThemeMode(String userId, ThemeMode themeMode) async {
    try {
      await _doc(userId).set({
        'userId': userId,
        'themeMode': AppSettingsModel.themeModeToString(themeMode),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const Result.success(null);
    } catch (_) {
      return const Result.failure(ServerFailure('Could not save your preference. Please try again.'));
    }
  }
}
