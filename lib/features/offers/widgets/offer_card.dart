import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_pill.dart';
import '../models/offer_models.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// Compact voucher row: a tinted tag tile, the headline value with the code
/// underneath, and a trailing copy action (or a `Used` pill once redeemed).
/// Any `checks[]` that do not merely repeat the headline are shown as small
/// tick pills, with the expiry copy on the same footer line.
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer, this.onApply});

  final Offer offer;
  final ValueChanged<Offer>? onApply;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final used = offer.used;
    final accent = used ? scheme.onSurfaceVariant : scheme.primary;
    final checks = offer.checks
        .where((c) => c.toLowerCase() != offer.valueLabel.toLowerCase())
        .toList(growable: false);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onApply == null ? null : () => onApply!(offer),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TagTile(accent: accent, used: used),
                  10.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.valueLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.base(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: used
                                ? scheme.onSurfaceVariant
                                : scheme.onSurface,
                          ),
                        ),
                        Gap.vXxs,
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                offer.code,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.base(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: accent,
                                ),
                              ),
                            ),
                            5.horizontalSpace,
                            Icon(Icons.copy_rounded, size: 12.w, color: accent),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Gap.hSm,
                  _TrailingAction(
                    used: used,
                    onCopy: onApply == null ? null : () => onApply!(offer),
                  ),
                ],
              ),
              if (offer.description != null) ...[
                Gap.vSm,
                Text(
                  offer.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.base(
                    fontSize: 12.sp,
                    height: 1.3,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (checks.isNotEmpty || offer.exp.isNotEmpty) ...[
                10.verticalSpace,
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final check in checks)
                      _MetaPill(text: check, tick: true),
                    if (offer.exp.isNotEmpty)
                      _MetaPill(text: offer.exp, tick: false),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tinted rounded tile carrying the offer glyph.
class _TagTile extends StatelessWidget {
  const _TagTile({required this.accent, required this.used});
  final Color accent;
  final bool used;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38.w,
      height: 38.w,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: used ? 0.10 : 0.12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.local_offer_rounded, size: 18.w, color: accent),
    );
  }
}

/// Copy button while the offer is open, a muted `Used` pill once redeemed.
class _TrailingAction extends StatelessWidget {
  const _TrailingAction({required this.used, this.onCopy});
  final bool used;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (used) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_rounded,
              size: 12.w,
              color: scheme.onSurfaceVariant,
            ),
            Gap.hXs,
            Text(
              'offers.used'.tr,
              style: AppText.base(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onCopy,
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient(scheme),
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copy_rounded, size: 13.w, color: AppColors.white),
            5.horizontalSpace,
            Text(
              'offers.copy'.tr,
              style: AppText.base(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small footer pill — a green tick for `checks[]`, a clock for the expiry.
class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.text, required this.tick});
  final String text;
  final bool tick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppPill(
      label: text,
      color: scheme.onSurfaceVariant,
      bgColor: scheme.surfaceContainerHighest,
      labelColor: scheme.onSurfaceVariant,
      radius: 8,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      leading: Icon(
        tick ? Icons.check_rounded : Icons.schedule_rounded,
        size: 12.w,
        color: tick ? AppColors.success : scheme.onSurfaceVariant,
      ),
    );
  }
}
