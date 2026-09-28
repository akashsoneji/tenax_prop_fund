import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../widgets/payout_methods_manager.dart';
import '../widgets/warning_banner.dart';

/// Payout methods screen: KYC-name warning banner, then the same
/// list + Add / Edit / Delete UI used by the Rewards "Payout methods" tab.
class PayoutMethodsView extends StatelessWidget {
  const PayoutMethodsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      resizeToAvoidBottomInset: true,
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
                  WarningBanner(
                    title: 'payout_methods.name_match_title'.tr,
                    body: 'payout_methods.name_match_body'.tr,
                  ),
                  SizedBox(height: 18.h),
                  const PayoutMethodsManager(showTitle: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
