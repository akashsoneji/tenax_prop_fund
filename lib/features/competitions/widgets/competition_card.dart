import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_pill.dart';
import '../../../shared/widgets/app_stat_tile.dart';
import '../models/competition_models.dart';
import '../../../shared/theme/app_spacing.dart';

/// One competition in the list: name + status pill, description, date window,
/// a prize-pool / entries / rank stat row and the entry CTA. Tapping the card
/// opens the detail screen.
class CompetitionCard extends StatelessWidget {
  const CompetitionCard({
    super.key,
    required this.competition,
    required this.registered,
    required this.registering,
    required this.onRegister,
    required this.onTap,
  });

  final Competition competition;
  final bool registered;
  final bool registering;
  final VoidCallback onRegister;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = competition.status.tone(scheme);
    final description = competition.description;
    final dateRange = competition.dateRange;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      competition.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title(
                        fontSize: 17.sp,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  10.horizontalSpace,
                  AppPill.status(
                    label: competition.statusLabel.isEmpty
                        ? competition.status.labelKey.tr
                        : competition.statusLabel,
                    color: tone,
                    showDot: true,
                  ),
                ],
              ),
              if (description != null && description.isNotEmpty) ...[
                Gap.vSm,
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    fontSize: 13.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (dateRange.isNotEmpty) ...[
                10.verticalSpace,
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14.w,
                      color: scheme.onSurfaceVariant,
                    ),
                    6.horizontalSpace,
                    Expanded(
                      child: Text(
                        dateRange,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(
                          fontSize: 12.sp,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              14.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: AppStatTile(
                      label: 'competitions.prize_pool'.tr,
                      value: competition.prizePool,
                      valueFontSize: 15.sp,
                    ),
                  ),
                  Expanded(
                    child: AppStatTile(
                      label: 'competitions.entries'.tr,
                      value: '${competition.entriesCount}',
                      valueFontSize: 15.sp,
                    ),
                  ),
                  Expanded(
                    child: AppStatTile(
                      label: 'competitions.my_rank'.tr,
                      value: competition.myRankLabel,
                      valueFontSize: 15.sp,
                    ),
                  ),
                ],
              ),
              14.verticalSpace,
              _EntryCta(
                competition: competition,
                registered: registered,
                registering: registering,
                onRegister: onRegister,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Register / Registered / closed-with-note CTA at the foot of the card.
class _EntryCta extends StatelessWidget {
  const _EntryCta({
    required this.competition,
    required this.registered,
    required this.registering,
    required this.onRegister,
  });

  final Competition competition;
  final bool registered;
  final bool registering;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = competition.canRegister && !registered && !registering;
    final note = competition.registrationNote;

    final label = registered
        ? 'competitions.registered'.tr
        : competition.canRegister
        ? 'competitions.register'.tr
        : (note != null && note.isNotEmpty)
        ? note
        : 'competitions.registration_closed'.tr;

    final background = registered
        ? scheme.primary.withValues(alpha: 0.14)
        : enabled
        ? scheme.primary
        : scheme.surfaceContainerHighest.withValues(alpha: 0.50);

    final foreground = registered
        ? scheme.primary
        : enabled
        ? AppColors.white
        : scheme.onSurfaceVariant;

    return SizedBox(
      width: double.infinity,
      height: 44.h,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: enabled ? onRegister : null,
          borderRadius: BorderRadius.circular(12.r),
          child: Center(
            child: registering
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor: AlwaysStoppedAnimation(foreground),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (registered) ...[
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16.w,
                          color: foreground,
                        ),
                        Gap.hSm,
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.title(
                            fontSize: 14.sp,
                            color: foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
