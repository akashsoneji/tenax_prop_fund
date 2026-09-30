import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/state/data_state.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_pill.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/symbol_icon.dart';
import '../controllers/home_controller.dart';
import '../models/dashboard_models.dart';

/// A section heading with an optional trailing action link or status badge.
class HomeSectionLabel extends StatelessWidget {
  const HomeSectionLabel(this.text, {super.key, this.actionLabel, this.onAction});
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.heading(color: scheme.onSurface, fontSize: 16.sp)
                .copyWith(letterSpacing: -0.3),
          ),
        ),
        if (actionLabel != null && onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: AppText.subtitle(
                        color: scheme.primary, fontSize: 12.5.sp),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 16.w, color: scheme.primary),
                ],
              ),
            ),
          )
        else if (actionLabel != null)
          AppPill(
            label: actionLabel!,
            color: AppColors.amber,
            labelColor: AppColors.warningInk,
            bgAlpha: 0.16,
            fontSize: 11.5,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          ),
      ],
    );
  }
}

/// A grouped surface that stacks rows with inset hairline dividers.
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 20),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 48.w,
                color: scheme.onSurface.withValues(alpha: 0.07),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Account health — one grouped card of rows: a status ring on the left, the
/// metric name + detail with a severity bar, and a status chip on the right.
class HomeRiskOverview extends StatelessWidget {
  const HomeRiskOverview({super.key, required this.items});
  final List<DashboardHealth> items;

  @override
  Widget build(BuildContext context) {
    return _GroupCard(
      children: [for (final item in items) _HealthRow(item: item)],
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({required this.item});
  final DashboardHealth item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // OK fills fully, Watch two-thirds, Breach one-third — a quick visual read
    // of severity even before the label.
    final (color, fill, glyph) = item.isBreach
        ? (AppColors.dangerBright, 0.34, Icons.priority_high_rounded)
        : item.isWatch
            ? (AppColors.amber, 0.66, Icons.warning_amber_rounded)
            : (AppColors.success, 1.0, Icons.check_rounded);
    final detail =
        item.line1.isNotEmpty ? item.line1 : item.status.toUpperCase();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          SizedBox(
            width: 36.w,
            height: 36.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: fill,
                    strokeWidth: 3.w,
                    backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Icon(glyph, size: 16.w, color: color),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title(
                            color: scheme.onSurface, fontSize: 13.5.sp),
                      ),
                    ),
                    if (item.status.isNotEmpty) ...[
                      SizedBox(width: 8.w),
                      AppPill(
                        label: item.status.toUpperCase(),
                        color: color,
                        fontSize: 9.5,
                        letterSpacing: 0.4,
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    color: scheme.onSurface.withValues(alpha: 0.58),
                    fontSize: 11.5.sp,
                  ).copyWith(height: 1.3),
                ),
                SizedBox(height: 7.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: fill,
                    minHeight: 4.h,
                    backgroundColor: scheme.onSurface.withValues(alpha: 0.07),
                    valueColor: AlwaysStoppedAnimation(color),
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

/// Recent activity — a vertical timeline: tone-coloured icon nodes joined by a
/// connector line, title + detail, and a relative-time badge.
class HomeActivityList extends StatelessWidget {
  const HomeActivityList({super.key, required this.items});
  final List<DashboardActivity> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 4.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 20),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _TimelineRow(item: items[i], isLast: i == items.length - 1),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.isLast});
  final DashboardActivity item;
  final bool isLast;

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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 15.w, color: tone),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.w,
                    margin: EdgeInsets.symmetric(vertical: 4.h),
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4.h, bottom: 14.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.title(
                              color: scheme.onSurface, fontSize: 13.5.sp),
                        ),
                        if (item.detail.isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Text(
                            item.detail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label(
                              color: scheme.onSurface.withValues(alpha: 0.55),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (item.when.isNotEmpty) ...[
                    SizedBox(width: 8.w),
                    Text(
                      item.when,
                      style: AppText.label(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recent trades — a grouped vertical list: symbol avatar, symbol + side chip
/// and lots, and the net P/L right-aligned in profit/loss colour.
class HomeRecentTrades extends StatelessWidget {
  const HomeRecentTrades({super.key, required this.items});
  final List<DashboardTrade> items;

  @override
  Widget build(BuildContext context) {
    return _GroupCard(
      children: [for (final trade in items) _TradeRow(trade: trade)],
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
      padding: EdgeInsets.symmetric(vertical: 11.h),
      child: Row(
        children: [
          SymbolIcon(code: trade.symbol, size: 34.w),
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
                  style:
                      AppText.title(color: scheme.onSurface, fontSize: 13.5.sp),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    AppPill(
                      label: trade.side.toUpperCase(),
                      color: sideColor,
                      fontSize: 9.5,
                      radius: 6,
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      leading: Icon(
                        trade.isBuy
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 11.w,
                        color: sideColor,
                      ),
                      leadingGap: 3,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        trade.lots,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                          fontSize: 11.5.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            trade.net,
            maxLines: 1,
            style: AppText.value(color: netColor, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}

/// The referral banner — primary-tinted card with the refer & earn headline,
/// referral count, a copyable share-link field and pending earnings. Tapping
/// anywhere opens the referral screen.
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
    final muted = scheme.onSurface.withValues(alpha: 0.6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.referral),
        borderRadius: BorderRadius.circular(22.r),
        child: Ink(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: 0.14),
                scheme.primary.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.card_giftcard_rounded,
                        size: 19.w, color: scheme.onPrimary),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'home.refer_earn'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.heading(
                              color: scheme.onSurface, fontSize: 16.sp)
                          .copyWith(letterSpacing: -0.3),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  AppPill.status(
                    label: '$referrals ${'home.referrals'.tr}',
                    color: scheme.primary,
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                'home.refer_earn_desc'.tr,
                style: AppText.body(color: muted, fontSize: 12.5.sp, height: 1.4),
              ),
              if (link.isNotEmpty) ...[
                SizedBox(height: 12.h),
                _LinkField(link: link, onCopy: () => _copy(link)),
              ],
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.hourglass_bottom_rounded, size: 15.w, color: muted),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'home.pending_earnings'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.subtitle(color: muted, fontSize: 13.sp),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    pending,
                    style: AppText.value(color: scheme.onSurface, fontSize: 16.sp)
                        .copyWith(letterSpacing: -0.4),
                  ),
                ],
              ),
            ],
          ),
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

/// The share-link field: caption + monospace link with an inline copy button.
class _LinkField extends StatelessWidget {
  const _LinkField({required this.link, required this.onCopy});
  final String link;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 6.w, 8.h),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'home.your_link'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  link,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.subtitle(
                    color: scheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 12.5.sp,
                  ).copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Material(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(10.r),
            child: InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(10.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded, size: 14.w, color: scheme.onPrimary),
                    SizedBox(width: 5.w),
                    Text(
                      'home.copy'.tr,
                      style: AppText.title(
                          color: scheme.onPrimary, fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
