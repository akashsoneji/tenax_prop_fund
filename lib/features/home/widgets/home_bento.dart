import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_count_up_text.dart';
import '../../../shared/widgets/app_pill.dart';
import '../controllers/home_controller.dart';
import '../models/dashboard_models.dart';

/// Formats a minor-currency amount (e.g. cents) as a grouped major string with
/// a leading currency symbol.
String formatMinorMoney(int minor, String currency) {
  final major = (minor / 100).toStringAsFixed(2);
  final parts = major.split('.');
  final intPart = parts[0];
  final negative = intPart.startsWith('-');
  final digits = negative ? intPart.substring(1) : intPart;
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  final symbol = currency == 'USD' ? '\$' : '';
  return '${negative ? '-' : ''}$symbol$buf.${parts[1]}';
}

/// The bento dashboard: an asymmetric grid of tiles of different sizes. A large
/// gradient equity tile spans the full width, then balance / accounts sit as a
/// paired row, followed by KPI tiles and a live-account grid. Every value binds
/// to the controller snapshot that the Pusher feed patches in real time.
class HomeBento extends StatelessWidget {
  const HomeBento({super.key, required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final focus = data.focus;
    final currency = focus?.currency ?? 'USD';
    final gap = 12.w;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Big gradient equity tile (full width).
        EquityBentoTile(data: data),
        SizedBox(height: gap),
        // Balance + Your accounts — paired row.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BentoTile(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'home.balance'.tr,
                  value: (focus?.balance.isNotEmpty ?? false)
                      ? focus!.balance
                      : formatMinorMoney(focus?.balanceMinor ?? 0, currency),
                  tone: AppColors.success,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _BentoTile(
                  icon: Icons.layers_rounded,
                  label: 'home.your_accounts'.tr,
                  value: '${data.accountCount}',
                  tone: null,
                ),
              ),
            ],
          ),
        ),
        if (data.kpis.isNotEmpty) ...[
          SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < data.kpis.length && i < 2; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  Expanded(child: _KpiBentoTile(kpi: data.kpis[i])),
                ],
                if (data.kpis.length == 1) ...[
                  SizedBox(width: gap),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The hero equity tile — a full-width gradient block with the focused account
/// switcher, a live pill, and an animated equity figure.
class EquityBentoTile extends GetView<HomeController> {
  const EquityBentoTile({super.key, required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focus = data.focus;
    final currency = focus?.currency ?? 'USD';
    final equityMinor = focus?.equityMinor ?? 0;
    final equityText = focus?.equity ?? '';
    final onMuted = AppColors.white.withValues(alpha: 0.72);

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(scheme),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.4),
            blurRadius: 28.r,
            spreadRadius: -6.r,
            offset: Offset(0, 14.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _Switcher(data: data, color: onMuted)),
              SizedBox(width: 8.w),
              _LivePill(),
            ],
          ),
          SizedBox(height: 18.h),
          Text('home.equity'.tr,
              style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w500,
                  color: onMuted)),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: equityMinor > 0
                ? AppCountUpText(
                    value: equityMinor.toDouble(),
                    formatter: (v) => formatMinorMoney(v.round(), currency),
                    style: _equityStyle,
                  )
                : Text(equityText.isEmpty ? '—' : equityText,
                    maxLines: 1, style: _equityStyle),
          ),
          if (focus?.note.isNotEmpty ?? false) ...[
            SizedBox(height: 8.h),
            Text(
              focus!.note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13.sp, fontWeight: FontWeight.w600, color: onMuted),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle get _equityStyle => TextStyle(
        fontSize: 36.sp,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.4,
        height: 1.0,
        color: AppColors.white,
        shadows: [
          Shadow(
              color: AppColors.white.withValues(alpha: 0.3), blurRadius: 20.r),
        ],
      );
}

/// A generic bento metric tile on the surface: tinted icon chip, value, label.
class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = tone ?? scheme.primary;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, size: 20.w, color: accent),
          ),
          SizedBox(height: 14.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 19.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: scheme.onSurface),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

/// A KPI tile styled for the bento grid, with a delta pill.
class _KpiBentoTile extends StatelessWidget {
  const _KpiBentoTile({required this.kpi});
  final DashboardKpi kpi;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = kpi.isGold
        ? AppColors.amber
        : kpi.isDown
            ? AppColors.dangerBright
            : kpi.isUp
                ? AppColors.success
                : scheme.primary;
    final isDelta = kpi.hint.trim().isNotEmpty &&
        (kpi.hint.trim().startsWith('+') ||
            kpi.hint.trim().startsWith('-') ||
            kpi.hint.trim().startsWith('−'));

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(_iconFor(kpi), size: 20.w, color: tone),
              ),
              const Spacer(),
              if (isDelta) AppPill.status(label: kpi.hint, color: tone),
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
                letterSpacing: -0.6,
                color: kpi.isGold ? AppColors.amber : scheme.onSurface),
          ),
          SizedBox(height: 2.h),
          Text(
            kpi.hint.isNotEmpty && !isDelta
                ? '${kpi.label} · ${kpi.hint}'
                : kpi.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(DashboardKpi kpi) {
    final hint = '${kpi.metric} ${kpi.label}'.toLowerCase();
    if (hint.contains('equity')) return Icons.trending_up_rounded;
    if (hint.contains('balance')) return Icons.account_balance_wallet_rounded;
    if (hint.contains('account')) return Icons.layers_rounded;
    if (hint.contains('day')) return Icons.calendar_today_rounded;
    if (hint.contains('profit')) return Icons.show_chart_rounded;
    return Icons.insights_rounded;
  }
}

/// The focused-account title, tappable to open the account picker.
class _Switcher extends StatelessWidget {
  const _Switcher({required this.data, required this.color});
  final DashboardData data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final focus = data.focus;
    final title = (focus?.title.isNotEmpty ?? false)
        ? focus!.title
        : 'home.total_equity'.tr;
    final canSwitch = data.liveAccounts.length > 1;
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13.sp, fontWeight: FontWeight.w600, color: color),
          ),
        ),
        if (canSwitch) ...[
          SizedBox(width: 4.w),
          Icon(Icons.keyboard_arrow_down_rounded, size: 18.w, color: color),
        ],
      ],
    );
    if (!canSwitch) return label;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _open(context),
      child: label,
    );
  }

  void _open(BuildContext context) {
    final controller = Get.find<HomeController>();
    final currentId = data.focus?.accountId;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        accounts: data.liveAccounts,
        selectedId: currentId,
        onSelected: (id) {
          controller.selectAccount(id);
          Get.back<void>();
        },
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
  });

  final List<DashboardAccount> accounts;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.all(12.w),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(22.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
                child: Text('home.switch_account'.tr,
                    style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final a = accounts[index];
                    final selected = a.id == selectedId;
                    return ListTile(
                      onTap: () => onSelected(a.id),
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected ? scheme.primary : scheme.outline,
                      ),
                      title: Text('${'home.account_hash'.tr}${a.id}',
                          style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface)),
                      trailing: Text(a.currency,
                          style: TextStyle(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color:
                                  scheme.onSurface.withValues(alpha: 0.6))),
                    );
                  },
                ),
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live-connection pill for the equity tile.
class _LivePill extends GetView<HomeController> {
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
            HomePulseDot(active: live),
            SizedBox(width: 6.w),
            Text(live ? 'LIVE' : 'OFFLINE',
                style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.white)),
          ],
        ),
      );
    });
  }
}

/// A pulsing status dot; animates while [active], honouring reduce-motion.
class HomePulseDot extends StatefulWidget {
  const HomePulseDot({super.key, required this.active, this.color});
  final bool active;
  final Color? color;

  @override
  State<HomePulseDot> createState() => _HomePulseDotState();
}

class _HomePulseDotState extends State<HomePulseDot>
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
  void didUpdateWidget(covariant HomePulseDot old) {
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
    final color =
        widget.color ?? (widget.active ? AppColors.success : AppColors.white);
    if (!widget.active || MediaQuery.of(context).disableAnimations) {
      return Container(
        width: 7.w,
        height: 7.w,
        decoration: BoxDecoration(
            color: color.withValues(alpha: widget.active ? 1 : 0.6),
            shape: BoxShape.circle),
      );
    }
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
      child: Container(
        width: 7.w,
        height: 7.w,
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

/// The live-account rail — horizontally scrolling bento cards, each with a live
/// pulse and an animated equity figure plus P/L vs balance.
class LiveAccountBentoGrid extends StatelessWidget {
  const LiveAccountBentoGrid({super.key, required this.accounts});
  final List<DashboardAccount> accounts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: accounts.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (_, i) => SizedBox(
          width: 190.w,
          child: _AccountBentoCard(account: accounts[i]),
        ),
      ),
    );
  }
}

class _AccountBentoCard extends StatelessWidget {
  const _AccountBentoCard({required this.account});
  final DashboardAccount account;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pnlMinor = account.equityMinor - account.balanceMinor;
    final isProfit = pnlMinor >= 0;
    final pnlColor = isProfit ? AppColors.success : AppColors.danger;
    final sign = isProfit ? '+' : '−';

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 13.h, 14.w, 13.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${'home.account_hash'.tr}${account.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.6))),
              ),
              HomePulseDot(active: true),
            ],
          ),
          SizedBox(height: 8.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AppCountUpText(
              value: account.equityMinor.toDouble(),
              formatter: (v) => formatMinorMoney(v.round(), account.currency),
              style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: scheme.onSurface),
            ),
          ),
          SizedBox(height: 8.h),
          AppPill.status(
            label: '$sign${formatMinorMoney(pnlMinor.abs(), account.currency)}',
            color: pnlColor,
            showDot: true,
          ),
        ],
      ),
    );
  }
}
