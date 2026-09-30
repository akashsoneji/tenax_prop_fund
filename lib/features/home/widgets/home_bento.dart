import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../accounts/services/primary_account_service.dart';
import '../../positions/controllers/positions_controller.dart';
import '../../positions/widgets/positions_account_header.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_count_up_text.dart';
import '../../../shared/widgets/app_pill.dart';
import '../controllers/home_controller.dart';
import '../models/dashboard_models.dart';
import 'home_overview_panel.dart';

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

/// The top of the Home tab: the account card (the Positions Floating P/L header
/// when available, else the equity tile) followed by the overview panel.
class HomeBento extends StatelessWidget {
  const HomeBento({super.key, required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Account card — same Floating P/L + account pill used on Positions.
        if (Get.isRegistered<PositionsController>())
          PositionsAccountHeader(
            controller: Get.find<PositionsController>(),
          )
        else
          EquityBentoTile(data: data),
        SizedBox(height: 16.h),
        HomeOverviewPanel(data: data),
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
          // Persist the choice as the user's active/primary account in the
          // background — never blocks the UI or the switch. Only when the id
          // maps to a known MT5 account (avoids writing a wrong primary).
          if (Get.isRegistered<PrimaryAccountService>()) {
            final svc = Get.find<PrimaryAccountService>();
            final known = svc.accounts.any((a) => a.id == id);
            if (known) unawaited(svc.setPrimary(id));
          }
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
      return AppPill(
        label: (live ? 'home.status_live' : 'home.status_offline').tr,
        color: AppColors.white,
        bgAlpha: 0.14,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        leading: HomePulseDot(active: live),
        leadingGap: 6,
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
