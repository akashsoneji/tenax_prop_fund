import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../../../core/state/data_state.dart';
import '../controllers/account_controller.dart';
import '../models/account_models.dart';
import '../widgets/account_overview_widgets.dart';
import '../widgets/account_tab_widgets.dart';

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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Obx(() => _Tabs(
                        selected: c.selectedTab.value,
                        onChanged: c.selectTab,
                      )),
                  const SizedBox(height: 16),
                  Obx(() => _TabBody(controller: c)),
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
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: AccountDetailTab.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : AppColors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : scheme.onSurfaceVariant,
          ),
        ),
      ),
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
          builder: (data) => _TradingTab(data: data),
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
          builder: (data) => _ResetTab(data: data),
        );
    }
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
        Row(
          children: [
            Expanded(
              child: Text(
                '${'account.login'.tr} ${data.header.login}',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            AccountStatusPill(
                label: data.header.statusLabel, tone: data.header.tone),
          ],
        ),
        const SizedBox(height: 14),
        Obx(() => AccountHeaderCard(
              header: data.header,
              credentials: data.credentials,
              cycle: data.cycle,
              revealed: controller.revealPassword.value,
              onReveal: controller.toggleReveal,
              onCopyLogin: () =>
                  controller.copy(data.credentials.login, 'account.copied'),
            )),
        const SizedBox(height: 16),
        AccountStatGrid(stats: data.stats),
        const SizedBox(height: 22),
        _SectionLabel('account.trading_objectives'.tr),
        const SizedBox(height: 12),
        for (final o in data.objectives) ...[
          AccountObjectiveCard(objective: o),
          const SizedBox(height: 12),
        ],
        if (data.health.isNotEmpty) ...[
          const SizedBox(height: 6),
          AccountHealthCard(health: data.health),
        ],
        const SizedBox(height: 18),
        AppGradientButton(
          label: 'account.trade_now'.tr,
          icon: Icons.trending_up_rounded,
          onPressed: () =>
              controller.copy(data.tradeUrl, 'account.trade_link_copied'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Trading overview tab
// ---------------------------------------------------------------------------
class _TradingTab extends StatelessWidget {
  const _TradingTab({required this.data});
  final AccountData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel('account.insights'.tr),
        const SizedBox(height: 12),
        AccountInsightsGrid(metrics: data.insights.metrics),
        const SizedBox(height: 22),
        _SectionLabel('account.recent_trades'.tr),
        const SizedBox(height: 12),
        if (data.trades.isEmpty)
          _EmptyNote(text: 'account.no_trades'.tr)
        else
          for (final t in data.trades) AccountTradeRow(trade: t),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            AccountStatusPill(label: data.statusLabel, tone: data.tone),
          ],
        ),
        const SizedBox(height: 14),
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
        const SizedBox(height: 22),
        _SectionLabel('account.downloads'.tr),
        const SizedBox(height: 12),
        for (final d in data.downloads) ...[
          PlatformDownloadCard(
            download: d,
            onDownload: () =>
                controller.copy(d.href, 'account.download_link_copied'),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 6),
        AppGradientButton(
          label: 'account.launch_web_terminal'.tr,
          icon: Icons.open_in_new_rounded,
          onPressed: () =>
              controller.copy(data.webTerminal, 'account.trade_link_copied'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reset tab
// ---------------------------------------------------------------------------
class _ResetTab extends StatelessWidget {
  const _ResetTab({required this.data});
  final ResetData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface),
                    ),
                  ),
                  if (data.percentLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(data.percentLabel,
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warningInk)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('account.reset_blurb'.tr,
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: scheme.onSurfaceVariant)),
              const SizedBox(height: 14),
              _KvLine(k: 'account.reset_original_fee'.tr, v: data.originalFee),
              _KvLine(k: 'account.reset_price'.tr, v: data.resetPrice),
              _KvLine(k: 'account.reset_valid_until'.tr, v: data.validUntil),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const ResetCarryList(),
        if (data.message.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            ),
            child: Text(data.message,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: scheme.onSurface.withValues(alpha: 0.85))),
          ),
        ],
        const SizedBox(height: 18),
        AppGradientButton(
          label: 'account.reset_this'.tr,
          onPressed: data.eligible && data.quotable ? () {} : null,
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(k,
                style: TextStyle(
                    fontSize: 13, color: scheme.onSurfaceVariant)),
          ),
          Text(v,
              style: TextStyle(
                  fontSize: 13.5,
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
          fontSize: 18, fontWeight: FontWeight.w800, color: scheme.onSurface),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(text,
            style: TextStyle(
                fontSize: 13.5, color: scheme.onSurfaceVariant)),
      ),
    );
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        CardSkeleton(lines: 5, height: 240),
        SizedBox(height: 16),
        ShimmerBox(height: 90, radius: 16),
        SizedBox(height: 22),
        CardSkeleton(lines: 3, height: 120),
        SizedBox(height: 12),
        CardSkeleton(lines: 3, height: 120),
      ],
    );
  }
}
