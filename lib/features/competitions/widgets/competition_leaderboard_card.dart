import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_text.dart';
import '../models/competition_models.dart';
import '../../../shared/theme/app_spacing.dart';

/// Leaderboard card — ranked rows with the signed-in trader's row highlighted
/// via `is_you`. Shows a placeholder while no scores have been posted.
class CompetitionLeaderboardCard extends StatelessWidget {
  const CompetitionLeaderboardCard({super.key, required this.rows});

  final List<CompetitionLeaderboardRow> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: rows.isEmpty
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: 26.h),
              child: Center(
                child: Text(
                  'competitions.leaderboard_empty'.tr,
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    fontSize: 13.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  _LeaderboardRow(
                    row: rows[i],
                    showDivider: i != rows.length - 1,
                  ),
              ],
            ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.row, required this.showDivider});

  final CompetitionLeaderboardRow row;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = row.isYou ? scheme.primary : scheme.onSurfaceVariant;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 13.h),
          child: Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '${row.rank}',
                  style: AppText.title(fontSize: 12.sp, color: accent),
                ),
              ),
              Gap.hMd,
              Expanded(
                child: Text(
                  row.isYou
                      ? '${row.name} · ${'competitions.you'.tr}'
                      : row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.subtitle(
                    fontSize: 14.sp,
                    color: row.isYou ? scheme.primary : scheme.onSurface,
                  ),
                ),
              ),
              10.horizontalSpace,
              Flexible(
                child: Text(
                  row.score,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppText.title(
                    fontSize: 14.sp,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1.h,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.40),
          ),
      ],
    );
  }
}
