import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/referral_models.dart';

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
          SizedBox(width: 12.w),
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
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      referral.earned,
                      maxLines: 1,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
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
                    SizedBox(width: 8.w),
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
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _StatusPill(status: referral.status),
                    const Spacer(),
                    if (date != null) ...[
                      Icon(
                        Icons.schedule_rounded,
                        size: 13.w,
                        color: scheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 4.w),
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

  TextStyle _meta(ColorScheme scheme) => GoogleFonts.beVietnamPro(
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
        style: GoogleFonts.beVietnamPro(
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
          color: scheme.primary,
        ),
      ),
    );
  }
}

/// Capitalised status with a leading dot, coloured by outcome.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final key = status.toLowerCase();
    final Color color = switch (key) {
      'approved' || 'paid' || 'completed' => AppColors.success,
      'rejected' || 'cancelled' || 'canceled' || 'failed' => scheme.error,
      _ => AppColors.warningInk,
    };
    final label = key.isEmpty ? '-' : key[0].toUpperCase() + key.substring(1);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 5.w),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
