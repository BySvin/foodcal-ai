import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin providers over the Firebase SDK singletons. Every repository
/// depends on these rather than calling `FirebaseAuth.instance` etc.
/// directly, so tests can override them with fakes/mocks.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final googleSignInProvider = Provider<GoogleSignIn>((ref) => GoogleSignIn());

/// Screen views are tracked automatically via FirebaseAnalyticsObserver on
/// the router; this is for the handful of key actions the plan calls out
/// explicitly (log_food, add_water, log_weight, complete_onboarding).
final analyticsProvider = Provider<FirebaseAnalytics>((ref) => FirebaseAnalytics.instance);

/// Raw Firebase auth state stream. Feature-specific user data (profile,
/// onboarding status) is layered on top of this by the auth feature.
final authStateChangesProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

/// Fire-and-forget analytics logging — a failure here (network hiccup,
/// Firebase not initialized in a test environment, an ad-blocker) must
/// never break the action it's describing, so this swallows errors rather
/// than letting them propagate into the caller's success path.
void logAnalyticsEvent(Ref ref, String name, [Map<String, Object>? parameters]) {
  try {
    ref.read(analyticsProvider).logEvent(name: name, parameters: parameters);
  } catch (_) {
    // Intentionally ignored — see doc comment above.
  }
}
