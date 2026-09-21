import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../controllers/settings_controller.dart';

/// Compact settings — theme as a 3-tile segmented picker and language as a
/// pill toggle. Selecting applies instantly and the reactive highlight moves
/// without leaving the screen.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'settings.title'.tr),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 32.h),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeSlideIn(
                    order: 0,
                    child: _Label(
                      icon: Icons.palette_outlined,
                      text: 'settings.theme'.tr,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  FadeSlideIn(
                    order: 1,
                    child: Obx(
                      () => Row(
                        children: [
                          _ThemeTile(
                            icon: Icons.brightness_auto_rounded,
                            label: 'settings.theme_system'.tr,
                            selected: s.themeMode == ThemeMode.system,
                            onTap: () => s.setThemeMode(ThemeMode.system),
                          ),
                          SizedBox(width: 10.w),
                          _ThemeTile(
                            icon: Icons.light_mode_rounded,
                            label: 'settings.theme_light'.tr,
                            selected: s.themeMode == ThemeMode.light,
                            onTap: () => s.setThemeMode(ThemeMode.light),
                          ),
                          SizedBox(width: 10.w),
                          _ThemeTile(
                            icon: Icons.dark_mode_rounded,
                            label: 'settings.theme_dark'.tr,
                            selected: s.themeMode == ThemeMode.dark,
                            onTap: () => s.setThemeMode(ThemeMode.dark),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 28.h),
                  FadeSlideIn(
                    order: 2,
                    child: _Label(
                      icon: Icons.language_rounded,
                      text: 'settings.language'.tr,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  FadeSlideIn(
                    order: 3,
                    child: Obx(
                      () => _PillToggle(
                        leftLabel: 'settings.language_en'.tr,
                        rightLabel: 'settings.language_hi'.tr,
                        rightSelected: s.locale.languageCode == 'hi',
                        onLeft: () => s.setLocale(const Locale('en')),
                        onRight: () => s.setLocale(const Locale('hi')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 17.sp, color: scheme.primary),
        SizedBox(width: 8.w),
        Text(
          text,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: scheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

/// One of the three theme segments — icon over label, highlights when selected.
class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.10)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24.sp,
                color: selected
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.6),
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-option sliding pill toggle (language).
class _PillToggle extends StatelessWidget {
  const _PillToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.rightSelected,
    required this.onLeft,
    required this.onRight,
  });

  final String leftLabel;
  final String rightLabel;
  final bool rightSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment:
                rightSelected ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 40.h,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(11.r),
                ),
              ),
            ),
          ),
          Row(
            children: [
              _PillHalf(
                label: leftLabel,
                selected: !rightSelected,
                onTap: onLeft,
              ),
              _PillHalf(
                label: rightLabel,
                selected: rightSelected,
                onTap: onRight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillHalf extends StatelessWidget {
  const _PillHalf({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 40.h,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: selected
                    ? scheme.onPrimary
                    : scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
