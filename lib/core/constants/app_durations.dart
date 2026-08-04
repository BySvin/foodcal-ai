/// Animation durations used across the app for consistent motion feel.
class AppDurations {
  const AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Duration searchDebounce = Duration(milliseconds: 350);
}
