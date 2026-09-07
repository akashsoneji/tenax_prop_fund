import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_theme.dart';
import '../models/verification_models.dart';

/// A benefit card for one verification step. Two visual variants driven by
/// [highlighted]:
/// - `false` → white [AppTheme.surfaceCard] with a grey number badge (used in
///   the paged stepper and the inactive rows of the overview).
/// - `true`  → filled purple gradient card with white text (the active step in
///   the overview list).
class VerificationStepCard extends StatelessWidget {
  const VerificationStepCard({
    super.key,
    required this.step,
    this.highlighted = false,
    this.showStepLabel = false,
  });

  final VerificationStep step;
  final bool highlighted;

  /// When true renders the "Step N" caption above the title (overview layout).
  final bool showStepLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onCard = highlighted ? AppColors.white : scheme.onSurface;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: highlighted
          ? BoxDecoration(
              gradient: AppTheme.brandGradient(scheme),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: -6,
                  offset: const Offset(0, 10),
                ),
              ],
            )
          : AppTheme.surfaceCard(scheme, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NumberBadge(label: step.numberLabel, highlighted: highlighted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showStepLabel) ...[
                      Text(
                        'verification.step_short'
                            .trParams({'index': '${step.index}'}),
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          color: onCard.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      step.title,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: onCard,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(status: step.status, highlighted: highlighted),
            ],
          ),
          const SizedBox(height: 12),
          for (final b in step.benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_box_outlined,
                    size: 20,
                    color: onCard.withValues(alpha: highlighted ? 0.95 : 0.7),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14.5,
                        color: onCard.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.label, required this.highlighted});
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = highlighted
        ? Colors.white
        : scheme.onSurface.withValues(alpha: 0.08);
    final fg = highlighted ? scheme.primary : scheme.onSurface;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.highlighted});
  final VerificationStatus status;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final completed = status.isCompleted;
    final Color bg;
    final Color fg;
    if (highlighted) {
      bg = Colors.white.withValues(alpha: 0.2);
      fg = Colors.white;
    } else if (completed) {
      bg = scheme.primary;
      fg = Colors.white;
    } else {
      bg = scheme.onSurface.withValues(alpha: 0.08);
      fg = scheme.onSurface.withValues(alpha: 0.55);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        completed ? 'verification.completed'.tr : 'verification.incomplete'.tr,
        style: GoogleFonts.beVietnamPro(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
