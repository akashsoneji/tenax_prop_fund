import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/rules_models.dart';

/// One row in the "Your plan" list. Label on the left, value on the right
/// with a chevron icon to signal tappability. Dollar/percent values use
/// brand-purple, plain values use a neutral ink.
class PlanRowTile extends StatelessWidget {
  const PlanRowTile({
    super.key,
    required this.row,
    this.showDivider = true,
  });

  final PlanRow row;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('${row.label} tapped'),
              duration: const Duration(seconds: 1),
            ),
          );
      },
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                    width: 0.6,
                  ),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                row.label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Text(
              row.value,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: row.emphasized ? FontWeight.w800 : FontWeight.w600,
                color: row.emphasized ? scheme.primary : scheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}