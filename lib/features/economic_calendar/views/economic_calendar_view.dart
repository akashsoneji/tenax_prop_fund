import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/widgets/app_info_banner.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/key_value_row.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/economic_calendar_controller.dart';
import '../models/economic_event.dart';

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
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
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
                              if (d > 0) const SizedBox(height: 24),
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
                                        showDivider:
                                            i != day.events.length - 1,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 22),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CurrencyChip(code: event.currency),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.detail,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12.5,
                        height: 1.35,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                event.impactLabel,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: event.impactColor(scheme),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 14,
            endIndent: 14,
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
      width: 48,
      height: 44,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        code,
        style: GoogleFonts.beVietnamPro(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
      ),
    );
  }
}
