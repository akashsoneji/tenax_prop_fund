import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_info_banner.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/key_value_row.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/faq_controller.dart';
import '../models/faq_models.dart';

/// FAQ — grouped accordion. Each section is a surface card of expandable Q&A
/// rows; opening one collapses the others. Loading/error/empty are handled by
/// [DataStateBuilder] on the controller's `DataState<List<FaqSection>>`.
class FaqView extends StatelessWidget {
  const FaqView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<FaqController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'faq.title'.tr),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
            sliver: SliverToBoxAdapter(
              child: Obx(
                () => DataStateBuilder<List<FaqSection>>(
                  state: c.state,
                  onRetry: c.load,
                  skeleton: const ListSkeleton(),
                  builder: (sections) =>
                      _FaqBody(controller: c, sections: sections),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqBody extends StatelessWidget {
  const _FaqBody({required this.controller, required this.sections});

  final FaqController controller;
  final List<FaqSection> sections;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var s = 0; s < sections.length; s++) ...[
          if (s > 0) SizedBox(height: 24.h),
          FadeSlideIn(
            order: s * 2,
            child: SectionHeader(sections[s].title),
          ),
          FadeSlideIn(
            order: s * 2 + 1,
            child: RulesCard(
              children: [
                for (var i = 0; i < sections[s].items.length; i++)
                  _FaqTile(
                    controller: c,
                    section: s,
                    entry: sections[s].items[i],
                    item: i,
                    showDivider: i != sections[s].items.length - 1,
                  ),
              ],
            ),
          ),
        ],
        SizedBox(height: 22.h),
        FadeSlideIn(
          order: 8,
          child: AppInfoBanner(
            tone: BannerTone.info,
            title: 'faq.not_answered'.tr,
            body: 'faq.open_ticket'.tr,
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.controller,
    required this.section,
    required this.entry,
    required this.item,
    required this.showDivider,
  });

  final FaqController controller;
  final int section;
  final FaqItem entry;
  final int item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: () => controller.toggle(section, item),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 15.h, 16.w, 15.h),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          entry.question,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Obx(() {
                        final open = controller.isExpanded(section, item);
                        return AnimatedRotation(
                          turns: open ? 0.5 : 0,
                          duration: AppMotion.fast,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        );
                      }),
                    ],
                  ),
                  Obx(() {
                    final open = controller.isExpanded(section, item);
                    return AnimatedCrossFade(
                      firstChild: const SizedBox(width: double.infinity),
                      secondChild: Padding(
                        padding: EdgeInsets.only(top: 10.h),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            entry.answer,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13.5.sp,
                              height: 1.45,
                              color: scheme.onSurface.withValues(alpha: 0.62),
                            ),
                          ),
                        ),
                      ),
                      crossFadeState: open
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: AppMotion.base,
                      sizeCurve: AppMotion.enter,
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1.h,
            thickness: 1.h,
            indent: 16.w,
            endIndent: 16.w,
            color: scheme.onSurface.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}
