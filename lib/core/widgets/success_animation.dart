import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';

/// Brief animated checkmark confirmation, shown after a quick action
/// completes (e.g. logging food) before navigating away. Auto-dismisses —
/// callers don't pop it themselves, they just await [show].
class SuccessAnimation extends StatefulWidget {
  const SuccessAnimation({super.key, required this.message});

  final String message;

  /// Shows the animation and returns once it's done (~700ms total) —
  /// await this, then navigate.
  static Future<void> show(BuildContext context, {String message = 'Logged'}) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: message,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, _, _) => SuccessAnimation(message: message),
      transitionBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(widget.message, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
