import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_status_colors.dart';
import '../../../shared/widgets/app_status_pill.dart';
import '../models/referral_models.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// One referral commission row: initials avatar, referred user + plan and a
/// status pill on the left; earned amount and "rate of price" on the right.
/// Shared by the Refer & earn preview list and the paginated history.
class ReferralCommissionRow extends StatelessWidget {
  const ReferralCommissionRow({super.key, required this.referral});
  final Referral referral;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = referral.createdAt;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InitialsAvatar(name: referral.name),
          Gap.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        referral.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.base(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Gap.hSm,
                    Text(
                      referral.earned,
                      maxLines: 1,
                      style: AppText.base(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                3.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        referral.plan,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _meta(scheme),
                      ),
                    ),
                    Gap.hSm,
                    Text(
                      'referral.rate_of_price'.trParams({
                        'rate': referral.rate,
                        'price': referral.price,
                      }),
                      maxLines: 1,
                      style: _meta(scheme),
                    ),
                  ],
                ),
                Gap.vSm,
                Row(
                  children: [
                    AppStatusPill(
                      label: AppStatusColors.label(referral.status),
                      color: AppStatusColors.of(referral.status, scheme),
                    ),
                    const Spacer(),
                    if (date != null) ...[
                      Icon(
                        Icons.schedule_rounded,
                        size: 13.w,
                        color: scheme.onSurfaceVariant,
                      ),
                      Gap.hXs,
                      Text(
                        DateFormat('d MMM yyyy').format(date.toLocal()),
                        style: _meta(scheme).copyWith(fontSize: 11.sp),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _meta(ColorScheme scheme) => AppText.base(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    color: scheme.onSurfaceVariant,
  );
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name});
  final String name;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40.w,
      height: 40.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primary.withValues(alpha: 0.10),
      ),
      child: Text(
        _initials,
        style: AppText.base(
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
          color: scheme.primary,
        ),
      ),
    );
  }
}
