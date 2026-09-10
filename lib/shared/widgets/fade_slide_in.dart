import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';

/// A tiny entrance animation used across inner screens: fades + slides its
/// child up on first build. Pass [order] so items in a list stagger in.
///
/// Honours the OS reduce-motion preference (disableAnimations) by rendering
/// the child immediately.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.order = 0,
    this.offset = 18,
  });

  final Widget child;
  final int order;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final delayed = Duration(milliseconds: 40 * order);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.page + delayed,
      curve: AppMotion.enter,
      builder: (context, value, child) {
        final v = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * offset.h),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
