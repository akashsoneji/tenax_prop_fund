import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/payout_methods_controller.dart';
import '../models/payout_method.dart';
import 'add_payout_method_sheet.dart';
import 'payout_method_manage_row.dart';

/// Payout methods list with Add / Edit / Delete, backed by
/// [PayoutMethodsController] (GET list, POST create, PUT update, DELETE).
/// [onChanged] fires after any successful mutation.
class PayoutMethodsManager extends StatelessWidget {
  const PayoutMethodsManager({
    super.key,
    this.showTitle = true,
    this.skeleton = const ListSkeleton(),
    this.onChanged,
  });

  final bool showTitle;
  final Widget skeleton;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PayoutMethodsController>();
    return Obx(
      () => DataStateBuilder<List<PayoutMethod>>(
        state: controller.state,
        onRetry: controller.load,
        skeleton: skeleton,
        emptyIcon: Icons.account_balance_wallet_outlined,
        emptyTitle: 'rewards.no_method_title'.tr,
        emptyMessage: 'rewards.no_method_body'.tr,
        emptyActionLabel: 'rewards.add_method'.tr,
        onEmptyAction: () => _openAddSheet(context),
        builder: (methods) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTitle) ...[
              Text(
                'rewards.tab_payout_methods'.tr,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              SizedBox(height: 14.h),
            ],
            AppGradientButton(
              label: 'rewards.add_method'.tr,
              icon: Icons.add_rounded,
              height: 44.h,
              onPressed: () => _openAddSheet(context),
            ),
            SizedBox(height: 16.h),
            for (final m in methods)
              PayoutMethodManageRow(method: m, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context) async {
    final saved = await AddPayoutMethodSheet.show(context);
    if (saved == true) onChanged?.call();
  }
}
