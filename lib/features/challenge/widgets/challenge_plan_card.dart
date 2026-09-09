import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/challenge_models.dart';

/// A selectable account-size price card in the Paid grid. When [selected] it
/// gains a brand-purple border + soft glow; otherwise a plain surface card.
class ChallengePlanCard extends StatelessWidget {
  const ChallengePlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final ChallengePlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.brightness == Brightness.dark
              ? AppColors.cardDark
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.08),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              plan.discountLabel,
              textAlign: TextAlign.center,
              style: AppText.label(
                color: scheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plan.size,
              textAlign: TextAlign.center,
              style: AppText.value(
                color: scheme.onSurface,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  plan.price,
                  style: AppText.title(
                    color: scheme.primary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  plan.original,
                  style: AppText.label(
                    color: scheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 12,
                  ).copyWith(decoration: TextDecoration.lineThrough),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
