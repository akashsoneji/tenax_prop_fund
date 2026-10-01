import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../controllers/settings_controller.dart';
import '../widgets/security_section.dart';
import '../../../shared/theme/app_spacing.dart';

/// Settings presented as a preference list: a summary hero at the top showing
/// the active choices, then grouped cards where every option is a full-width
/// row (icon + title + description + radio). Tapping a row applies instantly.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      resizeToAvoidBottomInset: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'settings.title'.tr),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeSlideIn(
                    order: 0,
                    child: Obx(
                      () => _SummaryHero(
                        themeValue: _themeLabel(s.themeMode),
                        languageValue: s.locale.languageCode == 'hi'
                            ? 'settings.language_hi'.tr
                            : 'settings.language_en'.tr,
                      ),
                    ),
                  ),
                  20.verticalSpace,
                  FadeSlideIn(
                    order: 1,
                    child: _SectionHeader(
                      icon: Icons.palette_outlined,
                      title: 'settings.theme'.tr,
                      caption: 'settings.theme_caption'.tr,
                    ),
                  ),
                  10.verticalSpace,
                  FadeSlideIn(
                    order: 2,
                    child: Obx(
                      () => _OptionGroup(
                        children: [
                          _OptionRow(
                            icon: Icons.brightness_auto_rounded,
                            title: 'settings.theme_system'.tr,
                            description: 'settings.theme_system_desc'.tr,
                            selected: s.themeMode == ThemeMode.system,
                            onTap: () => s.setThemeMode(ThemeMode.system),
                          ),
                          _OptionRow(
                            icon: Icons.light_mode_rounded,
                            title: 'settings.theme_light'.tr,
                            description: 'settings.theme_light_desc'.tr,
                            selected: s.themeMode == ThemeMode.light,
                            onTap: () => s.setThemeMode(ThemeMode.light),
                          ),
                          _OptionRow(
                            icon: Icons.dark_mode_rounded,
                            title: 'settings.theme_dark'.tr,
                            description: 'settings.theme_dark_desc'.tr,
                            selected: s.themeMode == ThemeMode.dark,
                            onTap: () => s.setThemeMode(ThemeMode.dark),
                          ),
                        ],
                      ),
                    ),
                  ),
                  22.verticalSpace,
                  FadeSlideIn(
                    order: 3,
                    child: _SectionHeader(
                      icon: Icons.language_rounded,
                      title: 'settings.language'.tr,
                      caption: 'settings.language_caption'.tr,
                    ),
                  ),
                  10.verticalSpace,
                  FadeSlideIn(
                    order: 4,
                    child: Obx(
                      () => _OptionGroup(
                        children: [
                          _OptionRow(
                            icon: Icons.abc_rounded,
                            title: 'settings.language_en'.tr,
                            description: 'settings.language_en_desc'.tr,
                            selected: s.locale.languageCode != 'hi',
                            onTap: () => s.setLocale(const Locale('en')),
                          ),
                          _OptionRow(
                            icon: Icons.translate_rounded,
                            title: 'settings.language_hi'.tr,
                            description: 'settings.language_hi_desc'.tr,
                            selected: s.locale.languageCode == 'hi',
                            onTap: () => s.setLocale(const Locale('hi')),
                          ),
                        ],
                      ),
                    ),
                  ),
                  22.verticalSpace,
                  FadeSlideIn(
                    order: 5,
                    child: _SectionHeader(
                      icon: Icons.shield_outlined,
                      title: 'settings.security.title'.tr,
                      caption: 'settings.security.caption'.tr,
                    ),
                  ),
                  10.verticalSpace,
                  const FadeSlideIn(order: 6, child: SecuritySection()),
                  18.verticalSpace,
                  FadeSlideIn(
                    order: 7,
                    child: Text(
                      'settings.footer_note'.tr,
                      textAlign: TextAlign.center,
                      style: AppText.label(
                        fontSize: 11.sp,
                        color: scheme.onSurface.withValues(alpha: 0.5),
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

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'settings.theme_light'.tr;
      case ThemeMode.dark:
        return 'settings.theme_dark'.tr;
      case ThemeMode.system:
        return 'settings.theme_system'.tr;
    }
  }
}

/// Top card summarising what is currently active.
class _SummaryHero extends StatelessWidget {
  const _SummaryHero({required this.themeValue, required this.languageValue});

  final String themeValue;
  final String languageValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.16),
            scheme.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'settings.subtitle'.tr,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.subtitle(
              fontSize: 13.sp,
              color: scheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          14.verticalSpace,
          Row(
            children: [
              _SummaryStat(
                icon: Icons.palette_outlined,
                label: 'settings.theme'.tr,
                value: themeValue,
              ),
              Gap.hMd,
              Container(
                width: 1,
                height: 34.h,
                color: scheme.onSurface.withValues(alpha: 0.12),
              ),
              Gap.hMd,
              _SummaryStat(
                icon: Icons.language_rounded,
                label: 'settings.language'.tr,
                value: languageValue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14.sp, color: scheme.primary),
              6.horizontalSpace,
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    fontSize: 11.sp,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          Gap.vXs,
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.title(fontSize: 15.sp, color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.caption,
  });

  final IconData icon;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.sp, color: scheme.primary),
        Gap.hSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title(
                  fontSize: 14.sp,
                  color: scheme.onSurface.withValues(alpha: 0.9),
                ),
              ),
              Gap.vXxs,
              Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(
                  fontSize: 11.sp,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card that stacks option rows with hairline dividers between them.
class _OptionGroup extends StatelessWidget {
  const _OptionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 56.w,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        );
      }
      rows.add(children[i]);
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(children: rows),
    );
  }
}

/// A single selectable preference row.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        color: selected
            ? scheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.16)
                    : scheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Icon(
                icon,
                size: 18.sp,
                color: selected
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Gap.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(
                      fontSize: 14.sp,
                      color: selected ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                  Gap.vXxs,
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(
                      fontSize: 11.sp,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            10.horizontalSpace,
            _SelectionDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 20.w,
      height: 20.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? scheme.primary : Colors.transparent,
        border: Border.all(
          color: selected
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.28),
          width: 1.6,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 13.sp, color: scheme.onPrimary)
          : null,
    );
  }
}
