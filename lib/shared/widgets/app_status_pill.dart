import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_pill.dart';

/// Small status chip used in transaction lists: coloured dot + bold label on
/// a 12% tint (8w × 3h padding, 20r corners, 10.5sp w700).
///
/// The feature decides the [label] (translated or from
/// `AppStatusColors.label`) and [color] (usually `AppStatusColors.of`), so the
/// pill itself never needs to know a feature's status enum.
class AppStatusPill extends StatelessWidget {
  const AppStatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppPill(
      label: label,
      color: color,
      showDot: true,
      dotGap: 5,
      radius: 20,
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
    );
  }
}
