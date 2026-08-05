import 'package:flutter/material.dart';

/// Fades and slides [child] up into place after a delay proportional to
/// [index] — used to make a screen's hero content arrive as one composed
/// sequence (ring, then macro card, then water card) instead of appearing
/// all at once.
class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  static const _stagger = Duration(milliseconds: 90);
  static const _duration = Duration(milliseconds: 380);

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(StaggeredFadeIn._stagger * widget.index, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: StaggeredFadeIn._duration,
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.04),
        duration: StaggeredFadeIn._duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
