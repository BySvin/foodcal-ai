import 'package:flutter/material.dart';

/// Circular progress ring for the dashboard's calorie summary. Reusable
/// with any center content via [child].
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 200,
    this.strokeWidth = 14,
    this.color,
    this.backgroundColor,
    this.child,
  });

  /// 0.0–1.0+ (values above 1.0 are visually capped but not clamped in data).
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ringColor = color ?? theme.colorScheme.primary;
    final trackColor = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final clamped = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              color: trackColor,
              strokeCap: StrokeCap.round,
            ),
          ),
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: clamped),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: strokeWidth,
                color: ringColor,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}
