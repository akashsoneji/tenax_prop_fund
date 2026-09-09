import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';

/// One of the four
/// screen (Withdrawable / Pending / Paid out / Your share).
///
/// Uses a faint tinted background instead of a glass blur so the colour
/// identity of each card (green = withdrawable, amber = pending, etc.) reads
/// even when stacked.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.tone,
    this.delayMs = 0,
  });

  final String label;
  final String value;
  final StatTileTone tone;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tintBg = _toneBackground(tone, scheme);
    final tintAccent = _toneAccent(tone, scheme);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: tintBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tintAccent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(
                      fontSize: 13,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tintAccent.withValues(alpha: 0.16),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/icons/adjust.svg',
                    width: 16,
                    height: 18,
                    colorFilter: ColorFilter.mode(tintAccent, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.value(fontSize: 26, color: tintAccent),
            ),
          ],
        ),
      ),
    );
  }

  // Tint matrix — matches the design without leaking yellow onto CTA surfaces.
  // Brightness-aware so the tile stays readable on a dark scaffold.
  Color _toneBackground(StatTileTone t, ColorScheme scheme) {
    return _toneAccent(t, scheme).withValues(
        alpha: scheme.brightness == Brightness.dark ? 0.16 : 0.12);
  }

  Color _toneAccent(StatTileTone t, ColorScheme scheme) {
    switch (t) {
      case StatTileTone.green:
        return AppColors.success;
      case StatTileTone.amber:
        return AppColors.warningInk;
      case StatTileTone.purple:
        return const Color(0xFF7A1F8E);
      case StatTileTone.blue:
        return const Color(0xFF1E6FB8);
    }
  }
}

enum StatTileTone { green, amber, purple, blue }
