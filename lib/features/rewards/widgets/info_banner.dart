import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: palette.accent.withValues(
            alpha: scheme.brightness == Brightness.dark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, size: 18, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.value(fontSize: 13.5, color: palette.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppText.subtitle(
              fontSize: 13,
              height: 1.4,
              color: scheme.onSurface.withValues(alpha: 0.7),
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
  const _InfoBannerPalette({
    required this.accent,
    required this.icon,
  });
  final Color accent;
  final IconData icon;
}