import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_theme.dart';
import '../controllers/configure_controller.dart';

/// Shows the selected payment method; tapping opens a scrollable bottom sheet
/// (30% of screen height) listing every method. Index 0 is the default.
class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({super.key, required this.c});

  final ConfigureController c;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openSheet(context),
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: AppTheme.surfaceCard(scheme, radius: 14.r),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 20.w, color: scheme.primary),
              SizedBox(width: 12.w),
              Expanded(
                child: Obx(() => Text(
                      c.selectedPaymentMethod?.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    )),
              ),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 22.w, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PaymentMethodSheet(c: c),
    );
  }
}

class _PaymentMethodSheet extends StatelessWidget {
  const _PaymentMethodSheet({required this.c});

  final ConfigureController c;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final methods = c.availablePaymentMethods;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.30,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10.h),
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
              child: Text(
                'configure.payment_method'.tr,
                style: text.titleMedium?.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                itemCount: methods.length,
                itemBuilder: (context, i) => Obx(() {
                  final selected = c.paymentMethod.value == i;
                  return _MethodOption(
                    label: methods[i].name,
                    selected: selected,
                    onTap: () {
                      c.setPaymentMethod(i);
                      Navigator.of(context).pop();
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  const _MethodOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: selected ? scheme.primary : Colors.transparent,
                width: 1.4.w,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 20.w,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
