import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Circular progress ring for the dashboard's calorie summary — the app's
/// signature visual element (echoed in the app icon and the login screen's
/// brand mark). Reusable with any center content via [child]. When
/// [gradientColors] is given, the arc is painted with a gradient stroke via
/// [_GradientArcPainter] instead of a flat color — [CircularProgressIndicator]
/// has no gradient support, so the filled arc needs a custom painter.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 200,
    this.strokeWidth = 14,
    this.color,
    this.gradientColors,
    this.backgroundColor,
    this.child,
  });

  /// 0.0–1.0+ (values above 1.0 are visually capped but not clamped in data).
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final List<Color>? gradientColors;
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
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                if (gradientColors == null || value <= 0) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: strokeWidth,
                    color: ringColor,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.transparent,
                  );
                }
                return CustomPaint(
                  painter: _GradientArcPainter(
                    progress: value,
                    strokeWidth: strokeWidth,
                    colors: gradientColors!,
                  ),
                );
              },
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

/// Paints the arc as many short solid-color segments, each interpolated
/// along [colors] by its position in the sweep — a deliberately simple,
/// robust way to get a gradient stroke that's always correctly aligned
/// with the arc's own start angle, without reasoning about SweepGradient's
/// separate shader coordinate space (which needs a rotation transform to
/// match an arbitrary arc start, and is easy to get subtly backwards).
class _GradientArcPainter extends CustomPainter {
  _GradientArcPainter({required this.progress, required this.strokeWidth, required this.colors});

  final double progress;
  final double strokeWidth;
  final List<Color> colors;

  static const _startAngle = -math.pi / 2;
  static const _segments = 120;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(strokeWidth / 2);
    final totalSweep = 2 * math.pi * progress;
    final segmentCount = math.max(1, (( _segments * progress).round()));
    final segmentSweep = totalSweep / segmentCount;
    // Slight overlap so rounded caps on adjacent segments don't leave
    // visible gaps between them.
    final drawnSweep = segmentSweep * 1.15;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < segmentCount; i++) {
      final t = segmentCount == 1 ? 0.0 : i / (segmentCount - 1);
      paint.color = _colorAt(t);
      final segmentStart = _startAngle + segmentSweep * i;
      canvas.drawArc(inset, segmentStart, drawnSweep, false, paint);
    }
  }

  Color _colorAt(double t) {
    if (colors.length == 1) return colors.first;
    final scaled = t * (colors.length - 1);
    final index = scaled.floor().clamp(0, colors.length - 2);
    final localT = scaled - index;
    return Color.lerp(colors[index], colors[index + 1], localT)!;
  }

  @override
  bool shouldRepaint(_GradientArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}
