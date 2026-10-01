import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_spacing.dart';

/// One tab on the competitions status filter.
class CompetitionStatusTab {
  const CompetitionStatusTab(this.key, this.labelKey);
  final String key;
  final String labelKey;
}

/// Segmented status filter (All / Live / Upcoming / Finished) above the
/// competitions list. Scrolls horizontally so long localisations never
/// overflow on narrow devices.
class CompetitionStatusTabs extends StatelessWidget {
  const CompetitionStatusTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  static const tabs = [
    CompetitionStatusTab('all', 'competitions.filter.all'),
    CompetitionStatusTab('live', 'competitions.filter.live'),
    CompetitionStatusTab('upcoming', 'competitions.filter.upcoming'),
    CompetitionStatusTab('ended', 'competitions.filter.finished'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 40.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => Gap.hSm,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final active = tab.key == selected;
          return Material(
            color: active
                ? scheme.primary
                : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(999.r),
            child: InkWell(
              onTap: () => onSelected(tab.key),
              borderRadius: BorderRadius.circular(999.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Center(
                  child: Text(
                    tab.labelKey.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.subtitle(
                      fontSize: 13.sp,
                      color: active ? AppColors.white : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
