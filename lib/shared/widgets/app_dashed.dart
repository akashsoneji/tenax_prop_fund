import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Receipt-style horizontal perforation line.
class AppDashedDivider extends StatelessWidget {
  const AppDashedDivider({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashWidth = 6.w;
          final gap = 4.w;
          final count = (constraints.maxWidth / (dashWidth + gap)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => SizedBox(
                width: dashWidth,
                height: 1.h,
                child: ColoredBox(color: color),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Rounded-rectangle dashed border for upload drop-zones. Pass ScreenUtil
/// values (e.g. `strokeWidth: 1.w`) for responsive dashes.
class AppDashedBorderPainter extends CustomPainter {
  AppDashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant AppDashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dash != dash ||
      old.gap != gap;
}
