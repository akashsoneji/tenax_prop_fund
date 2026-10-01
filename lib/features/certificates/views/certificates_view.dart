import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/certificates_controller.dart';
import '../models/certificate_model.dart';
import '../widgets/certificate_card.dart';

/// Certificates screen — an achievement shelf driven by
/// [CertificatesController]: earned certificates first, then the ones still to
/// unlock. Loading/error/empty are handled by [DataStateBuilder] on the
/// controller's `DataState<CertificatesData>`. Fully theme-driven (light/dark).
class CertificatesView extends GetView<CertificatesController> {
  const CertificatesView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            PinnedGradientAppBar(title: 'certificates.title'.tr),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
              sliver: SliverToBoxAdapter(
                child: Obx(
                  () => DataStateBuilder<CertificatesData>(
                    state: controller.state,
                    onRetry: controller.load,
                    skeleton: const _CertificatesSkeleton(),
                    builder: (data) => _Shelf(data: data),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Earned certificates first so the shelf leads with what the trader has won.
class _Shelf extends StatelessWidget {
  const _Shelf({required this.data});

  final CertificatesData data;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CertificatesController>();
    final items = [
      ...data.certificates.where((c) => c.earned),
      ...data.certificates.where((c) => !c.earned),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++)
          CertificateCard(
            certificate: items[i],
            index: i,
            onTap: () => controller.openCertificate(items[i]),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer skeleton matching the screen's shape.
// ---------------------------------------------------------------------------
class _CertificatesSkeleton extends StatelessWidget {
  const _CertificatesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardSkeleton(lines: 3, height: 150.h),
        14.verticalSpace,
        CardSkeleton(lines: 3, height: 150.h),
        14.verticalSpace,
        CardSkeleton(lines: 3, height: 150.h),
        14.verticalSpace,
        CardSkeleton(lines: 3, height: 150.h),
      ],
    );
  }
}
