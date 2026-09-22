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
/// and ones already redeemed — each a stack of [OfferCard]s driven by
/// [OffersController] from `GET /growth/offers`.
class OffersView extends StatelessWidget {
  const OffersView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<OffersController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      resizeToAvoidBottomInset: true,
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
                  builder: (data) {
                    if (data.isEmpty) {
                      return _EmptyOffers(message: 'offers.empty'.tr);
                    }
                    final available = data.available;
                    final used = data.used;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (available.isNotEmpty) ...[
                          _SectionLabel(
                            'offers.available_now'.tr,
                            count: available.length,
                          ),
                          for (final o in available)
                            OfferCard(offer: o, onApply: c.copyCode),
                        ],
                        if (used.isNotEmpty) ...[
                          SizedBox(height: 14.h),
                          _SectionLabel(
                            'offers.used_offers'.tr,
                            count: used.length,
                          ),
                          for (final o in used)
                            OfferCard(offer: o, onApply: c.copyCode),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the backend returns no offers at all.
class _EmptyOffers extends StatelessWidget {
  const _EmptyOffers({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 48.h),
      child: Column(
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 40.w,
            color: scheme.onSurfaceVariant,
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 14.sp,
              color: scheme.onSurfaceVariant,
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
  const _SectionLabel(this.text, {required this.count});
  final String text;
  final int count;

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
        padding: EdgeInsets.only(left: 2.w, bottom: 10.h),
        child: Row(
          children: [
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: scheme.onSurface,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
