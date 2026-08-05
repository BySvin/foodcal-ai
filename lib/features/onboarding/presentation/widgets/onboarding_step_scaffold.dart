import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

/// Shared layout for each onboarding step: progress bar, title, content,
/// and a back/next footer. Keeps every step visually consistent without
/// each step re-building the chrome.
class OnboardingStepScaffold extends StatelessWidget {
  const OnboardingStepScaffold({
    super.key,
    required this.stepIndex,
    required this.stepCount,
    required this.title,
    required this.child,
    required this.onNext,
    this.onBack,
    this.nextLabel = 'Continue',
    this.isNextLoading = false,
    this.subtitle,
  });

  final int stepIndex;
  final int stepCount;
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final String nextLabel;
  final bool isNextLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (stepIndex + 1) / stepCount;

    return Scaffold(
      appBar: AppBar(
        leading: onBack == null
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Back', onPressed: onBack),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(height: 6, color: theme.colorScheme.surfaceContainerHighest),
                        LayoutBuilder(
                          builder: (context, constraints) => AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            height: 6,
                            width: constraints.maxWidth * progress,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.accent, AppColors.accentGradientEnd],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(title, style: theme.textTheme.headlineLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(subtitle!, style: theme.textTheme.bodyLarge),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Expanded(child: SingleChildScrollView(child: child)),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: nextLabel,
                    onPressed: onNext,
                    isLoading: isNextLoading,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
