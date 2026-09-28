import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Route transition for the landscape full-screen chart.
///
/// The incoming page quarter-rotates and scales up into place while the
/// Markets tab behind it settles back, so the change reads as the DEVICE
/// turning rather than an unrelated page sliding in. Reversed on pop, which
/// lands exactly on the portrait layout the user came from.
class RotateIntoLandscapeTransition extends CustomTransition {
  RotateIntoLandscapeTransition();

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final eased = CurvedAnimation(
      parent: animation,
      curve: curve ?? Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return AnimatedBuilder(
      animation: eased,
      child: child,
      builder: (context, child) {
        final t = eased.value;
        return Opacity(
          // Fade in over the first half only, so the rotation is visible
          // rather than hidden behind a fully transparent page.
          opacity: math.min(1.0, t * 2),
          child: Transform.rotate(
            // A quarter turn, unwinding to zero as the page settles.
            angle: (1 - t) * (math.pi / 8),
            child: Transform.scale(
              scale: 0.88 + (0.12 * t),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
