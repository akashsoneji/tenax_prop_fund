import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Spacing scale in design units (375×812). Convert with `.w` / `.h` at use
/// site, or use [Gap] for ready-made responsive spacers.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Responsive spacers built on ScreenUtil. Use these between children instead
/// of `SizedBox(height: X.h)`; off-scale values use `14.verticalSpace` directly.
abstract final class Gap {
  static Widget get vXxs => AppSpacing.xxs.verticalSpace;
  static Widget get vXs => AppSpacing.xs.verticalSpace;
  static Widget get vSm => AppSpacing.sm.verticalSpace;
  static Widget get vMd => AppSpacing.md.verticalSpace;
  static Widget get vLg => AppSpacing.lg.verticalSpace;
  static Widget get vXl => AppSpacing.xl.verticalSpace;
  static Widget get vXxl => AppSpacing.xxl.verticalSpace;

  static Widget get hXxs => AppSpacing.xxs.horizontalSpace;
  static Widget get hXs => AppSpacing.xs.horizontalSpace;
  static Widget get hSm => AppSpacing.sm.horizontalSpace;
  static Widget get hMd => AppSpacing.md.horizontalSpace;
  static Widget get hLg => AppSpacing.lg.horizontalSpace;
  static Widget get hXl => AppSpacing.xl.horizontalSpace;
}
