import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/localization/backend_label_tr.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_dashed.dart';
import '../controllers/configure_controller.dart';
import '../../../shared/theme/app_spacing.dart';

/// Receipt-style order summary: plan header, choice chips, then a price
/// breakdown with a highlighted total. Rebuilds from [ConfigureController].
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.c});

  final ConfigureController c;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      // Touch reactive state so the card rebuilds on every change.
      c.selectedAddons.length;
      c.quantity.value;
      c.appliedCoupon.value;
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: AppTheme.surfaceCard(scheme, radius: 18.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PlanHeader(c: c),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 4.h),
              child: Wrap(spacing: 8.w, runSpacing: 8.h, children: _chips()),
            ),
            AppDashedDivider(color: scheme.outlineVariant),
            _PriceBreakdown(c: c),
          ],
        ),
      );
    });
  }

  List<Widget> _chips() {
    final platforms = c.availablePlatforms;
    return [
      if (platforms.isNotEmpty)
        _InfoChip(
          icon: Icons.dns_rounded,
          label: platforms[c.platform.value.clamp(0, platforms.length - 1)],
        ),
      _InfoChip(
        icon: Icons.swap_horiz_rounded,
        label: c.swap.value == 0
            ? 'configure.swap'.tr
            : 'configure.swap_free'.tr,
      ),
      if (c.selectedPaymentMethod != null)
        _InfoChip(
          icon: Icons.account_balance_wallet_outlined,
          label: trBackend(c.selectedPaymentMethod!.name),
        ),
      if (c.selectedAddons.isNotEmpty)
        _InfoChip(
          icon: Icons.extension_outlined,
          label: '${c.selectedAddons.length} ${'configure.addons'.tr}',
        ),
    ];
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.c});

  final ConfigureController c;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      color: scheme.primary.withValues(alpha: 0.06),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient(scheme),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 20.w,
              color: AppColors.white,
            ),
          ),
          Gap.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.planName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                Gap.vXxs,
                Text(
                  '${c.accountSize} · ${c.currency}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    fontSize: 12.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '× ${c.quantity.value}',
              style: text.labelLarge?.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      constraints: BoxConstraints(maxWidth: 0.8.sw),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.w, color: scheme.primary),
          6.horizontalSpace,
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown({required this.c});

  final ConfigureController c;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hasDiscount = c.appliedCoupon.value != null && c.discount > 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
      child: Column(
        children: [
          _PriceLine(label: 'configure.subtotal'.tr, value: '\$${c.subtotal}'),
          if (hasDiscount)
            _PriceLine(
              label: '${'configure.discount'.tr} (${c.appliedCoupon.value})',
              value: '-\$${c.discount}',
              valueColor: AppColors.success,
            ),
          Gap.vSm,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'configure.total'.tr,
                  style: text.titleMedium?.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${c.currency} ${c.total}',
                style: text.headlineSmall?.copyWith(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(
                fontSize: 13.sp,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: text.bodyMedium?.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: valueColor ?? scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
