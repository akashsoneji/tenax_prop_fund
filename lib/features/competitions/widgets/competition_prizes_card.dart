import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_text.dart';
import '../models/competition_models.dart';
import '../../../shared/theme/app_spacing.dart';

/// Prize-tier card on the competition detail screen. `amount` is null until
/// the organiser funds a tier, so unfunded tiers still show their structure.
class CompetitionPrizesCard extends StatelessWidget {
  const CompetitionPrizesCard({super.key, required this.prizes});

  final List<CompetitionPrize> prizes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        children: [
          for (var i = 0; i < prizes.length; i++)
            _PrizeRow(prize: prizes[i], showDivider: i != prizes.length - 1),
        ],
      ),
    );
  }
}

class _PrizeRow extends StatelessWidget {
  const _PrizeRow({required this.prize, required this.showDivider});

  final CompetitionPrize prize;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final medal = switch (prize.place) {
      1 => scheme.primary,
      2 => scheme.tertiary,
      3 => scheme.secondary,
      _ => scheme.onSurfaceVariant,
    };

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          child: Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: medal.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${prize.place}',
                  style: AppText.title(fontSize: 12.sp, color: medal),
                ),
              ),
              Gap.hMd,
              Expanded(
                child: Text(
                  prize.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    fontSize: 14.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              10.horizontalSpace,
              Flexible(
                child: Text(
                  prize.amount ?? '—',
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
