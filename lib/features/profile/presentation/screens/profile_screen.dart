import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_paths.dart';

/// Placeholder — replaced with profile info, settings, and logout in the
/// Profile & Settings milestone. The weight-history link is wired early
/// (Weight Tracking milestone) since /profile/weight needs a way to be
/// reached before this screen is fully built.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Profile — coming in the Profile & Settings milestone'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.push(RoutePaths.profileWeight),
              child: const Text('Weight history'),
            ),
          ],
        ),
      ),
    );
  }
}
