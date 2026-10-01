import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/invoice_viewer_controller.dart';
import '../models/billing_models.dart';
import '../widgets/invoice_web_view.dart';
import '../../../shared/widgets/app_card.dart';

/// Invoice viewer opened from a Billing row. The server-rendered invoice sits
/// on a white card (it's a printable light sheet); a bottom bar offers Share
/// and Download PDF.
class InvoiceViewerView extends GetView<InvoiceViewerController> {
  const InvoiceViewerView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        // The invoice scrolls inside its own WebView; the page itself must not.
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          Obx(() => PinnedGradientAppBar(title: controller.title)),
          SliverFillRemaining(
            hasScrollBody: true,
            child: Obx(
              () => DataStateBuilder<InvoiceDocument>(
                state: controller.state,
                onRetry: controller.load,
                skeleton: const _InvoiceSkeleton(),
                emptyIcon: Icons.receipt_long_outlined,
                emptyTitle: 'billing.invoice_unavailable'.tr,
                emptyMessage: 'billing.invoice_unavailable_body'.tr,
                builder: (invoice) => Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: ColoredBox(
                      color: Colors.white,
                      child: InvoiceWebView(
                        html: invoice.html,
                        onReady: controller.attachWebActions,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Obx(
        () => controller.state.isSuccess
            ? const _ActionBar()
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// Share (secondary) + Download PDF (primary), standard 44 height.
class _ActionBar extends StatelessWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final controller = Get.find<InvoiceViewerController>();
    return SafeArea(
      minimum: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: controller.share,
              icon: Icon(Icons.ios_share_rounded, size: 18.w),
              label: Text(
                'billing.invoice_share'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onSurface,
                minimumSize: Size.fromHeight(44.h),
                side: BorderSide(color: scheme.outlineVariant),
                textStyle: text.labelLarge?.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
          10.horizontalSpace,
          Expanded(
            child: AppGradientButton(
              label: 'billing.invoice_download'.tr,
              icon: Icons.download_rounded,
              height: 44.h,
              onPressed: controller.download,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceSkeleton extends StatelessWidget {
  const _InvoiceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      child: AppShimmer(child: AppCard(radius: 14.r)),
    );
  }
}
