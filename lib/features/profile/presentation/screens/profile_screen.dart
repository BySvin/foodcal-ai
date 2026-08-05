import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
                Center(child: _AvatarPicker(photoUrl: appUser.photoUrl)),
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

class _AvatarPicker extends ConsumerWidget {
  const _AvatarPicker({required this.photoUrl});

  final String? photoUrl;

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (picked == null) return;

    final Uint8List bytes = await picked.readAsBytes();
    final failure = await ref.read(profileControllerProvider.notifier).uploadAvatar(bytes);
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(profileControllerProvider).isLoading;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: isLoading ? null : () => _pickAndUpload(context, ref),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            backgroundImage: photoUrl != null
                ? CachedNetworkImageProvider(photoUrl!)
                : null,
            child: photoUrl == null
                ? Icon(Icons.person, size: 48, color: theme.colorScheme.onSurfaceVariant)
                : null,
          ),
          if (isLoading) const CircularProgressIndicator(strokeWidth: 2.5),
          if (!isLoading)
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.primary,
                child: Icon(Icons.edit, size: 14, color: theme.colorScheme.onPrimary),
              ),
            ),
        ],
      ),
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
