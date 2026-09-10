import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A pinned footer
/// with a safe-area inset and a subtle top hairline. Use as a Scaffold's
/// [Scaffold.bottomNavigationBar] so it stays above the gesture bar while the
/// body scrolls behind it.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}
