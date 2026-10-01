import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/symbol_icon.dart';
import '../models/symbol_models.dart';
import '../services/market_watch_v2_service.dart';
import '../../../shared/theme/app_spacing.dart';

/// iQuote-style market row: a drag handle, a circular flag avatar, the slashed
/// symbol (`XAUUSD` → `XAU/USD`) with a descriptive name below, and a joined
/// Buy|Sell pill with a live spread badge in the middle. Ported from the
/// white_label iQuote market screen; Buy=green, Sell=red, spread badge = dark
/// surface. Live bid/ask/spread come from [MarketWatchV2Service] via a granular
/// `Obx` (only this row repaints on tick).
class FavoriteSymbolTile extends StatelessWidget {
  const FavoriteSymbolTile({
    super.key,
    required this.instrument,
    required this.index,
    this.onTap,
  });

  final Instrument instrument;
  final int index;
  final VoidCallback? onTap;

  static const _buyColor = Color(0xFF33B970);
  static const _sellColor = Color(0xFFE65366);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rx = Get.find<MarketWatchV2Service>().priceOf(instrument.code);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(0, 8.h, 4.w, 8.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: scheme.onSurface.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 8.h, 6.w, 8.h),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    size: 20.w,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              SymbolIcon(code: instrument.code),
              10.horizontalSpace,
              Expanded(child: _identity(scheme)),
              Gap.hSm,
              Obx(() => _pill(scheme, rx.value)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identity(ColorScheme scheme) {
    final name = instrument.name.isEmpty
        ? instrument.category
        : instrument.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatSymbol(instrument.code),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.base(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        if (name.isNotEmpty) ...[
          Gap.vXxs,
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.base(
              fontSize: 11.sp,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  /// Joined Buy(ask) | Sell(bid) pill with a centered spread badge.
  Widget _pill(ColorScheme scheme, MarketPrice p) {
    final digits = p.digits.clamp(0, 5);
    final has = p.bid > 0 || p.ask > 0;
    final buy = has && p.ask > 0 ? p.ask.toStringAsFixed(digits) : '--';
    final sell = has && p.bid > 0 ? p.bid.toStringAsFixed(digits) : '--';
    final spread = p.spread > 0
        ? p.spread.toStringAsFixed(0)
        : (has ? '0' : '--');

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _side(
              'trade.buy'.tr,
              buy,
              _buyColor,
              BorderRadius.horizontal(left: Radius.circular(6.r)),
            ),
            1.horizontalSpace,
            _side(
              'trade.sell'.tr,
              sell,
              _sellColor,
              BorderRadius.horizontal(right: Radius.circular(6.r)),
            ),
          ],
        ),
        Positioned(
          top: 3.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
            child: Text(
              spread,
              style: AppText.base(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _side(String label, String value, Color color, BorderRadius radius) {
    return Container(
      width: 74.w,
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppText.base(
              fontSize: 10.sp,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          1.verticalSpace,
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: AppText.base(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `XAUUSD` → `XAU/USD`; strips a broker suffix like `.c`. 7-char *USDT pairs
  /// split before USDT; otherwise a 6-char code splits 3/3.
  static String _formatSymbol(String raw) {
    var s = raw.trim().toUpperCase();
    if (s.contains('.')) s = s.substring(0, s.indexOf('.'));
    if (s.length == 7 && s.endsWith('USDT')) {
      return '${s.substring(0, 3)}/USDT';
    }
    if (s.length == 6) return '${s.substring(0, 3)}/${s.substring(3)}';
    return s;
  }
}
