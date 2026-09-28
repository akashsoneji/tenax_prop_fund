import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_choice_chip.dart';
import '../../../shared/widgets/app_empty_view.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../../../core/state/data_state.dart';
import '../controllers/account_controller.dart';
import '../models/account_models.dart';
import '../widgets/account_analytics_widgets.dart';
import '../widgets/account_overview_widgets.dart';
import '../widgets/account_tab_widgets.dart';
import '../widgets/reset_confirm_dialog.dart';

/// Account detail screen — a mobile-native version of the web
/// `My accounts › Account overview` page, with four tabs (Account overview,
/// Trading overview, Platform, Reset) backed by three Inertia endpoints.
class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<AccountController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'account.title'.tr),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Obx(() => _Tabs(
                        selected: c.selectedTab.value,
                        onChanged: c.selectTab,
                      )),
                  SizedBox(height: 12.h),
                  _TabBody(controller: c),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab switcher
// ---------------------------------------------------------------------------
class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onChanged});
  final AccountDetailTab selected;
  final ValueChanged<AccountDetailTab> onChanged;

  static const _labels = {
    AccountDetailTab.overview: 'account.tab_overview',
    AccountDetailTab.trading: 'account.tab_trading',
    AccountDetailTab.platform: 'account.tab_platform',
    AccountDetailTab.reset: 'account.tab_reset',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: AccountDetailTab.values.length,
        separatorBuilder: (_, _) => SizedBox(width: 10.w),
        itemBuilder: (context, i) {
          final tab = AccountDetailTab.values[i];
          return _TabChip(
            label: (_labels[tab] ?? '').tr,
            selected: tab == selected,
            onTap: () => onChanged(tab),
          );
        },
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
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
    return AppChoiceChip(
      label: label,
      selected: selected,
      onTap: onTap,
      animate: true,
      alignment: Alignment.center,
      radius: 22,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      selectedColor: AppColors.white,
      unselectedColor: scheme.onSurfaceVariant,
      selectedFill: scheme.primary,
      unselectedFill: AppColors.transparent,
      borderColor: selected
          ? scheme.primary
          : scheme.primary.withValues(alpha: 0.22),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab body router
// ---------------------------------------------------------------------------
class _TabBody extends StatelessWidget {
  const _TabBody({required this.controller});
  final AccountController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.selectedTab.value) {
        case AccountDetailTab.overview:
          return DataStateBuilder<AccountData>(
            state: controller.state,
            onRetry: controller.load,
            skeleton: const _OverviewSkeleton(),
            builder: (data) => _OverviewTab(controller: controller, data: data),
          );
        case AccountDetailTab.trading:
          return DataStateBuilder<AccountData>(
            state: controller.state,
            onRetry: controller.load,
            skeleton: const _OverviewSkeleton(),
            builder: (data) => _TradingTab(controller: controller, data: data),
          );
        case AccountDetailTab.platform:
          return DataStateBuilder<PlatformData>(
            state: controller.platform.value ?? const DataInitial(),
            onRetry: controller.retryPlatform,
            skeleton: const _OverviewSkeleton(),
            builder: (data) => _PlatformTab(controller: controller, data: data),
          );
        case AccountDetailTab.reset:
          return DataStateBuilder<ResetData>(
            state: controller.reset.value ?? const DataInitial(),
            onRetry: controller.retryReset,
            skeleton: const _OverviewSkeleton(),
            builder: (data) => _ResetTab(controller: controller, data: data),
          );
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Account overview tab
// ---------------------------------------------------------------------------
class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.controller, required this.data});
  final AccountController controller;
  final AccountData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AccountSummaryHero(header: data.header, stats: data.stats),
        SizedBox(height: 16.h),
        Obx(() => AccountHeaderCard(
              header: data.header,
              credentials: data.credentials,
              cycle: data.cycle,
              revealed: controller.revealPassword.value,
              onReveal: controller.toggleReveal,
              onCopyLogin: () =>
                  controller.copy(data.credentials.login, 'account.copied'),
            )),
        SizedBox(height: 22.h),
        _SectionLabel('account.trading_objectives'.tr),
        SizedBox(height: 12.h),
        for (final o in data.objectives) ...[
          AccountObjectiveCard(objective: o),
          SizedBox(height: 12.h),
        ],
        if (data.health.isNotEmpty) ...[
          SizedBox(height: 6.h),
          AccountHealthCard(health: data.health),
        ],
        SizedBox(height: 18.h),
        // AppGradientButton(
        //   label: 'account.trade_now'.tr,
        //   icon: Icons.trending_up_rounded,
        //   onPressed: () =>
        //       controller.copy(data.tradeUrl, 'account.trade_link_copied'),
        // ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Trading overview tab
// ---------------------------------------------------------------------------
class _TradingTab extends StatelessWidget {
  const _TradingTab({required this.controller, required this.data});
  final AccountController controller;
  final AccountData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() => AccountSegmentedTabs(
              labels: [
                'account.detailed_stats'.tr,
                'account.analytics'.tr,
              ],
              selectedIndex: controller.tradingSub.value.index,
              onChanged: (i) =>
                  controller.selectTradingSub(TradingSubTab.values[i]),
            )),
        SizedBox(height: 18.h),
        Obx(() => controller.tradingSub.value == TradingSubTab.detailed
            ? _DetailedStats(data: data)
            : _Analytics(controller: controller, data: data)),
      ],
    );
  }
}

// Detailed stats: metric grid + recent trades.
class _DetailedStats extends StatelessWidget {
  const _DetailedStats({required this.data});
  final AccountData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel('account.insights'.tr),
        SizedBox(height: 12.h),
        AccountInsightsGrid(metrics: data.insights.metrics),
        SizedBox(height: 22.h),
        _SectionLabel('account.recent_trades'.tr),
        SizedBox(height: 12.h),
        if (data.trades.isEmpty)
          const AppEmptyView(
            messageKey: 'account.no_trades',
            icon: Icons.receipt_long_outlined,
          )
        else
          for (final t in data.trades) AccountTradeRow(trade: t),
      ],
    );
  }
}

// Analytics: equity-growth chart + performance breakdowns.
class _Analytics extends StatelessWidget {
  const _Analytics({required this.controller, required this.data});
  final AccountController controller;
  final AccountData data;

  @override
  Widget build(BuildContext context) {
    final insights = data.insights;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EquityGrowthCard(points: data.equity),
        SizedBox(height: 18.h),
        Obx(() => AccountPillSelector(
              labels: [
                'account.symbol_performance'.tr,
                'account.pl_weekday'.tr,
                'account.pl_hour'.tr,
                'account.win_loss'.tr,
              ],
              selectedIndex: controller.perfBreakdown.value.index,
              onChanged: (i) => controller
                  .selectPerfBreakdown(PerformanceBreakdown.values[i]),
            )),
        SizedBox(height: 14.h),
        Obx(() {
          switch (controller.perfBreakdown.value) {
            case PerformanceBreakdown.symbol:
              return PerformanceBarsCard(bars: insights.symbolBars);
            case PerformanceBreakdown.weekday:
              return PerformanceBarsCard(bars: insights.weekdayBars);
            case PerformanceBreakdown.hour:
              return PerformanceBarsCard(bars: insights.hourBars);
            case PerformanceBreakdown.winLoss:
              return WinLossCard(won: insights.won, lost: insights.lost);
          }
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Platform tab
// ---------------------------------------------------------------------------
class _PlatformTab extends StatelessWidget {
  const _PlatformTab({required this.controller, required this.data});
  final AccountController controller;
  final PlatformData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'account.connection_details'.tr,
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            AccountStatusPill(label: data.statusLabel, tone: data.tone),
          ],
        ),
        SizedBox(height: 14.h),
        Obx(() => AccountHeaderCard(
              header: AccountHeader(
                login: data.credentials.login,
                statusLabel: '',
                tone: AccountTone.neutral,
                planLabel: data.credentials.platform,
                phaseLabel: '',
                initialBalance: '—',
                leverage: 0,
                drawdownType: '',
                accountType: data.credentials.accountType,
              ),
              credentials: data.credentials,
              cycle: const AccountCycle(
                  phaseStarted: '—',
                  daysElapsed: 0,
                  timeLimit: '—',
                  nextReward: '—'),
              revealed: controller.revealPassword.value,
              onReveal: controller.toggleReveal,
              onCopyLogin: () =>
                  controller.copy(data.credentials.login, 'account.copied'),
            )),
        // const SizedBox(height: 22),
        // _SectionLabel('account.downloads'.tr),
        // const SizedBox(height: 12),
        // for (final d in data.downloads) ...[
        //   PlatformDownloadCard(
        //     download: d,
        //     onDownload: () =>
        //         controller.copy(d.href, 'account.download_link_copied'),
        //   ),
        //   const SizedBox(height: 12),
        // ],
        // const SizedBox(height: 6),
        // AppGradientButton(
        //   label: 'account.launch_web_terminal'.tr,
        //   icon: Icons.open_in_new_rounded,
        //   onPressed: () =>
        //       controller.copy(data.webTerminal, 'account.trade_link_copied'),
        // ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reset tab
// ---------------------------------------------------------------------------
class _ResetTab extends StatelessWidget {
  const _ResetTab({required this.controller, required this.data});
  final AccountController controller;
  final ResetData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: AppTheme.surfaceCard(scheme, radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${'account.reset'.tr} ${data.login}',
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface),
                    ),
                  ),
                  if (data.percentLabel.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(data.percentLabel,
                          style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warningInk)),
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              Text('account.reset_blurb'.tr,
                  style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.4,
                      color: scheme.onSurfaceVariant)),
              SizedBox(height: 14.h),
              _KvLine(k: 'account.reset_original_fee'.tr, v: data.originalFee),
              _KvLine(k: 'account.reset_price'.tr, v: data.resetPrice),
              _KvLine(k: 'account.reset_valid_until'.tr, v: data.validUntil),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        const ResetCarryList(),
        if (data.message.isNotEmpty) ...[
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            ),
            child: Text(data.message,
                style: TextStyle(
                    fontSize: 12.5.sp,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.85))),
          ),
        ],
        SizedBox(height: 18.h),
        AppGradientButton(
          label: 'account.reset_this'.tr,
          onPressed: data.eligible &&
                  data.quotable &&
                  data.paymentMethods.isNotEmpty
              ? () => ResetConfirmDialog.show(controller, data)
              : null,
        ),
      ],
    );
  }
}

class _KvLine extends StatelessWidget {
  const _KvLine({required this.k, required this.v});
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Expanded(
            child: Text(k,
                style: TextStyle(
                    fontSize: 13.sp, color: scheme.onSurfaceVariant)),
          ),
          Text(v,
              style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
          fontSize: 16.sp, fontWeight: FontWeight.w800, color: scheme.onSurface),
    );
  }
}


class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardSkeleton(lines: 5, height: 240.h),
        SizedBox(height: 16.h),
        ShimmerBox(height: 90.h, radius: 16.r),
        SizedBox(height: 22.h),
        CardSkeleton(lines: 3, height: 120.h),
        SizedBox(height: 12.h),
        CardSkeleton(lines: 3, height: 120.h),
      ],
    );
  }
}
