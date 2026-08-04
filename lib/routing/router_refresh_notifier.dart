import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/firebase_providers.dart';
import '../features/auth/presentation/providers/auth_providers.dart';

/// Bridges Riverpod's auth-state and profile streams to GoRouter's
/// `refreshListenable` so redirects re-evaluate immediately on sign-in/out
/// or onboarding completion, without waiting for a widget rebuild to
/// trigger navigation.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(this._ref) {
    _authSubscription = _ref.listen<AsyncValue<Object?>>(
      authStateChangesProvider,
      (previous, next) => notifyListeners(),
    );
    _appUserSubscription = _ref.listen<AsyncValue<Object?>>(
      appUserProvider,
      (previous, next) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<Object?>> _authSubscription;
  late final ProviderSubscription<AsyncValue<Object?>> _appUserSubscription;

  @override
  void dispose() {
    _authSubscription.close();
    _appUserSubscription.close();
    super.dispose();
  }
}
