import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/certificates_controller.dart';
import '../models/certificate_model.dart';
import '../widgets/certificate_card.dart';

/// Certificates screen — a scrolling list of achievement cards driven by
/// [CertificatesController]. Loading/error/empty are handled by
/// [DataStateBuilder] on the controller's `DataState<List<Certificate>>`.
/// Pinned gradient app bar, surface-card rows, each with an optional progress
/// bar. Fully theme-driven (light/dark).
class CertificatesView extends StatelessWidget {
  const CertificatesView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<CertificatesController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'certificates.title'.tr),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            sliver: SliverToBoxAdapter(
              child: Obx(
                () => DataStateBuilder<List<Certificate>>(
                  state: c.state,
                  onRetry: c.load,
                  skeleton: const _CertificatesSkeleton(),
                  builder: (items) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < items.length; i++)
                        CertificateCard(certificate: items[i], index: i),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
      children: const [
        CardSkeleton(lines: 2, height: 120),
        SizedBox(height: 14),
        CardSkeleton(lines: 2, height: 96),
        SizedBox(height: 14),
        CardSkeleton(lines: 2, height: 96),
        SizedBox(height: 14),
        CardSkeleton(lines: 2, height: 96),
      ],
    );
  }
}
