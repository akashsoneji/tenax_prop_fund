import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/trading_rules_controller.dart';
import '../models/rules_models.dart';
import '../widgets/can_do_row.dart';
import '../widgets/closing_rule_card.dart';
import '../widgets/delay_row.dart';
import '../widgets/plan_row.dart';
import '../widgets/rules_hero_header.dart';
import '../widgets/rules_info_banner.dart';
import '../widgets/rules_segmented_tabs.dart';

/// Trading Rules screen — 4 tabs of rule content driven by
/// [TradingRulesController]. Loading/error/empty are handled by
/// [DataStateBuilder] on the controller's `DataState<TradingRulesData>`; the
/// real UI reads the loaded data through [Obx] for the tab switch. Layout per
/// tab:
///
///   * Tab 1 — intro banner ("Only three things close an account"), three
///     numbered danger cards, "you get a warning first" tip.
///   * Tab 2 — intro ("These delay money…"), checklist card with 10
///     rows, allowed-grid tip.
///   * Tab 3 — intro ("These delay money…"), 4 delay rows in a card.
///   * Tab 4 — "Your plan" header, 10 row settings card, full-rulebook CTA.
///
/// Tabs cross-fade + slide using a single `AnimatedSwitcher` so switching is
/// smooth and the list scroll position resets per tab (which is what users
/// expect when tabs are unrelated content blocks).
class TradingRulesView extends StatelessWidget {
  const TradingRulesView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TradingRulesController>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
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
      final tab = controller.selectedTab.value;
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
          key: ValueKey(tab),
          child: _buildTabBody(tab, data),
        ),
      );
    });
  }

  Widget _buildTabBody(RulesTab tab, TradingRulesData data) {
    switch (tab) {
      case RulesTab.closes:
        return _ClosesTab(data: data);
      case RulesTab.canDo:
        return _CanDoTab(data: data);
      case RulesTab.delays:
        return _DelaysTab(data: data);
      case RulesTab.everything:
        return _EverythingTab(data: data);
    }
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
          SizedBox(height: 16.h),
          CardSkeleton(lines: 3, height: 130.h),
          SizedBox(height: 12.h),
          CardSkeleton(lines: 3, height: 130.h),
          SizedBox(height: 12.h),
          CardSkeleton(lines: 2, height: 100.h),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — What closes an account
// ---------------------------------------------------------------------------

class _ClosesTab extends StatelessWidget {
  const _ClosesTab({required this.data});

  final TradingRulesData data;

  @override
  Widget build(BuildContext context) {
    return _TabScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RulesInfoBanner(
            icon: Icons.warning_amber_rounded,
            tone: RuleTone.danger,
            title: 'trading_rules.closes_title'.tr,
            body: 'trading_rules.closes_body'.tr,
          ),
          for (var i = 0; i < data.closingRules.length; i++)
            ClosingRuleCard(
              rule: data.closingRules[i],
              index: i,
            ),
          RulesInfoBanner(
            icon: Icons.info_outline_rounded,
            tone: RuleTone.warning,
            title: data.closingTip.title,
            body: data.closingTip.body,
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — What I can do
// ---------------------------------------------------------------------------

class _CanDoTab extends StatelessWidget {
  const _CanDoTab({required this.data});

  final TradingRulesData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = data.canDoRows;

    return _TabScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RulesInfoBanner(
            icon: Icons.info_outline_rounded,
            tone: RuleTone.warning,
            title: 'trading_rules.cando_title'.tr,
            body: 'trading_rules.cando_body'.tr,
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: AppTheme.surfaceCard(scheme, radius: 16),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  CanDoRowTile(
                    row: rows[i],
                    showDivider: i != rows.length - 1,
                  ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          RulesInfoBanner(
            icon: Icons.check_circle_outline_rounded,
            tone: RuleTone.info,
            title: 'trading_rules.grid_title'.tr,
            body: 'trading_rules.grid_body'.tr,
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3 — Delays a reward
// ---------------------------------------------------------------------------

class _DelaysTab extends StatelessWidget {
  const _DelaysTab({required this.data});

  final TradingRulesData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = data.delayRows;

    return _TabScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RulesInfoBanner(
            icon: Icons.info_outline_rounded,
            tone: RuleTone.warning,
            title: 'trading_rules.delays_title'.tr,
            body: 'trading_rules.delays_body'.tr,
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: AppTheme.surfaceCard(scheme, radius: 16),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  DelayRowTile(
                    row: rows[i],
                    showDivider: i != rows.length - 1,
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 4 — Everything / Your plan
// ---------------------------------------------------------------------------

class _EverythingTab extends StatelessWidget {
  const _EverythingTab({required this.data});

  final TradingRulesData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = data.planRows;

    return _TabScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'trading_rules.your_plan'.tr,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: AppTheme.surfaceCard(scheme, radius: 16),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  PlanRowTile(
                    row: rows[i],
                    showDivider: i != rows.length - 1,
                  ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: AppGradientButton(
              label: 'trading_rules.read_full'.tr,
              icon: Icons.menu_book_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('trading_rules.opening_rulebook'.tr),
                      duration: const Duration(seconds: 1),
                    ),
                  );
              },
            ),
          ),
          SizedBox(height: 8.h),
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
