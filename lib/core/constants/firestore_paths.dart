/// Firestore top-level collection names, kept in one place so a rename is a
/// one-line change rather than a repo-wide string search.
class FirestorePaths {
  const FirestorePaths._();

  static const String users = 'users';
  static const String settings = 'settings';
  static const String foods = 'foods';
  static const String foodLogs = 'food_logs';
  static const String favorites = 'favorites';
  static const String weightLogs = 'weight_logs';
  static const String waterLogs = 'water_logs';
}
