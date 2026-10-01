import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../controllers/referral_controller.dart';
import '../models/referral_models.dart';
import '../../../shared/theme/app_spacing.dart';

/// Opens the "Withdraw referral earnings" sheet and loads the payout methods.
Future<void> showReferralWithdrawSheet(ReferralData data) {
  Get.find<ReferralController>().loadPayoutMethods();
  return Get.bottomSheet<void>(
    ReferralWithdrawSheet(data: data),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

/// Amount + payout method form. Submit logic lives in
/// [ReferralController.withdraw]; the sheet only closes on server success.
class ReferralWithdrawSheet extends StatefulWidget {
  const ReferralWithdrawSheet({super.key, required this.data});
  final ReferralData data;

  @override
  State<ReferralWithdrawSheet> createState() => _ReferralWithdrawSheetState();
}

class _ReferralWithdrawSheetState extends State<ReferralWithdrawSheet> {
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit(ReferralController c) async {
    FocusScope.of(context).unfocus();
    final ok = await c.withdraw(_amount.text);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ReferralController>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    // No viewInsets padding here: Get.bottomSheet already lifts the sheet above
    // the keyboard, adding it again doubles the offset and clips the sheet.
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'referral.withdraw_title'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, size: 20.w),
                  ),
                ],
              ),
              _BalanceStrip(data: widget.data),
              14.verticalSpace,
              _Label('referral.amount_usd'.tr),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: text.bodyMedium?.copyWith(fontSize: 14.sp),
                decoration: _decoration(context, hint: '0.00'),
              ),
              Gap.vMd,
              _Label('referral.payout_method'.tr),
              const _MethodPicker(),
              18.verticalSpace,
              Obx(
                () => AppGradientButton(
                  label: 'referral.withdraw_submit'.tr,
                  height: 46.h,
                  loading: c.isWithdrawing.value,
                  onPressed: c.isWithdrawing.value ? null : () => _submit(c),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoration(BuildContext context, {String? hint}) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    isDense: true,
    hintText: hint,
    filled: true,
    fillColor: scheme.surface,
    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
    enabledBorder: border(scheme.outlineVariant),
    focusedBorder: border(scheme.primary, 1.4),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// "Withdrawable: $x · Minimum $y" from the referral payload.
class _BalanceStrip extends StatelessWidget {
  const _BalanceStrip({required this.data});
  final ReferralData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 12.5.sp,
      color: scheme.onSurfaceVariant,
    );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text.rich(
        TextSpan(
          style: base,
          children: [
            TextSpan(text: '${'referral.withdrawable'.tr}: '),
            TextSpan(
              text: data.withdrawableLabel,
              style: base?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            TextSpan(
              text: ' · ${'referral.minimum'.tr} ${data.minWithdrawLabel}',
            ),
          ],
        ),
      ),
    );
  }
}

/// Payout-method dropdown with loading / "add a method" fallbacks.
class _MethodPicker extends StatelessWidget {
  const _MethodPicker();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ReferralController>();
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      if (c.methodsLoading.value && c.payoutMethods.isEmpty) {
        return SizedBox(
          height: 44.h,
          child: Center(
            child: SizedBox(
              width: 18.w,
              height: 18.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
      if (c.payoutMethods.isEmpty) {
        return OutlinedButton.icon(
          onPressed: () async {
            await Get.toNamed(AppRoutes.payoutMethods);
            c.loadPayoutMethods();
          },
          icon: Icon(Icons.add_rounded, size: 18.w),
          label: Text('referral.add_payout_method'.tr),
          style: OutlinedButton.styleFrom(
            minimumSize: Size.fromHeight(44.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
      final selected = c.selectedMethodId.value;
      return DropdownButtonFormField<String>(
        initialValue: c.payoutMethods.any((m) => m.id == selected)
            ? selected
            : null,
        isExpanded: true,
        icon: Icon(
          Icons.expand_more_rounded,
          size: 20.w,
          color: scheme.onSurfaceVariant,
        ),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontSize: 14.sp),
        decoration: _decoration(context),
        items: [
          for (final m in c.payoutMethods)
            DropdownMenuItem<String>(
              value: m.id,
              child: Text(
                '${m.name} · ${m.type.toUpperCase()} · ${m.currency}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (v) {
          if (v != null) c.selectMethod(v);
        },
      );
    });
  }
}
