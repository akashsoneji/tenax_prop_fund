import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../models/symbol_models.dart';
import '../services/market_watch_v2_service.dart';

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
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
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
                  padding: const EdgeInsets.fromLTRB(4, 8, 2, 8),
                  child: Icon(Icons.drag_handle_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                ),
              ),
              _FlagAvatar(code: instrument.code, tint: scheme.primary),
              const SizedBox(width: 10),
              Expanded(child: _identity(scheme)),
              const SizedBox(width: 8),
              Obx(() => _pill(scheme, rx.value)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identity(ColorScheme scheme) {
    final name = instrument.name.isEmpty ? instrument.category : instrument.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatSymbol(instrument.code),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.base(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface),
        ),
        if (name.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.base(fontSize: 11, color: scheme.onSurfaceVariant),
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
    final spread =
        p.spread > 0 ? p.spread.toStringAsFixed(0) : (has ? '0' : '--');

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _side('trade.buy'.tr, buy, _buyColor,
                const BorderRadius.horizontal(left: Radius.circular(6))),
            const SizedBox(width: 1),
            _side('trade.sell'.tr, sell, _sellColor,
                const BorderRadius.horizontal(right: Radius.circular(6))),
          ],
        ),
        Positioned(
          top: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
            child: Text(spread,
                style: AppText.base(
                    fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _side(String label, String value, Color color, BorderRadius radius) {
    return Container(
      width: 70,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppText.base(
                  fontSize: 10, color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 1),
          Text(value,
              style: AppText.base(
                  fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
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

/// Circular flag/asset avatar. Resolves `assets/svg/flags/<code>.svg`
/// (lower-cased, suffix stripped); falls back to the symbol's first letter.
class _FlagAvatar extends StatelessWidget {
  const _FlagAvatar({required this.code, required this.tint});
  final String code;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    var clean = code.trim().toLowerCase();
    if (clean.contains('.')) clean = clean.substring(0, clean.indexOf('.'));
    final letter = clean.isEmpty ? '?' : clean[0].toUpperCase();

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: SvgPicture.asset(
          'assets/svg/flags/$clean.svg',
          fit: BoxFit.cover,
          placeholderBuilder: (_) => Center(
            child: Text(letter,
                style: AppText.base(
                    fontSize: 12, fontWeight: FontWeight.w700, color: tint)),
          ),
        ),
      ),
    );
  }
}
