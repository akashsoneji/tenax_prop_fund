import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Visual tone of an [AppInfoBanner]. Drives the icon tint + soft fill so the
/// same widget covers "heads-up" (info), "be careful" (warning) and "danger".
enum BannerTone { info, warning, danger }

/// The ONE soft callout banner used across inner screens — a rounded, low-key
/// tinted box with a leading icon, bold title and muted body. Fully
/// theme-driven; drop it at the bottom of a scroll body.
///
/// ```dart
/// const AppInfoBanner(
///   tone: BannerTone.info,
///   title: 'A competition is not an evaluation',
///   body: 'Different rules, a separate account…',
/// )
/// ```
class AppInfoBanner extends StatelessWidget {
  const AppInfoBanner({
    super.key,
    required this.title,
    required this.body,
    this.tone = BannerTone.info,
    this.icon,
    this.margin = EdgeInsets.zero,
  });

  final String title;
  final String body;
  final BannerTone tone;
  final IconData? icon;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _accent(scheme);
    final fill = accent.withValues(alpha: scheme.brightness == Brightness.dark ? 0.14 : 0.10);

    return Container(
      margin: margin,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? _defaultIcon, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _defaultIcon {
    switch (tone) {
      case BannerTone.info:
        return Icons.info_outline_rounded;
      case BannerTone.warning:
        return Icons.warning_amber_rounded;
      case BannerTone.danger:
        return Icons.error_outline_rounded;
    }
  }

  Color _accent(ColorScheme scheme) {
    switch (tone) {
      case BannerTone.info:
        return scheme.primary;
      case BannerTone.warning:
        return AppTheme.accent;
      case BannerTone.danger:
        return AppColors.danger;
    }
  }
}
