import 'package:flutter/material.dart';

/// Wraps a child in a staggered fade+slide-in animation. Drop it around
/// individual fields to get the "form builds itself as the screen opens" feel.
class AnimatedField extends StatelessWidget {
  const AnimatedField({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 450),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final int index;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Horizontal shake (used on wrong OTP / invalid input).
class ShakeWidget extends StatefulWidget {
  const ShakeWidget({
    super.key,
    required this.child,
    required this.controller,
  });

  final Widget child;
  final ShakeController controller;

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void initState() {
    super.initState();
    widget.controller._attach(_ctrl);
  }

  @override
  void dispose() {
    widget.controller._detach(_ctrl);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        // 4 oscillations, decaying.
        final dx = 8 * (1 - _ctrl.value) *
            (((_ctrl.value * 30).floor() % 2 == 0) ? 1 : -1);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

class ShakeController {
  AnimationController? _attached;

  void _attach(AnimationController c) => _attached = c;
  void _detach(AnimationController c) {
    if (_attached == c) _attached = null;
  }

  void shake() {
    final c = _attached;
    if (c == null) return;
    c
      ..reset()
      ..forward();
  }
}