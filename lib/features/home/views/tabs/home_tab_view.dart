import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/flavor/flavor_resolver.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/data_state_builder.dart';
import '../../../../shared/widgets/skeletons/skeletons.dart';
import '../../controllers/home_controller.dart';
import '../../models/dashboard_models.dart';

/// The Home (Portfolio) tab — a next-generation, mobile-first dashboard driven
/// entirely by `HomeController` (GetX): a glass brand header, an immersive
/// gradient equity hero with a live pulse, KPI tiles, quick actions, risk
/// overview, recent activity and a referral prompt. Live equity ticks arrive
/// over the Pusher socket and patch the controller state, which rebuilds this
/// view through `DataStateBuilder`. Fully theme-token driven (light/dark) and
/// localized through `.tr`.
class HomeTabView extends GetView<HomeController> {
  const HomeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: Obx(
                () => DataStateBuilder<DashboardData>(
                  state: controller.state,
                  onRetry: controller.load,
                  skeleton: const _HomeSkeleton(),
                  emptyTitle: 'home.no_dashboard'.tr,
                  emptyMessage: 'home.no_dashboard_body'.tr,
                  builder: (data) => RefreshIndicator(
                    onRefresh: controller.refreshData,
                    color: scheme.primary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      children: [
                        _EquityHero(data: data),
                        if (data.kpis.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _KpiGrid(kpis: data.kpis),
                        ],
                        const SizedBox(height: 24),
                        _SectionLabel('home.quick_actions'.tr,
                            actionLabel: 'home.recommended'.tr),
                        const SizedBox(height: 14),
                        const _QuickActions(),
                        if (data.health.isNotEmpty) ...[
                          const SizedBox(height: 26),
                          _SectionLabel('home.account_health'.tr,
                              actionLabel: data.healthBadge.isEmpty
                                  ? null
                                  : data.healthBadge),
                          const SizedBox(height: 12),
                          _RiskOverview(items: data.health),
                        ],
                        if (data.activity.isNotEmpty) ...[
                          const SizedBox(height: 26),
                          _SectionLabel(
                            'home.recent_activity'.tr,
                            actionLabel: 'home.view_all'.tr,
                            onAction: () =>
                                Get.toNamed(AppRoutes.notifications),
                          ),
                          const SizedBox(height: 12),
                          _ActivityList(items: data.activity),
                        ],
                        const SizedBox(height: 26),
                        const _ReferralPrompt(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header: brand mark + notification bell
// ---------------------------------------------------------------------------
class _Header extends GetView<HomeController> {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient(scheme),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.change_history_rounded,
                color: AppColors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                FlavorResolver.appName,
                style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5),
              ),
              Obx(() {
                final name = controller.userName.value.trim();
                final text = name.isEmpty
                    ? 'home.welcome_back'.tr
                    : '${'home.welcome_back'.tr}, $name';
                return Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface.withValues(alpha: 0.55)),
                );
              }),
            ],
          ),
          const Spacer(),
          _BellButton(),
        ],
      ),
    );
  }
}

class _BellButton extends GetView<HomeController> {
  const _BellButton();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.notifications),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: dark
              ? AppColors.white.withValues(alpha: 0.06)
              : AppColors.trackSoft,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: dark
                ? AppColors.white.withValues(alpha: 0.06)
                : AppColors.border,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                color: scheme.onSurface, size: 23),
            Positioned(
              right: 9,
              top: 9,
              child: Obx(() {
                if (controller.unreadCount.value == 0) {
                  return const SizedBox.shrink();
                }
                return Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.dangerBright,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: dark ? scheme.surface : AppColors.white,
                        width: 1.5),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Equity hero: immersive gradient card with live pulse + equity/balance
// ---------------------------------------------------------------------------
class _EquityHero extends GetView<HomeController> {
  const _EquityHero({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focus = data.focus;
    final equity = focus?.equity ?? _kpiValue('sum_equity', 'equity');
    final balance = focus?.balance.isNotEmpty == true
        ? focus!.balance
        : _kpiValue('sum_balance', 'balance');
    const onHero = AppColors.white;
    final onHeroMuted = AppColors.white.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(scheme),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  focus?.title.isNotEmpty == true
                      ? focus!.title
                      : 'home.total_equity'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: onHeroMuted),
                ),
              ),
              const SizedBox(width: 8),
              const _LivePill(),
            ],
          ),
          const SizedBox(height: 14),
          Text('home.equity'.tr,
              style: TextStyle(fontSize: 12.5, color: onHeroMuted)),
          const SizedBox(height: 4),
          Text(
            equity.isEmpty ? '—' : equity,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                color: onHero),
          ),
          if (focus?.note.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              focus!.note,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: onHeroMuted),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _HeroStat(
                  label: 'home.balance'.tr,
                  value: balance.isEmpty ? '—' : balance,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: AppColors.white.withValues(alpha: 0.18),
                ),
                _HeroStat(
                  label: 'home.your_accounts'.tr,
                  value: '${data.accountCount}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Falls back to a KPI value when no focused account is present. Matches on
  /// the KPI `metric` first, then a keyword in the label.
  String _kpiValue(String metric, String labelKeyword) {
    for (final k in data.kpis) {
      if (k.metric == metric) return k.value;
    }
    for (final k in data.kpis) {
      if (k.label.toLowerCase().contains(labelKeyword)) return k.value;
    }
    return '';
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 3),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white)),
        ],
      ),
    );
  }
}

/// A soft pulsing "Live" indicator that reflects the Pusher connection state.
class _LivePill extends GetView<HomeController> {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final live = controller.isLive.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PulseDot(active: live),
            const SizedBox(width: 6),
            Text(
              live ? 'LIVE' : 'OFFLINE',
              style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.white),
            ),
          ],
        ),
      );
    });
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.active});
  final bool active;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? AppColors.success : AppColors.white;
    if (!widget.active) {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6), shape: BoxShape.circle),
      );
    }
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 6),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KPI grid: all dashboard KPIs (equity / balance / accounts / trading days)
// ---------------------------------------------------------------------------
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});
  final List<DashboardKpi> kpis;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < kpis.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _KpiCard(kpi: kpis[i])),
                const SizedBox(width: 12),
                if (i + 1 < kpis.length)
                  Expanded(child: _KpiCard(kpi: kpis[i + 1]))
                else
                  const Spacer(),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});
  final DashboardKpi kpi;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final tone = kpi.isGold
        ? AppColors.amber
        : kpi.isDown
            ? AppColors.dangerBright
            : kpi.isUp
                ? AppColors.success
                : scheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.white.withValues(alpha: 0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark
              ? AppColors.white.withValues(alpha: 0.06)
              : AppColors.border,
        ),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: AppColors.heroInk.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_iconFor(kpi), size: 19, color: tone),
              ),
              const Spacer(),
              if (kpi.hint.isNotEmpty && _isDelta(kpi.hint))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    kpi.hint,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: tone),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            kpi.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: kpi.isGold ? AppColors.amber : scheme.onSurface),
          ),
          const SizedBox(height: 3),
          Text(
            kpi.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
          if (kpi.hint.isNotEmpty && !_isDelta(kpi.hint)) ...[
            const SizedBox(height: 3),
            Text(
              kpi.hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurface.withValues(alpha: 0.45)),
            ),
          ],
        ],
      ),
    );
  }

  /// A hint like "+$14.80" / "-$5.00" is a delta chip; anything else is a
  /// descriptive subtitle shown under the label.
  bool _isDelta(String hint) {
    final t = hint.trim();
    return t.startsWith('+') || t.startsWith('-') || t.startsWith('−');
  }

  IconData _iconFor(DashboardKpi kpi) {
    final hint = '${kpi.metric} ${kpi.label}'.toLowerCase();
    if (hint.contains('equity')) return Icons.trending_up_rounded;
    if (hint.contains('balance')) return Icons.account_balance_wallet_rounded;
    if (hint.contains('account')) return Icons.layers_rounded;
    if (hint.contains('day')) return Icons.calendar_today_rounded;
    if (hint.contains('profit')) return Icons.show_chart_rounded;
    if (hint.contains('status') || hint.contains('phase')) {
      return Icons.flag_rounded;
    }
    return Icons.insights_rounded;
  }
}

// ---------------------------------------------------------------------------
// Quick actions: four shortcut tiles
// ---------------------------------------------------------------------------
class _QuickAction {
  const _QuickAction(this.route, this.labelKey, this.icon);
  final String route;
  final String labelKey;
  final IconData icon;
}

const _quickActions = <_QuickAction>[
  _QuickAction(AppRoutes.challenge, 'home.qa.challenge', Icons.add_rounded),
  _QuickAction(
      AppRoutes.profileKyc, 'home.qa.kyc', Icons.verified_user_rounded),
  _QuickAction(AppRoutes.rewards, 'home.qa.reward', Icons.credit_card_rounded),
  _QuickAction(
      AppRoutes.tradingRules, 'home.qa.rules', Icons.description_rounded),
];

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _quickActions.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _QuickActionTile(action: _quickActions[i])),
        ],
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Material(
      color: dark ? AppColors.white.withValues(alpha: 0.05) : AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Get.toNamed(action.route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: dark
                  ? AppColors.white.withValues(alpha: 0.06)
                  : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: scheme.primary, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                action.labelKey.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Risk overview: account-health rows
// ---------------------------------------------------------------------------
class _RiskOverview extends StatelessWidget {
  const _RiskOverview({required this.items});
  final List<DashboardHealth> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? AppColors.white.withValues(alpha: 0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark
              ? AppColors.white.withValues(alpha: 0.06)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  color: scheme.onSurface.withValues(alpha: 0.07)),
            _RiskRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _RiskRow extends StatelessWidget {
  const _RiskRow({required this.item});
  final DashboardHealth item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = item.isBreach
        ? AppColors.dangerBright
        : item.isWatch
            ? AppColors.amber
            : AppColors.success;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.status.toUpperCase(),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: color),
                      ),
                    ),
                  ],
                ),
                if (item.line1.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.line1,
                    style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
                if (item.line2.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.line2,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.8)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent activity
// ---------------------------------------------------------------------------
class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.items});
  final List<DashboardActivity> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? AppColors.white.withValues(alpha: 0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark
              ? AppColors.white.withValues(alpha: 0.06)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  color: scheme.onSurface.withValues(alpha: 0.07)),
            _ActivityRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});
  final DashboardActivity item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.bolt_rounded, size: 20, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface),
                ),
                if (item.detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ],
            ),
          ),
          if (item.when.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              item.when,
              style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Referral prompt
// ---------------------------------------------------------------------------
class _ReferralPrompt extends GetView<HomeController> {
  const _ReferralPrompt();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final referral = _referral;
    final link = referral?.shareUrl.isNotEmpty == true
        ? referral!.shareUrl
        : (referral?.code ?? '');
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.referral),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient(scheme),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.card_giftcard_rounded,
                      color: AppColors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'home.refer_earn'.tr,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'home.refer_earn_short'.tr,
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (link.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'home.your_link'.tr,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color:
                                    AppColors.white.withValues(alpha: 0.65)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            link,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _copy,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy_rounded,
                                size: 16, color: AppColors.white),
                            const SizedBox(width: 6),
                            Text(
                              'home.copy'.tr,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copy() {
    final referral = _referral;
    final link = referral?.shareUrl.isNotEmpty == true
        ? referral!.shareUrl
        : (referral?.code ?? '');
    if (link.isEmpty) return;
    Clipboard.setData(ClipboardData(text: link));
    AppToast.success('home.copied'.tr, title: 'home.copied_title'.tr);
  }

  DashboardReferral? get _referral {
    final s = controller.state;
    return s.isSuccess
        ? (s as dynamic).data.referral as DashboardReferral?
        : null;
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.actionLabel, this.onAction});
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: scheme.onSurface),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Text(
              actionLabel!,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary),
            ),
          )
        else if (actionLabel != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warningInk),
            ),
          ),
      ],
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: const [
        CardSkeleton(lines: 2, height: 150),
        SizedBox(height: 18),
        StatGridSkeleton(tiles: 4),
        SizedBox(height: 24),
        CardSkeleton(lines: 3),
        SizedBox(height: 16),
        CardSkeleton(lines: 2),
      ],
    );
  }
}
