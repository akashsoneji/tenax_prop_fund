import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/certificate_viewer_controller.dart';
import '../models/certificate_model.dart';
import '../widgets/certificate_meta_row.dart';
import '../widgets/certificate_web_view.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';

/// Single-certificate viewer. Shows the rendered document in a pinch-zoomable
/// WebView with the holder/issue/verification facts above it, and a bottom
/// action bar to save it as a PDF (OS print sheet) or copy its verify link.
///
/// The document itself is a printable light-themed sheet, so it sits on a white
/// card; every piece of app chrome around it follows the active theme.
class CertificateViewerView extends GetView<CertificateViewerController> {
  const CertificateViewerView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        // The document pans inside its own WebView, so the page itself must
        // not scroll — the sliver list only hosts the pinned app bar.
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: controller.certificate.name),
          SliverFillRemaining(
            hasScrollBody: true,
            child: Obx(
              () => DataStateBuilder<CertificateDocument>(
                state: controller.state,
                onRetry: controller.load,
                skeleton: const _CertificateViewerSkeleton(),
                builder: (document) => _Document(document: document),
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

class _Document extends StatelessWidget {
  const _Document({required this.document});

  final CertificateDocument document;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CertificateViewerController>();
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      child: Column(
        children: [
          CertificateMetaRow(document: document),
          14.verticalSpace,
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: ColoredBox(
                color: Colors.white,
                child: CertificateWebView(
                  html: document.html,
                  onReady: controller.attachWebActions,
                ),
              ),
            ),
          ),
          Gap.vMd,
        ],
      ),
    );
  }
}

/// Save-as-PDF (primary) + share-the-certificate (secondary), safe-area padded.
class _ActionBar extends StatelessWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = Get.find<CertificateViewerController>();

    return SafeArea(
      minimum: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: controller.share,
              icon: Icon(Icons.ios_share_rounded, size: 18.w),
              label: Text(
                'certificates.share'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onSurface,
                minimumSize: Size.fromHeight(54.h),
                side: BorderSide(
                  color: scheme.onSurface.withValues(alpha: 0.18),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),
          Gap.hMd,
          Expanded(
            child: AppGradientButton(
              label: 'certificates.download'.tr,
              icon: Icons.download_rounded,
              height: 54.h,
              onPressed: controller.download,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer skeleton shaped like the meta strip + certificate sheet.
// ---------------------------------------------------------------------------
class _CertificateViewerSkeleton extends StatelessWidget {
  const _CertificateViewerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardSkeleton(lines: 2, height: 78.h),
          14.verticalSpace,
          Expanded(
            child: AppShimmer(child: AppCard(radius: 18.r)),
          ),
        ],
      ),
    );
  }
}
