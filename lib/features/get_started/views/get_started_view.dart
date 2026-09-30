import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';

import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/flavor_logo.dart';

/// Onboarding entry: hero mark + tagline + Get Started / Create Account CTAs.
/// Single page, no carousel. Adapts to light/dark via [Theme].
class GetStartedView extends StatelessWidget {
  const GetStartedView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ringColor = isDark
        ? scheme.primary.withValues(alpha: 0.55)
        : AppColors.border;
    final sheetColor = isDark
        ? const Color(0xFF141416)
        : Colors.white;
    final onSheet = isDark ? Colors.white : Colors.black87;
    final onSheetMuted = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = math.min(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return Center(
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size(size, size),
                            painter: _DashedRingsPainter(
                              color: ringColor,
                              isDark: isDark,
                            ),
                          ),
                          _LogoMark(scheme: scheme, isDark: isDark),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _BottomSheetCard(
              sheetColor: sheetColor,
              onSheet: onSheet,
              onSheetMuted: onSheetMuted,
              scheme: scheme,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.scheme, required this.isDark});
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180.w,
      height: 180.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            scheme.primary,
            scheme.primary.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.45),
            blurRadius: 60.r,
            spreadRadius: 4.r,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: 96.w,
        height: 96.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        child: FlavorLogo(
          size: 96.w,
          fallback: Text(
            'tp',
            style: GoogleFonts.beVietnamPro(
              fontSize: 44.sp,
              fontWeight: FontWeight.w800,
              color: scheme.secondary,
              letterSpacing: -1,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomSheetCard extends StatelessWidget {
  const _BottomSheetCard({
    required this.sheetColor,
    required this.onSheet,
    required this.onSheetMuted,
    required this.scheme,
    required this.isDark,
  });

  final Color sheetColor;
  final Color onSheet;
  final Color onSheetMuted;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 20.h),
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'get_started.headline'.tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 26.sp,
              fontWeight: FontWeight.w800,
              color: onSheet,
              height: 1.15,
              letterSpacing: 0.2,
            ),
          ),
          // SizedBox(height: 14.h),
          // Text(
          //   'get_started.subtitle'.tr,
          //   textAlign: TextAlign.center,
          //   style: GoogleFonts.beVietnamPro(
          //     fontSize: 14.sp,
          //     color: onSheetMuted,
          //     height: 1.5,
          //   ),
          // ),
          SizedBox(height: 22.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onSheet,
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : scheme.primary.withValues(alpha: 0.35),
                    ),
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.transparent,
                  ),
                  onPressed: () => Get.toNamed(AppRoutes.login),
                  child: Text('get_started.get_started'.tr),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: AppGradientButton(
                  label: 'get_started.create_account'.tr,
                  onPressed: () => Get.toNamed(AppRoutes.register),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paints three concentric dashed circles at 0.55, 0.75, 0.95 of the box size.
class _DashedRingsPainter extends CustomPainter {
  _DashedRingsPainter({required this.color, required this.isDark});
  final Color color;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final f in const [0.55, 0.75, 0.95]) {
      _drawDashedCircle(canvas, center, maxR * f, paint);
    }
  }

  void _drawDashedCircle(Canvas canvas, Offset c, double r, Paint p) {
    const dashDeg = 4.0;
    const gapDeg = 3.0;
    double a = 0;
    while (a < 360) {
      final start = a * math.pi / 180;
      final sweep = dashDeg * math.pi / 180;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        sweep,
        false,
        p,
      );
      a += dashDeg + gapDeg;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingsPainter old) =>
      old.color != color || old.isDark != isDark;
}
