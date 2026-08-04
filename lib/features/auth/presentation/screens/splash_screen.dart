import 'package:flutter/material.dart';

/// Transient screen shown while the initial auth state is resolving.
/// The router redirects away from here as soon as auth state is known.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
    );
  }
}
