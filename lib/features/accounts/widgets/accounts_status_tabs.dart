import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/accounts_models.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// Horizontally scrollable status tabs with a count badge on each — mirrors the
/// web "Active / Funded / Completed / Breached / All" row. The selected tab is a
/// brand-purple pill; the rest sit flat over the surface.
class AccountsStatusTabs extends StatelessWidget {
  const AccountsStatusTabs({
    super.key,
    required this.labels,
    required this.counts,
    required this.selected,
    required this.onChanged,
  });

  final Map<AccountTab, String> labels;
  final AccountCounts counts;
  final AccountTab selected;
  final ValueChanged<AccountTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: AccountTab.values.length,
        separatorBuilder: (_, _) => Gap.hSm,
        itemBuilder: (context, i) {
          final tab = AccountTab.values[i];
          return _Tab(
            label: labels[tab] ?? '',
            count: counts.forTab(tab),
            selected: tab == selected,
            onTap: () => onChanged(tab),
          );
        },
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? AppColors.white : scheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 13.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : AppColors.transparent,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppText.base(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            7.horizontalSpace,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.white.withValues(alpha: 0.22)
                    : scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '$count',
                style: AppText.base(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.white : scheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
