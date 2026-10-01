import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_spacing.dart';

/// Competition rules card — a simple bulleted list of the API's `rules[]`
/// strings.
class CompetitionRulesCard extends StatelessWidget {
  const CompetitionRulesCard({super.key, required this.rules});

  final List<String> rules;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rules.length; i++) ...[
            if (i != 0) Gap.vMd,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                10.horizontalSpace,
                Expanded(
                  child: Text(
                    rules[i],
                    style: AppText.body(
                      fontSize: 13.sp,
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
