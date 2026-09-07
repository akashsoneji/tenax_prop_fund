import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/configure_models.dart';

/// A single add-on row on the Configure screen: a leading check circle, the
/// add-on title + description + tag, and the price on the right. Selecting it
/// tints the circle with the brand gradient and highlights the border.
class AddonTile extends StatelessWidget {
  const AddonTile({
    super.key,
    required this.addon,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
  });

  final Addon addon;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CheckCircle(selected: selected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addon.title,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          addon.description,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12.5,
                            height: 1.35,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          addon.tagLabel,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    addon.priceLabel,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 14,
            endIndent: 14,
            color: scheme.onSurface.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: AppMotion.fast,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: selected ? AppTheme.brandGradient(scheme) : null,
        border: selected
            ? null
            : Border.all(color: scheme.onSurface.withValues(alpha: 0.25), width: 1.5),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 15, color: AppColors.white)
          : null,
    );
  }
}
