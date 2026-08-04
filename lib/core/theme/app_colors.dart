import 'package:flutter/material.dart';

/// Notion/Apple-Health inspired palette: a single warm accent, near-neutral
/// grays, and dedicated colors for the three macro categories so the
/// dashboard reads at a glance without a legend.
class AppColors {
  const AppColors._();

  static const Color accent = Color(0xFF2F6FED);

  static const Color proteinColor = Color(0xFFE0575B);
  static const Color carbsColor = Color(0xFFEAA83E);
  static const Color fatColor = Color(0xFF4FA6E8);
  static const Color waterColor = Color(0xFF3FB6D3);

  static const Color lightBackground = Color(0xFFFAFAF9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE9E8E6);
  static const Color lightTextPrimary = Color(0xFF1F1F1E);
  static const Color lightTextSecondary = Color(0xFF787774);

  static const Color darkBackground = Color(0xFF191919);
  static const Color darkSurface = Color(0xFF202020);
  static const Color darkBorder = Color(0xFF2F2F2F);
  static const Color darkTextPrimary = Color(0xFFEDEDEC);
  static const Color darkTextSecondary = Color(0xFF9B9B99);

  static const Color success = Color(0xFF3DA35D);
  static const Color danger = Color(0xFFE0575B);
}
