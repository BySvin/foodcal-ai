/// Route path/name constants — single source of truth for navigation,
/// avoids magic strings scattered across features.
class RoutePaths {
  const RoutePaths._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String onboarding = '/onboarding';

  static const String dashboard = '/dashboard';

  static const String log = '/log';
  static const String logSearch = '/log/search';
  static const String logAddManual = '/log/add-manual';
  static String logFood(String foodId) => '/log/food/$foodId';

  static const String history = '/history';
  static String historyDate(String date) => '/history/$date';

  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String profileWeight = '/profile/weight';
  static const String profileWaterSettings = '/profile/water-settings';
}
