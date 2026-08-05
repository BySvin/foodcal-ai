import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_paths.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/settings_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(appUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: appUserAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: 'Could not load your profile.',
            onRetry: () => ref.invalidate(appUserProvider),
          ),
          data: (appUser) {
            if (appUser == null) return const LoadingView();
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Center(child: _Avatar(photoUrl: appUser.photoUrl)),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(appUser.displayName, style: Theme.of(context).textTheme.headlineLarge),
                ),
                Center(
                  child: Text(appUser.email, style: Theme.of(context).textTheme.bodyLarge),
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily target', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(
                          '${appUser.dailyCalorieTarget ?? '—'} kcal',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _ThemeModeSelector(),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () => context.push(RoutePaths.profileEdit),
                  child: const Text('Edit profile & goal'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => context.push(RoutePaths.profileWeight),
                  child: const Text('Weight history'),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () => ref.read(profileControllerProvider.notifier).signOut(),
                  child: const Text('Sign out'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Static display only — no upload capability (V1 dropped Firebase Storage
/// entirely, Firestore-only). Still shows a photo when one is present,
/// since Google Sign-In populates `photoUrl` from the Google account
/// automatically, independent of any Storage upload flow.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: 48,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl!) : null,
      child: photoUrl == null
          ? Icon(Icons.person, size: 48, color: theme.colorScheme.onSurfaceVariant)
          : null,
    );
  }
}

class _ThemeModeSelector extends ConsumerWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(appSettingsProvider).valueOrNull?.themeMode ?? ThemeMode.system;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theme', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
            ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
          ],
          selected: {currentMode},
          onSelectionChanged: (selected) =>
              ref.read(settingsControllerProvider.notifier).setThemeMode(selected.first),
        ),
      ],
    );
  }
}
