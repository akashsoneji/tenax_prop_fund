import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../app/flavor/flavor.dart';
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
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 28.h),
                      children: [
                        _EquityHero(data: data),
                        if (data.kpis.isNotEmpty) ...[
                          SizedBox(height: 18.h),
                          _KpiGrid(kpis: data.kpis),
                        ],
                        SizedBox(height: 24.h),
                        _SectionLabel('home.quick_actions'.tr,
                            actionLabel: 'home.recommended'.tr),
                        SizedBox(height: 14.h),
                        const _QuickActions(),
                        if (data.health.isNotEmpty) ...[
                          SizedBox(height: 26.h),
                          _SectionLabel('home.account_health'.tr,
                              actionLabel: data.healthBadge.isEmpty
                                  ? null
                                  : data.healthBadge),
                          SizedBox(height: 12.h),
                          _RiskOverview(items: data.health),
                        ],
                        if (data.activity.isNotEmpty) ...[
                          SizedBox(height: 26.h),
                          _SectionLabel(
                            'home.recent_activity'.tr,
                            actionLabel: 'home.view_all'.tr,
                            onAction: () =>
                                Get.toNamed(AppRoutes.notifications),
                          ),
                          SizedBox(height: 12.h),
                          _ActivityList(items: data.activity),
                        ],
                        if (data.trades.isNotEmpty) ...[
                          SizedBox(height: 26.h),
                          _SectionLabel('home.recent_trades'.tr),
                          SizedBox(height: 12.h),
                          _RecentTrades(items: data.trades),
                        ],
                        SizedBox(height: 26.h),
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
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 12.w, 10.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient(scheme),
              borderRadius: BorderRadius.circular(13.r),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.35),
                  blurRadius: 14.r,
                  offset: Offset(0, 6.h),
                ),
              ],
            ),
            child: Icon(Icons.change_history_rounded,
                color: AppColors.white, size: 22.w),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                FlavorResolver.appName,
                style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 19.sp,
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
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface.withValues(alpha: 0.55)),
                );
              }),
            ],
          ),
          const Spacer(),
          if (FlavorResolver.flavor == Flavor.tenax) ...[
            _SettingsButton(),
            SizedBox(width: 10.w),
          ],
          _BellButton(),
        ],
      ),
    );
  }
}

/// Opens the "More" directory. Shown only on the tenax flavor, whose bottom nav
/// replaces the More tab with an Accounts tab.
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.more),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42.w,
        height: 42.h,
        decoration: BoxDecoration(
          color: dark
              ? AppColors.white.withValues(alpha: 0.06)
              : AppColors.trackSoft,
          borderRadius: BorderRadius.circular(13.r),
          border: Border.all(
            color: dark
                ? AppColors.white.withValues(alpha: 0.06)
                : AppColors.border,
          ),
        ),
        child: Icon(Icons.settings_outlined, color: scheme.onSurface, size: 23.w),
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
        width: 42.w,
        height: 42.h,
        decoration: BoxDecoration(
          color: dark
              ? AppColors.white.withValues(alpha: 0.06)
              : AppColors.trackSoft,
          borderRadius: BorderRadius.circular(13.r),
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
                color: scheme.onSurface, size: 23.w),
            Positioned(
              right: 9.w,
              top: 9.h,
              child: Obx(() {
                if (controller.unreadCount.value == 0) {
                  return const SizedBox.shrink();
                }
                return Container(
                  width: 9.w,
                  height: 9.h,
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
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(scheme),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.35),
            blurRadius: 24.r,
            offset: Offset(0, 12.h),
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
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: onHeroMuted),
                ),
              ),
              SizedBox(width: 8.w),
              const _LivePill(),
            ],
          ),
          SizedBox(height: 14.h),
          Text('home.equity'.tr,
              style: TextStyle(fontSize: 12.5.sp, color: onHeroMuted)),
          SizedBox(height: 4.h),
          Text(
            equity.isEmpty ? '—' : equity,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 38.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                color: onHero),
          ),
          if (focus?.note.isNotEmpty == true) ...[
            SizedBox(height: 6.h),
            Text(
              focus!.note,
              style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: onHeroMuted),
            ),
          ],
          SizedBox(height: 18.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              children: [
                _HeroStat(
                  label: 'home.balance'.tr,
                  value: balance.isEmpty ? '—' : balance,
                ),
                Container(
                  width: 1.w,
                  height: 30.h,
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
                  fontSize: 11.5.sp,
                  color: AppColors.white.withValues(alpha: 0.7))),
          SizedBox(height: 3.h),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 16.sp,
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
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PulseDot(active: live),
            SizedBox(width: 6.w),
            Text(
              live ? 'LIVE' : 'OFFLINE',
              style: TextStyle(
                  fontSize: 10.5.sp,
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
        width: 7.w,
        height: 7.h,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6), shape: BoxShape.circle),
      );
    }
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
      child: Container(
        width: 7.w,
        height: 7.h,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 6.r),
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
          if (i > 0) SizedBox(height: 12.h),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _KpiCard(kpi: kpis[i])),
                SizedBox(width: 12.w),
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: dark ? AppColors.white.withValues(alpha: 0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
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
                  blurRadius: 16.r,
                  offset: Offset(0, 6.h),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(_iconFor(kpi), size: 19.w, color: tone),
              ),
              const Spacer(),
              if (kpi.hint.isNotEmpty && _isDelta(kpi.hint))
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    kpi.hint,
                    style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        color: tone),
                  ),
                ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            kpi.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 19.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: kpi.isGold ? AppColors.amber : scheme.onSurface),
          ),
          SizedBox(height: 3.h),
          Text(
            kpi.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
          if (kpi.hint.isNotEmpty && !_isDelta(kpi.hint)) ...[
            SizedBox(height: 3.h),
            Text(
              kpi.hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.sp,
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
          if (i > 0) SizedBox(width: 12.w),
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
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: () => Get.toNamed(action.route),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: dark
                  ? AppColors.white.withValues(alpha: 0.06)
                  : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 46.w,
                height: 46.h,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(action.icon, color: scheme.primary, size: 22.w),
              ),
              SizedBox(height: 10.h),
              Text(
                action.labelKey.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5.sp,
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: dark ? AppColors.white.withValues(alpha: 0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
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
                  height: 1.h,
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
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8.w,
            height: 8.h,
            margin: EdgeInsets.only(top: 6.h),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 12.w),
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
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 9.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        item.status.toUpperCase(),
                        style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: color),
                      ),
                    ),
                  ],
                ),
                if (item.line1.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    item.line1,
                    style: TextStyle(
                        fontSize: 13.sp,
                        color: scheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
                if (item.line2.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    item.line2,
                    style: TextStyle(
                        fontSize: 12.5.sp,
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: dark ? AppColors.white.withValues(alpha: 0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
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
                  height: 1.h,
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
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.bolt_rounded, size: 20.w, color: scheme.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface),
                ),
                if (item.detail.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    item.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13.sp,
                        color: scheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ],
            ),
          ),
          if (item.when.isNotEmpty) ...[
            SizedBox(width: 8.w),
            Text(
              item.when,
              style: TextStyle(
                  fontSize: 12.5.sp,
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
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient(scheme),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.3),
              blurRadius: 20.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(Icons.card_giftcard_rounded,
                      color: AppColors.white, size: 24.w),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'home.refer_earn'.tr,
                        style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'home.refer_earn_short'.tr,
                        style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (link.isNotEmpty) ...[
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.fromLTRB(14.w, 10.h, 8.w, 10.h),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14.r),
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
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color:
                                    AppColors.white.withValues(alpha: 0.65)),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            link,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: _copy,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 9.h),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy_rounded,
                                size: 16.w, color: AppColors.white),
                            SizedBox(width: 6.w),
                            Text(
                              'home.copy'.tr,
                              style: TextStyle(
                                  fontSize: 13.sp,
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
// Recent trades: compact rows of the trader's latest closed trades
// ---------------------------------------------------------------------------
class _RecentTrades extends StatelessWidget {
  const _RecentTrades({required this.items});
  final List<DashboardTrade> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.white.withValues(alpha: 0.04) : AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
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
                height: 1.h,
                thickness: 1,
                indent: 16.w,
                endIndent: 16.w,
                color: dark
                    ? AppColors.white.withValues(alpha: 0.05)
                    : AppColors.border,
              ),
            _TradeRow(trade: items[i]),
          ],
        ],
      ),
    );
  }
}

class _TradeRow extends StatelessWidget {
  const _TradeRow({required this.trade});
  final DashboardTrade trade;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final netColor = trade.isLoss ? AppColors.dangerBright : AppColors.success;
    final sideColor = trade.isBuy ? AppColors.success : AppColors.dangerBright;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.h,
            decoration: BoxDecoration(
              color: sideColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Icon(
              trade.isBuy
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: sideColor,
              size: 20.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trade.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${trade.side} · ${trade.lots} · ${trade.held}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            trade.net,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w800,
                color: netColor),
          ),
        ],
      ),
    );
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
              fontSize: 17.sp,
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
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary),
            ),
          )
        else if (actionLabel != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Text(
              actionLabel!,
              style: TextStyle(
                  fontSize: 12.sp,
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
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      children: [
        CardSkeleton(lines: 2, height: 150.h),
        SizedBox(height: 18.h),
        const StatGridSkeleton(tiles: 4),
        SizedBox(height: 24.h),
        const CardSkeleton(lines: 3),
        SizedBox(height: 16.h),
        const CardSkeleton(lines: 2),
      ],
    );
  }
}
