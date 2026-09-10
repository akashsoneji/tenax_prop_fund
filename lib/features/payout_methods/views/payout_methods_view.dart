import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/payout_methods_controller.dart';
import '../models/payout_method.dart';
import '../widgets/payout_method_card.dart';
import '../widgets/warning_banner.dart';

/// Payout methods screen. An amber KYC-name warning banner on top, then one
/// [PayoutMethodCard] per demo destination. All state comes from
/// [PayoutMethodsController].
class PayoutMethodsView extends StatelessWidget {
  const PayoutMethodsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<PayoutMethodsController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'payout_methods.title'.tr),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const WarningBanner(
                    title: 'The name must match your KYC document',
                    body:
                        'A payout is rejected if the account name differs from '
                        'your verified ID — even by a middle name. This is the '
                        'single most common reason a first reward is delayed.',
                  ),
                  SizedBox(height: 18.h),
                  Obx(
                    () => DataStateBuilder<List<PayoutMethod>>(
                      state: c.state,
                      onRetry: c.load,
                      skeleton: const ListSkeleton(),
                      builder: (methods) => Column(
                        children: [
                          for (var i = 0; i < methods.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                  bottom: i == methods.length - 1 ? 0 : 14.h),
                              child: PayoutMethodCard(
                                method: methods[i],
                                delayMs: i * 70,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
