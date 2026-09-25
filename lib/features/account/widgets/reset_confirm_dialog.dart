import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../controllers/account_controller.dart';
import '../models/account_models.dart';

/// Confirm-reset popup: restates the reset price for the login and lets the
/// user pick the payment method before the purchase is submitted. Mirrors the
/// web "Confirm account reset" modal.
///
/// Methods are addressed by list index, not by `id` — the API can return two
/// methods sharing the same `id` (a manual and a gateway variant).
class ResetConfirmDialog extends StatelessWidget {
  const ResetConfirmDialog({
    super.key,
    required this.controller,
    required this.data,
  });

  final AccountController controller;
  final ResetData data;

  static Future<void> show(AccountController controller, ResetData data) {
    return Get.dialog<void>(
      ResetConfirmDialog(controller: controller, data: data),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: scheme.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(login: data.login),
              SizedBox(height: 14.h),
              _PriceBanner(data: data),
              SizedBox(height: 14.h),
              Text(
                'account.reset_confirm_blurb'.tr,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'account.reset_pay_with'.tr,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              SizedBox(height: 8.h),
              _MethodField(controller: controller, data: data),
              SizedBox(height: 12.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 15.w, color: scheme.onSurfaceVariant),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'account.reset_confirm_note'.tr,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        height: 1.45,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Obx(
                () => AppGradientButton(
                  label: 'account.reset_confirm_cta'.tr,
                  loading: controller.resetSubmitting.value,
                  onPressed: controller.selectedResetMethod.value == null
                      ? null
                      : controller.confirmReset,
                ),
              ),
              SizedBox(height: 6.h),
              TextButton(
                onPressed: Get.back,
                child: Text(
                  'common.cancel'.tr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.login});
  final String login;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(Icons.restart_alt_rounded,
              size: 20.w, color: scheme.primary),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'account.reset_confirm_title'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                '${'account.reset'.tr} $login',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: Get.back,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.close_rounded,
              size: 20.w, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Reset price front and centre, with the original fee struck through so the
/// discount reads at a glance.
class _PriceBanner extends StatelessWidget {
  const _PriceBanner({required this.data});
  final ResetData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.16),
            scheme.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'account.reset_price'.tr.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        data.resetPrice,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 3.h),
                      child: Text(
                        data.originalFee,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          decoration: TextDecoration.lineThrough,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (data.percentLabel.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                data.percentLabel,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tappable field showing the current method; opens the picker sheet.
class _MethodField extends StatelessWidget {
  const _MethodField({required this.controller, required this.data});

  final AccountController controller;
  final ResetData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final method = controller.selectedResetMethod.value;
      return InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () => _openSheet(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          decoration: AppTheme.surfaceCard(scheme, radius: 14.r),
          child: Row(
            children: [
              Icon(_iconFor(method), size: 18.w, color: scheme.primary),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  method?.name ?? 'account.reset_select_method'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: method == null
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
              ),
              if (method != null) _ModeChip(method: method),
              SizedBox(width: 6.w),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20.w, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      );
    });
  }

  void _openSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (_) => _MethodSheet(controller: controller, data: data),
    );
  }
}

class _MethodSheet extends StatelessWidget {
  const _MethodSheet({required this.controller, required this.data});

  final AccountController controller;
  final ResetData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'account.reset_pay_with'.tr,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            SizedBox(height: 12.h),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: data.paymentMethods.length,
                separatorBuilder: (_, _) => SizedBox(height: 8.h),
                itemBuilder: (_, i) {
                  final method = data.paymentMethods[i];
                  return Obx(
                    () => _MethodTile(
                      method: method,
                      selected: identical(
                          controller.selectedResetMethod.value, method),
                      onTap: () {
                        controller.selectResetMethod(method);
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final ResetPaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.10)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            Icon(_iconFor(method), size: 18.w, color: scheme.primary),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                method.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            _ModeChip(method: method),
            SizedBox(width: 8.w),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18.w,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.method});
  final ResetPaymentMethod method;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = method.isManual
        ? 'account.reset_method_manual'.tr
        : 'account.reset_method_online'.tr;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
      ),
    );
  }
}

IconData _iconFor(ResetPaymentMethod? method) {
  if (method == null) return Icons.account_balance_wallet_outlined;
  if (method.type == 'crypto') return Icons.currency_bitcoin_rounded;
  return Icons.credit_card_rounded;
}
