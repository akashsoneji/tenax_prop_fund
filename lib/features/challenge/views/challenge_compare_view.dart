import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../controllers/challenge_controller.dart';
import '../models/challenge_models.dart';

class ChallengeCompareView extends StatelessWidget {
  const ChallengeCompareView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChallengeController>();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const PinnedGradientAppBar(title: 'Compare challenges'),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
            sliver: SliverToBoxAdapter(
              child: Obx(() {
                final data = controller.comparison.value;
                if (data == null) return const _CompareSkeleton();
                return _CompareBody(data: data);
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareBody extends StatelessWidget {
  const _CompareBody({required this.data});
  final ChallengeData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Compare challenges',
          style: GoogleFonts.beVietnamPro(
            fontSize: 26.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 16.h),
        for (final plan in data.plans) ...[
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: AppTheme.surfaceCard(scheme, radius: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name, style: GoogleFonts.beVietnamPro(fontSize: 18.sp, fontWeight: FontWeight.w800)),
                SizedBox(height: 4.h),
                Text('${plan.size} · ${plan.price}', style: GoogleFonts.beVietnamPro(color: scheme.primary, fontWeight: FontWeight.w700)),
                SizedBox(height: 12.h),
                for (final row in [...plan.challengeRules, ...plan.fundedRules])
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 7.h),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16.w, color: scheme.primary),
                        SizedBox(width: 8.w),
                        Expanded(child: Text(row.label, style: GoogleFonts.beVietnamPro(fontSize: 13.sp))),
                        Text(row.value, style: GoogleFonts.beVietnamPro(fontSize: 13.sp, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
        ],
      ],
    );
  }
}

class _CompareSkeleton extends StatelessWidget {
  const _CompareSkeleton();

  @override
  Widget build(BuildContext context) => Container(
        height: 240.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18.r),
        ),
      );
}
