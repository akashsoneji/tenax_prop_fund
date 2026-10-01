import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// The ONE top bar
/// that stays **pinned** while the body scrolls, so the brand header never
/// slides away. Drop it as the first sliver inside a [CustomScrollView].
///
/// ```dart
/// CustomScrollView(slivers: [
///   const PinnedGradientAppBar(title: 'Account'),
///   ...
/// ])
/// ```
class PinnedGradientAppBar extends StatelessWidget {
  const PinnedGradientAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actions,
  });

  final String title;

  /// Shows the circular back button (defaults to [Get.back]). Set false on a
  /// root tab where there is nothing to pop.
  final bool showBack;
  final VoidCallback? onBack;

  /// Optional trailing widgets rendered on the right of the bar.
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
        backgroundColor: AppColors.transparent,
      surfaceTintColor: AppColors.transparent,
      toolbarHeight: 60.h,
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: AppTheme.heroGradient(scheme)),
      ),
      titleSpacing: 16.w,
      title: Row(
        children: [
          if (showBack) ...[
            _CircleBack(onTap: onBack ?? Get.back),
            Gap.hSm,
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.beVietnamPro(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...?actions,
        ],
      ),
    );
  }
}

class _CircleBack extends StatelessWidget {
  const _CircleBack({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 36.w,
          height: 36.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.16),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 18.w),
        ),
      ),
    );
  }
}
