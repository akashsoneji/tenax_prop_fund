import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_pill.dart';

import '../models/reward_models.dart';
import '../../../shared/theme/app_text.dart';

/// A single line in the "What stands between you and a payout" card. Renders
/// the label on the left, the value on the right, and a thin divider below
/// (except for the last row in the card).
class RequirementRow extends StatelessWidget {
  const RequirementRow({
    super.key,
    required this.requirement,
    required this.showDivider,
  });

  final PayoutRequirement requirement;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = requirement.status.color;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  requirement.label.tr,
                  style: AppText.base(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.78),
                  ),
                ),
              ),
              _StatusPill(text: requirement.value.tr, color: accent),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1.h,
            thickness: 1,
            color: scheme.onSurface.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppPill(label: text, color: color, bgAlpha: 0.10, fontSize: 12.5);
  }
}
