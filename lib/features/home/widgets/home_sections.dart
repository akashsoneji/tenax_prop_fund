import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/state/data_state.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_pill.dart';
import '../../../shared/widgets/app_toast.dart';
import '../controllers/home_controller.dart';
import '../models/dashboard_models.dart';

/// A section heading with an optional trailing action (tappable link) or badge.
class HomeSectionLabel extends StatelessWidget {
  const HomeSectionLabel(this.text, {super.key, this.actionLabel, this.onAction});
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: scheme.onSurface),
          ),
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

/// A rounded card that stacks children with hairline dividers between them.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 20),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1.h, color: scheme.onSurface.withValues(alpha: 0.07)),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Account-health — a horizontal row of circular gauge tiles, one per metric.
/// The ring fills green (OK), amber (Watch) or red (Breach); the centre shows
/// a status glyph, and the metric name + short detail sit below.
class HomeRiskOverview extends StatelessWidget {
  const HomeRiskOverview({super.key, required this.items});
  final List<DashboardHealth> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (_, i) => _RiskGaugeTile(item: items[i]),
      ),
    );
  }
}

class _RiskGaugeTile extends StatelessWidget {
  const _RiskGaugeTile({required this.item});
  final DashboardHealth item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // OK ring fills fully, Watch two-thirds, Breach one-third — a quick visual
    // read of severity even before the label.
    final (color, fill, glyph) = item.isBreach
        ? (AppColors.dangerBright, 0.34, Icons.priority_high_rounded)
        : item.isWatch
            ? (AppColors.amber, 0.66, Icons.warning_amber_rounded)
            : (AppColors.success, 1.0, Icons.check_rounded);

    return Container(
      width: 150.w,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 58.w,
            height: 58.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 58.w,
                  height: 58.w,
                  child: CircularProgressIndicator(
                    value: fill,
                    strokeWidth: 5.w,
                    backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Icon(glyph, size: 22.w, color: color),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface),
          ),
          SizedBox(height: 3.h),
          Text(
            item.line1.isNotEmpty ? item.line1 : item.status.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11.5.sp,
                height: 1.25,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

/// Recent-activity — a compact icon-list: a tinted tone dot/icon, the event
/// title + detail, and a relative-time badge on the right.
class HomeActivityList extends StatelessWidget {
  const HomeActivityList({super.key, required this.items});
  final List<DashboardActivity> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      children: [for (final item in items) _ActivityRow(item: item)],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});
  final DashboardActivity item;

  (Color, IconData) _tone(ColorScheme scheme) {
    switch (item.tone) {
      case 'green':
        return (AppColors.success, Icons.check_circle_rounded);
      case 'red':
        return (AppColors.dangerBright, Icons.error_rounded);
      case 'amber':
      case 'yellow':
        return (AppColors.amber, Icons.warning_rounded);
      default:
        return (scheme.primary, Icons.bolt_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (tone, icon) = _tone(scheme);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 11.h),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.w, color: tone),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14.sp,
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
                        fontSize: 12.5.sp,
                        color: scheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ],
            ),
          ),
          if (item.when.isNotEmpty) ...[
            SizedBox(width: 10.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Text(
                item.when,
                style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Recent trades — a continuously auto-scrolling horizontal marquee of trade
/// chips. Pauses honour reduce-motion (renders a static scrollable row).
class HomeRecentTrades extends StatefulWidget {
  const HomeRecentTrades({super.key, required this.items});
  final List<DashboardTrade> items;

  @override
  State<HomeRecentTrades> createState() => _HomeRecentTradesState();
}

class _HomeRecentTradesState extends State<HomeRecentTrades>
    with SingleTickerProviderStateMixin {
  final _controller = ScrollController();
  Ticker? _ticker;
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
  }

  void _maybeStart() {
    if (!mounted) return;
    if (MediaQuery.of(context).disableAnimations) return;
    if (widget.items.length < 2) return;
    _ticker = createTicker((_) {
      if (!_controller.hasClients) return;
      final max = _controller.position.maxScrollExtent;
      if (max <= 0) return;
      _offset += 0.5; // px per frame ≈ smooth continuous drift
      // The list is duplicated, so wrap at the halfway point for a seamless loop.
      if (_offset >= max / 2) _offset -= max / 2;
      _controller.jumpTo(_offset);
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Duplicate the items so the marquee can loop seamlessly.
    final loop = widget.items.length < 2
        ? widget.items
        : [...widget.items, ...widget.items];
    return SizedBox(
      height: 88.h,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: loop.length,
        separatorBuilder: (_, _) => SizedBox(width: 10.w),
        itemBuilder: (_, i) => _TradeChip(trade: loop[i]),
      ),
    );
  }
}

class _TradeChip extends StatelessWidget {
  const _TradeChip({required this.trade});
  final DashboardTrade trade;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final netColor = trade.isLoss ? AppColors.dangerBright : AppColors.success;
    final sideColor = trade.isBuy ? AppColors.success : AppColors.dangerBright;
    return Container(
      width: 172.w,
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: sideColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Icon(
                  trade.isBuy
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: sideColor,
                  size: 17.w,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  trade.symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${trade.side} · ${trade.lots}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface.withValues(alpha: 0.55)),
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                trade.net,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: netColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The referral summary card — refer & earn headline, share link with copy, and
/// pending earnings. Tapping opens the referral screen.
class HomeReferralPrompt extends GetView<HomeController> {
  const HomeReferralPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final referral = _referral;
    final link = referral?.shareUrl.isNotEmpty == true
        ? referral!.shareUrl
        : (referral?.code ?? '');
    final referrals = referral?.referrals ?? 0;
    final pending = referral?.pending ?? '\$0.00';
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.referral),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: AppTheme.surfaceCard(scheme, radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'home.refer_earn'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: scheme.onSurface),
                  ),
                ),
                SizedBox(width: 10.w),
                AppPill.status(
                  label: '$referrals ${'home.referrals'.tr}',
                  color: scheme.primary,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              'home.refer_earn_desc'.tr,
              style: TextStyle(
                  fontSize: 14.sp,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
            if (link.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.28),
                    width: 1.2.w,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'home.your_link'.tr,
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        GestureDetector(
                          onTap: () => _copy(link),
                          behavior: HitTestBehavior.opaque,
                          child: Text(
                            'home.copy'.tr,
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      link,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'monospace',
                          color: scheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'home.pending_earnings'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  pending,
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: scheme.onSurface),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copy(String link) {
    if (link.isEmpty) return;
    Clipboard.setData(ClipboardData(text: link));
    AppToast.success('home.copied'.tr, title: 'home.copied_title'.tr);
  }

  DashboardReferral? get _referral {
    final s = controller.state;
    return s is DataSuccess<DashboardData> ? s.data.referral : null;
  }
}
