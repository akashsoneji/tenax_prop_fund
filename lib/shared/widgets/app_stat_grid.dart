import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// One labelled value shown inside an [AppStatGrid].
class AppStat {
  const AppStat({required this.label, required this.value});
  final String label;
  final String value;
}

/// A responsive grid of labelled values — the reusable form of the
/// `_StatGrid` / `_MetricStrip` blocks used on billing, accounts hero and
/// account summary screens.
///
/// Set [onGradient] to `true` when the grid sits on a brand-gradient hero: text
/// turns white and each cell gets a translucent-white box. On a plain surface
/// it uses theme colours.
///
/// ```dart
/// AppStatGrid(
///   columns: 2,
///   onGradient: true,
///   stats: const [
///     AppStat(label: 'Balance', value: '\$10,000'),
///     AppStat(label: 'Equity', value: '\$10,240'),
///   ],
/// )
/// ```
class AppStatGrid extends StatelessWidget {
  const AppStatGrid({
    super.key,
    required this.stats,
    this.columns = 2,
    this.onGradient = false,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  final List<AppStat> stats;
  final int columns;
  final bool onGradient;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gap = spacing.w;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = columns < 1 ? 1 : columns;
        final cellWidth =
            (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: runSpacing.h,
          children: [
            for (final stat in stats)
              SizedBox(
                width: cellWidth,
                child: _Cell(
                  stat: stat,
                  onGradient: onGradient,
                  scheme: scheme,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.stat,
    required this.onGradient,
    required this.scheme,
  });

  final AppStat stat;
  final bool onGradient;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final labelColor = onGradient
        ? Colors.white.withValues(alpha: 0.75)
        : scheme.onSurface.withValues(alpha: 0.60);
    final valueColor = onGradient ? Colors.white : scheme.onSurface;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stat.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          stat.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.beVietnamPro(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );

    if (!onGradient) return content;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: content,
    );
  }
}
