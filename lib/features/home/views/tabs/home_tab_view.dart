import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text.dart';
import '../../../../shared/theme/app_theme.dart';

/// The Home (Dashboard) tab — a faithful build of the Figma "Dashboard" frame
/// (#11:156): a purple brand app bar, an equity hero row, a Daily Risk Headroom
/// card, a KYC pill banner, a 2×2 quick-action grid, the "Your plans" summary,
/// three plan-progress cards (Phase 1 / Funded / Breached), a horizontally
/// scrolling "Your accounts" carousel, the purple payout-journey card and a
/// "Recent trades" list. Fully theme-token driven (light/dark) and localized
/// through `.tr`. Values are static placeholders matching the design; wire to
/// `HomeController` later without touching this layout.
class HomeTabView extends StatelessWidget {
  const HomeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Column(
        children: [
          const _BrandAppBar(),
          Expanded(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                const _EquityRow(),
                const SizedBox(height: 14),
                const _RiskHeadroomCard(),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.profileKyc),
                  child: const _KycBanner()),
                const SizedBox(height: 18),
                const _QuickActions(),
                const SizedBox(height: 22),
                const _YourPlansSummary(),
                const SizedBox(height: 16),
                const _PlanProgressCard(
                  title: 'Pipze 2-Step · \$100K',
                  account: '100482',
                  status: 'home.dash.phase1',
                  statusColor: _StatusTone.brand,
                  progress: 0.54,
                  detail: '\$4,280 of \$8,000',
                  percent: '54%',
                ),
                const SizedBox(height: 12),
                const _PlanProgressCard(
                  title: 'Pipze Instant · \$20K',
                  account: '100311',
                  status: 'home.dash.funded_status',
                  statusColor: _StatusTone.success,
                  progress: 0.54,
                  detail: '\$4,280 of \$8,000',
                  percent: '54%',
                ),
                const SizedBox(height: 12),
                const _PlanProgressCard(
                  title: 'Pipze One-Step · \$50K',
                  account: '100205',
                  status: 'home.dash.breached_status',
                  statusColor: _StatusTone.danger,
                  breachDate: 'Jul 19, 2026',
                  breachBody:
                      'Daily loss limit breached — equity fell below the daily floor of \$47,500.',
                ),
                const SizedBox(height: 22),
                const _AccountsCarousel(),
                const SizedBox(height: 22),
                const _PayoutCard(),
                const SizedBox(height: 22),
                const _RecentTrades(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared: soft white card + purple shadow (Figma effect_83a7f8e3)
// ---------------------------------------------------------------------------
BoxDecoration _softCard(ColorScheme scheme, {double radius = 16}) {
  final isDark = scheme.brightness == Brightness.dark;
  return BoxDecoration(
    color: isDark ? AppColors.cardDark : AppColors.cardLight,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: isDark
          ? AppColors.white.withValues(alpha: AppColors.alphaHairline)
          : AppColors.track,
    ),
    boxShadow: isDark
        ? null
        : [
            BoxShadow(
              color: AppColors.brandPurple.withValues(alpha: 0.10),
              blurRadius: 12,
            ),
          ],
  );
}

LinearGradient _progressGradient() => const LinearGradient(
      colors: [AppColors.brandPurple, AppColors.brandMagenta],
    );

// ---------------------------------------------------------------------------
// Purple brand app bar: logo + name + bell
// ---------------------------------------------------------------------------
class _BrandAppBar extends StatelessWidget {
  const _BrandAppBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
          child: Row(
            children: [
              const Icon(Icons.close_rounded, color: AppColors.accent, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tenax',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(color: AppColors.white, fontSize: 18),
                ),
              ),
              IconButton(
                onPressed: () => Get.toNamed(AppRoutes.notifications),
                icon: const Icon(Icons.notifications_none_rounded,
                    color: AppColors.white, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Equity hero row: big equity card + Float / All-time stack
// ---------------------------------------------------------------------------
class _EquityRow extends StatelessWidget {
  const _EquityRow();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: _softCard(scheme),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('home.total_equity'.tr,
                      style: AppText.subtitle(
                          color: scheme.onSurface, fontSize: 14)),
                    const SizedBox(height: 4),
                  Text('3 ${'home.dash.accounts_word'.tr}',
                      style: AppText.label(
                          color: scheme.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('\$169,460',
                        style: AppText.base(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                            color: scheme.primary)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'home.dash.float'.tr,
                    value: '\$1,300',
                    valueColor: AppColors.danger,
                    up: false,
                  ),
                ),
                const SizedBox(height: 13),
                Expanded(
                  child: _MiniStat(
                    label: 'home.dash.all_time'.tr,
                    value: '\$540',
                    valueColor: scheme.onSurface,
                    up: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.up,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool up;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: _softCard(scheme),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                    color: scheme.onSurface.withValues(alpha: 0.72),
                    fontSize: 14)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: AppText.subtitle(
                      fontSize: 14,
                      color: valueColor)),
              const SizedBox(width: 4),
              Icon(up ? Icons.north_east_rounded : Icons.south_east_rounded,
                  size: 15, color: valueColor),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Daily Risk Headroom card
// ---------------------------------------------------------------------------
class _RiskHeadroomCard extends StatelessWidget {
  const _RiskHeadroomCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _softCard(scheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('home.dash.risk_headroom'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppText.title(color: scheme.onSurface, fontSize: 16)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_rounded, size: 15, color: muted),
                  const SizedBox(width: 4),
                  Text('14:35:08', style: AppText.label(color: muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('home.dash.available'.tr, style: AppText.label(color: muted)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('\$3,850',
                  style: AppText.base(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      color: scheme.primary)),
              const SizedBox(width: 4),
              Text('/ \$5,000',
                  style: AppText.subtitle(color: muted, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 6, color: AppColors.track),
                FractionallySizedBox(
                  widthFactor: 0.77,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(gradient: _progressGradient()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${'home.dash.used'.tr} \$1,150',
                  style: AppText.label(color: muted)),
              Flexible(
                child: Text(
                  '${'home.dash.floor_at'.tr} \$90,000 · \$14,280 ${'home.dash.away'.tr}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppText.label(color: muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KYC pill banner (purple, half-circle right edge)
// ---------------------------------------------------------------------------
class _KycBanner extends StatelessWidget {
  const _KycBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.kycGradient(scheme),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          topRight: Radius.circular(100),
          bottomRight: Radius.circular(100),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('home.dash.kyc_title'.tr,
                    style: AppText.title(color: AppColors.white, fontSize: 16)),
                const SizedBox(height: 4),
                Text('home.dash.kyc_sub'.tr,
                    style: AppText.body(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fingerprint_rounded,
                color: AppColors.white, size: 26),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions — 2×2 grid
// ---------------------------------------------------------------------------
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _ActionTile(
                    icon: Icons.candlestick_chart_rounded,
                    label: 'home.qa.trade'.tr)),
            const SizedBox(width: 16),
            Expanded(
                child: _ActionTile(
                    icon: Icons.attach_money_rounded,
                    label: 'home.qa.get_paid'.tr)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _ActionTile(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'home.qa.new_challenge'.tr)),
            const SizedBox(width: 16),
            Expanded(
                child: _ActionTile(
                    icon: Icons.menu_book_rounded, label: 'home.qa.rules'.tr)),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _softCard(scheme),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: scheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.subtitle(color: scheme.onSurface, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Your plans" summary — Plans purchased (tall) + Funded/passed + Breached
// ---------------------------------------------------------------------------
class _YourPlansSummary extends StatelessWidget {
  const _YourPlansSummary();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.72);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('home.your_plans'.tr,
            style: AppText.title(color: scheme.onSurface, fontSize: 16)),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _softCard(scheme),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('home.dash.plans_purchased'.tr,
                          style: AppText.subtitle(color: muted, fontSize: 13)),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text('03',
                            style: AppText.base(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                                color: scheme.primary)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _CountTile(
                          label: 'home.dash.funded_passed'.tr, count: '01'),
                    ),
                    const SizedBox(height: 13),
                    Expanded(
                      child: _CountTile(
                          label: 'home.dash.breached_status'.tr, count: '01'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.label, required this.count});
  final String label;
  final String count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: _softCard(scheme),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.subtitle(
                    color: scheme.onSurface.withValues(alpha: 0.72),
                    fontSize: 13)),
          ),
          const SizedBox(width: 6),
          Text(count,
              style: AppText.base(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                  color: scheme.primary)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plan progress cards
// ---------------------------------------------------------------------------
enum _StatusTone { brand, success, danger }

class _PlanProgressCard extends StatelessWidget {
  const _PlanProgressCard({
    required this.title,
    required this.account,
    required this.status,
    required this.statusColor,
    this.progress,
    this.detail,
    this.percent,
    this.breachDate,
    this.breachBody,
  });

  final String title;
  final String account;
  final String status;
  final _StatusTone statusColor;
  final double? progress;
  final String? detail;
  final String? percent;
  final String? breachDate;
  final String? breachBody;

  bool get _breached => breachBody != null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final tone = switch (statusColor) {
      _StatusTone.brand => scheme.primary,
      _StatusTone.success => AppColors.success,
      _StatusTone.danger => AppColors.danger,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _softCard(scheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(color: scheme.onSurface, fontSize: 16)),
              ),
              const SizedBox(width: 8),
              Icon(Icons.person_outline_rounded, size: 15, color: muted),
              const SizedBox(width: 4),
              Text(account, style: AppText.label(color: muted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(status.tr,
              style: AppText.base(
                  fontSize: 16, fontWeight: FontWeight.w700, color: tone)),
          const SizedBox(height: 10),
          if (_breached)
            _BreachBanner(date: breachDate ?? '', body: breachBody!)
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  Container(height: 8, color: AppColors.track),
                  FractionallySizedBox(
                    widthFactor: progress ?? 0,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(gradient: _progressGradient()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${detail ?? ''} ${'home.dash.target_achieved'.tr}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.subtitle(color: muted, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(percent ?? '',
                    style: AppText.subtitle(color: muted, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BreachBanner extends StatelessWidget {
  const _BreachBanner({required this.date, required this.body});
  final String date;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 15, color: AppColors.danger),
              const SizedBox(width: 6),
              Flexible(
                child: Text('${'home.dash.breached_on'.tr} $date',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppText.subtitle(color: AppColors.danger, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(body,
              style: AppText.body(color: AppColors.danger, fontSize: 12)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Your accounts" horizontal carousel
// ---------------------------------------------------------------------------
class _AccountsCarousel extends StatelessWidget {
  const _AccountsCarousel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('home.dash.your_accounts'.tr,
            style: AppText.title(color: scheme.onSurface, fontSize: 16)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _AccountCard(
                title: 'Pipze 2-Step · \$100K',
                sub: '100482 · Phase 1',
                balance: '\$104,280',
                change: '+\$4,280',
                changePositive: true,
                canLose: '\$3,850',
                toBreach: '\$3,850',
                floating: '-\$1,140',
                floatingPositive: false,
                breached: false,
              ),
              SizedBox(width: 16),
              _AccountCard(
                title: 'Pipze Instant · \$20K',
                sub: '100311 · Funded',
                balance: '\$20,980',
                change: '+\$980',
                changePositive: true,
                canLose: 'No Limit',
                toBreach: '\$2,180',
                floating: '-\$160',
                floatingPositive: false,
                breached: false,
              ),
              SizedBox(width: 16),
              _AccountCard(
                title: 'Pipze One-Step · \$50K',
                sub: '100205 · Breached',
                balance: '\$44,200',
                change: '-\$5,800',
                changePositive: false,
                canLose: '\$0',
                toBreach: '\$0',
                floating: '\$0',
                floatingPositive: true,
                breached: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dot(scheme.primary),
            _dot(scheme.primary.withValues(alpha: 0.25)),
            _dot(scheme.primary.withValues(alpha: 0.25)),
          ],
        ),
      ],
    );
  }

  Widget _dot(Color color) => Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.title,
    required this.sub,
    required this.balance,
    required this.change,
    required this.changePositive,
    required this.canLose,
    required this.toBreach,
    required this.floating,
    required this.floatingPositive,
    required this.breached,
  });

  final String title;
  final String sub;
  final String balance;
  final String change;
  final bool changePositive;
  final String canLose;
  final String toBreach;
  final String floating;
  final bool floatingPositive;
  final bool breached;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onCard = breached ? AppColors.white : scheme.onSurface;
    final muted = breached
        ? AppColors.white.withValues(alpha: 0.7)
        : scheme.onSurface.withValues(alpha: 0.6);
    final changeColor = breached
        ? AppColors.white
        : (changePositive ? AppColors.success : AppColors.danger);
    return Container(
      width: 320,
      padding: const EdgeInsets.all(14),
      decoration: breached
          ? BoxDecoration(
              gradient: AppTheme.kycGradient(scheme),
              borderRadius: BorderRadius.circular(16),
            )
          : _softCard(scheme),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title(color: onCard, fontSize: 15)),
                    SizedBox(height: 6,),
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(color: muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(balance,
                      style: AppText.title(color: onCard, fontSize: 15)),
                      SizedBox(height: 6,),
                  Text(change, style: AppText.label(color: changeColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: breached
                  ? AppColors.white.withValues(alpha: 0.10)
                  : AppColors.trackSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _AccountMetric(
                      align: CrossAxisAlignment.start,
                      label: 'home.dash.can_lose_today'.tr,
                      value: canLose,
                      valueColor: breached ? AppColors.white : AppColors.success,
                      muted: muted),
                ),
                Expanded(
                  child: _AccountMetric(
                      align: CrossAxisAlignment.center,
                      label: 'home.dash.to_breach'.tr,
                      value: toBreach,
                      valueColor: breached ? AppColors.white : AppColors.success,
                      muted: muted),
                ),
                Expanded(
                  child: _AccountMetric(
                      align: CrossAxisAlignment.end,
                      label: 'home.dash.floating'.tr,
                      value: floating,
                      valueColor: breached
                          ? AppColors.white
                          : (floatingPositive
                              ? AppColors.success
                              : AppColors.danger),
                      muted: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountMetric extends StatelessWidget {
  const _AccountMetric({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.muted,
    this.align = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color muted;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final textAlign = switch (align) {
      CrossAxisAlignment.end => TextAlign.end,
      CrossAxisAlignment.center => TextAlign.center,
      _ => TextAlign.start,
    };
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label,
            maxLines: 1,
            textAlign: textAlign,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(color: muted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            maxLines: 1,
            textAlign: textAlign,
            overflow: TextOverflow.ellipsis,
            style: AppText.base(
                fontSize: 13, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "Distance to your first payout" journey card (purple)
// ---------------------------------------------------------------------------
class _PayoutCard extends StatelessWidget {
  const _PayoutCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.kycGradient(scheme),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('home.dash.distance_payout'.tr,
              style: AppText.title(color: AppColors.white, fontSize: 16)),
          const SizedBox(height: 16),
          const _JourneyTrack(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _JourneyStep(
                      label: 'home.dash.phase1'.tr, value: '\$8,000')),
              Expanded(
                  child: _JourneyStep(
                      label: 'home.dash.phase2'.tr, value: '5% target')),
              Expanded(
                  child: _JourneyStep(
                      label: 'home.dash.funded_status'.tr, value: '80% share')),
              Expanded(
                  child: _JourneyStep(
                      label: 'home.dash.paid'.tr, value: '14 days')),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag_rounded,
                        size: 15, color: AppColors.white),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text('\$3,720 ${'home.dash.pass_phase1'.tr}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.subtitle(
                              color: AppColors.white, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('home.dash.payout_note'.tr,
                    style: AppText.body(
                        color: AppColors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyTrack extends StatelessWidget {
  const _JourneyTrack();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: AppColors.white.withValues(alpha: 0.25),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dot(scheme.secondary),
              _dot(AppColors.white.withValues(alpha: 0.4)),
              _dot(AppColors.white.withValues(alpha: 0.4)),
              _dot(AppColors.white.withValues(alpha: 0.4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border:
              Border.all(color: AppColors.white.withValues(alpha: 0.3), width: 2),
        ),
      );
}

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.subtitle(color: AppColors.white, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
                color: AppColors.white.withValues(alpha: 0.75), fontSize: 12)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recent trades list
// ---------------------------------------------------------------------------
class _RecentTrades extends StatelessWidget {
  const _RecentTrades();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const trades = [
      _Trade('XAUUSD · Buy', '0.80 lots · held 2h 14m', '\$3,850', true),
      _Trade('EURUSD · Sell', '1.20 lots · held 46m', '\$218', true),
      _Trade('US30 · Buy', '0.50 lots · held 3h 02m', '\$1,153', true),
      _Trade('GBPUSD · Buy', '1.00 lots · held 1h 21m', '\$168', false),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('home.recent_trades'.tr,
            style: AppText.title(color: scheme.onSurface, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: _softCard(scheme),
          child: Column(
            children: [
              for (var i = 0; i < trades.length; i++) ...[
                _TradeRow(trade: trades[i]),
                if (i != trades.length - 1)
                  Divider(
                      height: 1,
                      color: scheme.brightness == Brightness.dark
                          ? AppColors.white.withValues(alpha: 0.06)
                          : AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Trade {
  const _Trade(this.symbol, this.sub, this.amount, this.positive);
  final String symbol;
  final String sub;
  final String amount;
  final bool positive;
}

class _TradeRow extends StatelessWidget {
  const _TradeRow({required this.trade});
  final _Trade trade;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = trade.positive ? AppColors.success : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trade.symbol,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(color: scheme.onSurface, fontSize: 15)),
                const SizedBox(height: 2),
                Text(trade.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(
                        color: scheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(trade.amount,
                  style: AppText.base(
                      fontSize: 15, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(width: 4),
              Icon(
                  trade.positive
                      ? Icons.north_east_rounded
                      : Icons.south_east_rounded,
                  size: 15,
                  color: color),
            ],
          ),
        ],
      ),
    );
  }
}
