import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../routing/route_paths.dart';
import '../providers/auth_providers.dart';

/// Reachable from the email-verification banner's "learn more" action.
/// Verification is a soft gate — the app remains usable unverified, so this
/// screen always offers a way back into the app.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isResending = false;
  bool _sent = false;

  Future<void> _resend() async {
    setState(() => _isResending = true);
    final failure = await ref.read(authControllerProvider.notifier).resendVerificationEmail();
    if (!mounted) return;
    setState(() => _isResending = false);
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    } else {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(firebaseAuthProvider).currentUser?.email ?? 'your email';

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 44,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Verify your email', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "We sent a verification link to $email. You can keep using FoodCal AI in the meantime.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: _sent ? 'Email sent' : 'Resend email',
                    isLoading: _isResending,
                    onPressed: _sent ? null : _resend,
                    variant: AppButtonVariant.secondary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Continue to app',
                    onPressed: () => context.go(RoutePaths.dashboard),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
