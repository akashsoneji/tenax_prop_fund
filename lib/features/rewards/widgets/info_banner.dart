import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// A tinted callout
/// and the KYC-name-mismatch reminder. Variants drive background tint and
/// icon/text colour so we never reuse one colour for both states.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.title,
    required this.body,
    this.variant = InfoBannerVariant.warning,
    this.icon,
  });

  final String title;
  final String body;
  final InfoBannerVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = _paletteFor(variant);
    final iconData = icon ?? palette.icon;
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: palette.accent.withValues(
          alpha: scheme.brightness == Brightness.dark ? 0.16 : 0.12,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, size: 18.w, color: palette.accent),
              Gap.hSm,
              Expanded(
                child: Text(
                  title,
                  style: AppText.base(
                    color: palette.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5.sp,
                  ),
                ),
              ),
            ],
          ),
          Gap.vSm,
          Text(
            body,
            style: AppText.base(
              color: scheme.onSurface.withValues(alpha: 0.7),
              fontSize: 13.sp,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  _InfoBannerPalette _paletteFor(InfoBannerVariant v) {
    switch (v) {
      case InfoBannerVariant.warning:
        return const _InfoBannerPalette(
          accent: AppColors.warningInk,
          icon: Icons.warning_amber_rounded,
        );
      case InfoBannerVariant.info:
        return const _InfoBannerPalette(
          accent: AppColors.warningInk,
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

enum InfoBannerVariant { warning, info }

class _InfoBannerPalette {
  const _InfoBannerPalette({required this.accent, required this.icon});
  final Color accent;
  final IconData icon;
}
