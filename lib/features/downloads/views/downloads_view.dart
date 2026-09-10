import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/icon_leading_row.dart';
import '../../../shared/widgets/key_value_row.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/downloads_controller.dart';
import '../models/download_models.dart';

/// Downloads & guides — three grouped card sections (Trading platform, Read
/// first, Video) of tappable rows. Fully theme-driven and reactive via
/// [DownloadsController].
class DownloadsView extends StatelessWidget {
  const DownloadsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<DownloadsController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'downloads.title'.tr),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
            sliver: SliverToBoxAdapter(
              child: Obx(
                () => DataStateBuilder<List<DownloadSection>>(
                  state: c.state,
                  onRetry: c.load,
                  skeleton: const ListSkeleton(),
                  builder: (sections) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var s = 0; s < sections.length; s++) ...[
                        if (s > 0) SizedBox(height: 26.h),
                        FadeSlideIn(
                          order: s * 2,
                          child: SectionHeader(sections[s].title),
                        ),
                        FadeSlideIn(
                          order: s * 2 + 1,
                          child: _SectionCard(section: sections[s]),
                        ),
                      ],
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});
  final DownloadSection section;

  @override
  Widget build(BuildContext context) {
    return RulesCard(
      children: [
        for (var i = 0; i < section.items.length; i++)
          IconLeadingRow(
            icon: section.items[i].icon,
            title: section.items[i].title,
            subtitle: section.items[i].subtitle,
            showDivider: i != section.items.length - 1,
            trailing: section.items[i].meta == null
                ? null
                : _Meta(text: section.items[i].meta!),
            onTap: () {},
          ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface.withValues(alpha: 0.55),
      ),
    );
  }
}
