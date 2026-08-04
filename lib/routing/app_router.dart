import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/firebase_providers.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/verify_email_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/food_logging/presentation/screens/log_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import 'app_shell.dart';
import 'route_paths.dart';
import 'router_refresh_notifier.dart';

const _publicRoutes = {
  RoutePaths.login,
  RoutePaths.signup,
  RoutePaths.forgotPassword,
};

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refreshNotifier,
    observers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      final location = state.matchedLocation;

      if (authState.isLoading) {
        return location == RoutePaths.splash ? null : RoutePaths.splash;
      }

      final user = authState.valueOrNull;

      if (user == null) {
        return _publicRoutes.contains(location) ? null : RoutePaths.login;
      }

      final appUserState = ref.read(appUserProvider);
      if (appUserState.isLoading) {
        return location == RoutePaths.splash ? null : RoutePaths.splash;
      }

      final appUser = appUserState.valueOrNull;
      // Profile doc missing (e.g. mid sign-up write) — stay put rather than
      // bouncing to onboarding prematurely.
      if (appUser == null) return null;

      if (!appUser.onboardingCompleted) {
        return location == RoutePaths.onboarding ? null : RoutePaths.onboarding;
      }

      final atEntryRoute = location == RoutePaths.splash ||
          _publicRoutes.contains(location) ||
          location == RoutePaths.onboarding;

      return atEntryRoute ? RoutePaths.dashboard : null;
    },
    routes: [
      GoRoute(path: RoutePaths.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: RoutePaths.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: RoutePaths.signup, builder: (context, state) => const SignupScreen()),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.verifyEmail,
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.log,
                builder: (context, state) => const LogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.history,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
