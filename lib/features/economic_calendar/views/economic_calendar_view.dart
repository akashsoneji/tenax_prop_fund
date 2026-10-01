import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_info_banner.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/key_value_row.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/economic_calendar_controller.dart';
import '../models/economic_event.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// Economic calendar — events grouped by day in surface cards, each row with a
/// currency chip, title, forecast/previous detail and an impact label. Closes
/// with a "News trading is allowed" info banner. Theme-driven and reactive.
class EconomicCalendarView extends StatelessWidget {
  const EconomicCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<EconomicCalendarController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'economic_calendar.title'.tr),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
            sliver: SliverToBoxAdapter(
              child: Obx(
                () => DataStateBuilder<List<EventDay>>(
                  state: c.state,
                  onRetry: c.load,
                  skeleton: const ListSkeleton(rows: 7),
                  builder: (days) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: days.length,
                        itemBuilder: (context, d) {
                          final day = days[d];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (d > 0) Gap.vXl,
                              FadeSlideIn(
                                order: d * 2,
                                child: SectionHeader(day.label),
                              ),
                              FadeSlideIn(
                                order: d * 2 + 1,
                                child: RulesCard(
                                  children: [
                                    for (var i = 0; i < day.events.length; i++)
                                      _EventRow(
                                        event: day.events[i],
                                        showDivider: i != day.events.length - 1,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      22.verticalSpace,
                      FadeSlideIn(
                        order: 12,
                        child: AppInfoBanner(
                          tone: BannerTone.warning,
                          title: 'economic_calendar.news_allowed'.tr,
                          body: 'economic_calendar.news_allowed_body'.tr,
                        ),
                      ),
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

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.showDivider});
  final EconomicEvent event;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CurrencyChip(code: event.currency),
              Gap.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: AppText.base(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    Gap.vXs,
                    Text(
                      event.detail,
                      style: AppText.base(
                        fontSize: 12.5.sp,
                        height: 1.35,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              10.horizontalSpace,
              Text(
                event.impactLabel,
                style: AppText.base(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: event.impactColor(scheme),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1.h,
            thickness: 1.h,
            indent: 14.w,
            endIndent: 14.w,
            color: scheme.onSurface.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 48.w,
      height: 44.h,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: Alignment.center,
      child: Text(
        code,
        style: AppText.base(
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
      ),
    );
  }
}
