import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/offers_controller.dart';
import '../models/offer_models.dart';
import '../widgets/offer_card.dart';

/// "My offers" screen. Two labelled sections — offers the user can apply now
/// and locked rewards — each a stack of [OfferCard]s driven by
/// [OffersController]. Values are demo data so the layout can be validated
/// end-to-end; swap the Rx lists for repository calls later.
class OffersView extends StatelessWidget {
  const OffersView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<OffersController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'offers.title'.tr),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
              child: Obx(
                () => DataStateBuilder<OffersData>(
                  state: c.state,
                  onRetry: c.load,
                  skeleton: const ListSkeleton(rows: 4),
                  builder: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionLabel('Available Now'),
                      for (final o in data.available) OfferCard(offer: o),
                      SizedBox(height: 18.h),
                      const _SectionLabel('Locked Rewards'),
                      for (final o in data.locked) OfferCard(offer: o),
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

/// Small section header used between the two offer blocks, with the same
/// subtle rise-in entrance as the rewards screen.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.page,
      curve: AppMotion.enter,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16.h),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(left: 2.w, bottom: 12.h),
        child: Text(
          text,
          style: GoogleFonts.beVietnamPro(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
