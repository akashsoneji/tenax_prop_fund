import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/trading_rules_controller.dart';
import '../models/rules_models.dart';
import '../widgets/rule_line_card.dart';
import '../widgets/rules_hero_header.dart';
import '../widgets/rules_info_banner.dart';
import '../widgets/rules_segmented_tabs.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';

/// Trading Rules screen — every tab and every rule line comes from
/// `GET /support/rules`, so the screen matches whatever the backend publishes.
/// Loading/error/empty are handled by [DataStateBuilder] on the controller's
/// `DataState<TradingRulesData>`; the tab switch is an [Obx] over the selected
/// tab value and cross-fades with a single [AnimatedSwitcher].
class TradingRulesView extends StatelessWidget {
  const TradingRulesView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TradingRulesController>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          RulesHeroHeader(title: 'trading_rules.title'.tr),
          const RulesSegmentedTabs(),
          Expanded(
            child: Obx(
              () => DataStateBuilder<TradingRulesData>(
                state: c.state,
                onRetry: c.load,
                skeleton: const _RulesSkeleton(),
                builder: (data) => _RulesBody(controller: c, data: data),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded body: the animated tab switch.
// ---------------------------------------------------------------------------

class _RulesBody extends StatelessWidget {
  const _RulesBody({required this.controller, required this.data});

  final TradingRulesController controller;
  final TradingRulesData data;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tabValue = controller.selectedTab.value;
      final tab = data.tabs.firstWhereOrNull((t) => t.value == tabValue);
      return AnimatedSwitcher(
        duration: AppMotion.page,
        switchInCurve: AppMotion.enter,
        switchOutCurve: AppMotion.transition,
        transitionBuilder: (child, anim) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(anim);
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(tabValue),
          child: _RulesTabBody(tab: tab, section: data.sectionFor(tabValue)),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// One tab: intro banner + the section's rule lines.
// ---------------------------------------------------------------------------

class _RulesTabBody extends StatelessWidget {
  const _RulesTabBody({required this.tab, required this.section});

  final RulesTab? tab;
  final RulesSection? section;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = section?.items ?? const <String>[];

    if (items.isEmpty) {
      return _TabScroll(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 16.h),
          child: Text(
            'trading_rules.no_rules'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final title = section?.title ?? tab?.label;

    return _TabScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // if (title != null)
          //   RulesInfoBanner(
          //     icon: Icons.info_outline_rounded,
          //     tone: RuleTone.warning,
          //     title: title,
          //     body: section?.body ?? 'trading_rules.section_body'.tr,
          //   ),
          AppCard(
            radius: 16.r,
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  RuleLineTile(
                    number: i + 1,
                    text: items[i],
                    showDivider: i != items.length - 1,
                  ),
              ],
            ),
          ),
          Gap.vSm,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer skeleton matching the screen's shape (hero + rule cards).
// ---------------------------------------------------------------------------

class _RulesSkeleton extends StatelessWidget {
  const _RulesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroSkeleton(height: 96.h),
          Gap.vLg,
          CardSkeleton(lines: 3, height: 130.h),
          Gap.vMd,
          CardSkeleton(lines: 3, height: 130.h),
          Gap.vMd,
          CardSkeleton(lines: 2, height: 100.h),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable scroll wrapper — gives every tab the same overscroll + padding.
// ---------------------------------------------------------------------------

class _TabScroll extends StatelessWidget {
  const _TabScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(bottom: 24.h),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );
  }
}
