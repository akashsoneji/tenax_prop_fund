import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/symbol_icon.dart';
import '../models/symbol_models.dart';
import '../services/market_watch_v2_service.dart';
import '../../../shared/theme/app_spacing.dart';

/// Market row: a drag handle, a circular flag avatar, the slashed symbol
/// (`XAUUSD` → `XAU/USD`) with its name + spread chip, and MT-style Bid | Ask
/// prices (pip digits enlarged, pipette as superscript). Live quotes come from
/// [MarketWatchV2Service] via a granular `Obx` (only this row repaints on tick).
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rx = Get.find<MarketWatchV2Service>().priceOf(instrument.code);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(0, 10.h, 8.w, 10.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: scheme.onSurface.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          child: Obx(() {
            final p = rx.value;
            final digits = p.digits.clamp(0, 5);
            return Row(
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
                Expanded(child: _identity(scheme, p)),
                Gap.hSm,
                _QuotePrice(
                  extremeLabel: 'symbols.low_short'.tr,
                  price: p.bid,
                  extreme: p.dayLow,
                  digits: digits,
                  trend: p.bidTrend,
                ),
                8.horizontalSpace,
                _QuotePrice(
                  extremeLabel: 'symbols.high_short'.tr,
                  price: p.ask,
                  extreme: p.dayHigh,
                  digits: digits,
                  trend: p.askTrend,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _identity(ColorScheme scheme, MarketPrice p) {
    final name = instrument.name.isEmpty
        ? instrument.category
        : instrument.name;
    final hasQuote = p.bid > 0 || p.ask > 0;
    final spread = p.spread > 0
        ? p.spread.toStringAsFixed(0)
        : (hasQuote ? '0' : '--');
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
        Gap.vXxs,
        Row(
          children: [
            // if (name.isNotEmpty) ...[
            //   Flexible(
            //     child: Text(
            //       name,
            //       maxLines: 1,
            //       overflow: TextOverflow.ellipsis,
            //       style: AppText.base(
            //         fontSize: 11.sp,
            //         color: scheme.onSurfaceVariant,
            //       ),
            //     ),
            //   ),
            //   6.horizontalSpace,
            // ],
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                '${'trade.spread'.tr} $spread',
                maxLines: 1,
                style: AppText.base(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
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

/// Right-aligned MT-style quote: the price with its two pip digits enlarged and
/// (for 3/5-digit symbols) the pipette as a superscript, then the day low/high
/// line underneath. Coloured by the last tick: green when the price went up,
/// red when it went down, neutral before the first change.
class _QuotePrice extends StatelessWidget {
  const _QuotePrice({
    required this.extremeLabel,
    required this.price,
    required this.extreme,
    required this.digits,
    required this.trend,
  });

  final String extremeLabel;
  final double price;
  final double? extreme;
  final int digits;
  final int trend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (trend) {
      > 0 => AppColors.success,
      < 0 => AppColors.danger,
      _ => scheme.onSurface,
    };
    final extremeValue = extreme;
    return SizedBox(
      width: 88.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text.rich(_priceSpan(color), maxLines: 1),
          ),
          if (extremeValue != null && extremeValue > 0) ...[
            2.verticalSpace,
            Text(
              '$extremeLabel ${extremeValue.toStringAsFixed(digits)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.base(
                fontSize: 9.sp,
                color: scheme.onSurfaceVariant,
                height: 1.0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  TextSpan _priceSpan(Color color) {
    final base = AppText.base(
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.1,
    );
    if (price <= 0) return TextSpan(text: '--', style: base);

    final text = price.toStringAsFixed(digits);
    final pipetteLen = (digits == 3 || digits == 5) ? 1 : 0;
    const pipLen = 2;
    if (text.length <= pipLen + pipetteLen) {
      return TextSpan(text: text, style: base);
    }

    final pipEnd = text.length - pipetteLen;
    final pipStart = pipEnd - pipLen;
    return TextSpan(
      style: base,
      children: [
        TextSpan(text: text.substring(0, pipStart)),
        TextSpan(
          text: text.substring(pipStart, pipEnd),
          style: base.copyWith(fontSize: 20.sp, fontWeight: FontWeight.w700),
        ),
        if (pipetteLen > 0)
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Transform.translate(
              offset: Offset(0, -4.h),
              child: Text(
                text.substring(pipEnd),
                style: base.copyWith(fontSize: 10.sp),
              ),
            ),
          ),
      ],
    );
  }
}
