import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/app_toast.dart';
import '../controllers/payout_methods_controller.dart';
import '../models/payout_method.dart';
import 'add_payout_method_sheet.dart';

/// One saved payout method with edit + delete actions. [onChanged] fires
/// after a successful edit or delete so the host screen can refresh
/// dependent data.
class PayoutMethodManageRow extends StatelessWidget {
  const PayoutMethodManageRow({super.key, required this.method, this.onChanged});

  final PayoutMethod method;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 4.w, 10.h),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 18.w,
              color: scheme.primary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              method.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          IconButton(
            tooltip: 'rewards.history_edit'.tr,
            onPressed: () => _edit(context),
            icon: Icon(
              Icons.edit_outlined,
              size: 20.w,
              color: scheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            tooltip: 'payout_methods.remove'.tr,
            onPressed: () => _delete(context),
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20.w,
              color: scheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final saved = await AddPayoutMethodSheet.show(context, existing: method);
    if (saved == true) onChanged?.call();
  }

  Future<void> _delete(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await AppConfirmDialog.show(
      title: 'payout_methods.remove_title'.tr,
      confirmLabel: 'payout_methods.remove'.tr,
      destructive: true,
      message: TextSpan(
        children: [
          TextSpan(text: '${'payout_methods.remove'.tr} '),
          TextSpan(
            text: method.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          TextSpan(text: '? ${'payout_methods.remove_body'.tr}'),
        ],
      ),
    );
    if (!confirmed) return;

    final result =
        await Get.find<PayoutMethodsController>().deleteMethod(method.id);
    if (result.success) {
      onChanged?.call();
      AppToast.success('rewards.method_deleted'.tr);
    } else {
      AppToast.error(result.message ?? 'rewards.cannot_submit_body'.tr);
    }
  }
}
