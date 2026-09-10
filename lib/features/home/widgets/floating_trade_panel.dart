import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'dart:math';

import '../../../shared/theme/app_colors.dart';
import '../../symbols/services/market_watch_v2_service.dart';
import '../views/pending_order_view.dart';
import 'notifications_sheet.dart';

/// A docked trading order ticket shown below the Markets chart and above the
/// bottom navigation bar. It exposes Buy / Sell, live spread, order type
/// (Market / Pending) with an optional TP/SL section, and a volume/lot stepper.
class FloatingTradePanel extends StatefulWidget {
  const FloatingTradePanel({
    super.key,
    required this.symbol,
    this.symbols = const [],
    this.onSymbolSelected,
    this.spread = 0.8,
    this.onSubmit,
  });

  /// Currently selected market symbol (drives the ticket header).
  final String symbol;

  /// Symbols the user can switch to via the header symbol picker sheet.
  final List<String> symbols;

  /// Called when the user picks a symbol from the picker bottom sheet.
  final ValueChanged<String>? onSymbolSelected;

  /// Live spread in pips shown between the Sell/Buy prices.
  final double spread;

  /// Called when the user taps Buy or Sell with the assembled ticket.
  final ValueChanged<TradeTicket>? onSubmit;

  @override
  State<FloatingTradePanel> createState() => _FloatingTradePanelState();
}

/// Immutable snapshot of what the user configured before hitting Buy/Sell.
class TradeTicket {
  const TradeTicket({
    required this.symbol,
    required this.side,
    required this.volume,
    this.takeProfit,
    this.stopLoss,
  });

  final String symbol;
  final TradeSide side;
  final double volume;

  /// Optional TP/SL prices; null when the TP/SL toggle is off or left unset.
  final double? takeProfit;
  final double? stopLoss;
}

enum TradeSide { buy, sell }

class _FloatingTradePanelState extends State<FloatingTradePanel> {
  double _volume = 0.01;
  bool _tpSlEnabled = false;
  double? _takeProfit;
  double? _stopLoss;

  /// Quick-set lot presets shown as chips above the volume field.
  static const List<double> _volumePresets = [0.01, 0.10, 0.50, 1.00];

  /// Shared height for the volume field, +/- steppers and Pending button so
  /// they line up on one row.
  static const double _controlHeight = 44;

  final _volumeCtrl = TextEditingController(text: '0.01');

  @override
  void dispose() {
    _volumeCtrl.dispose();
    super.dispose();
  }

  void _bumpVolume(double delta) {
    final next = (_volume + delta).clamp(0.01, 100.0);
    setState(() {
      _volume = double.parse(next.toStringAsFixed(2));
      _volumeCtrl.text = _volume.toStringAsFixed(2);
    });
  }

  void _onVolumeEdited(String raw) {
    final parsed = double.tryParse(raw);
    if (parsed == null) return;
    _volume = parsed.clamp(0.01, 100.0);
  }

  void _setVolume(double value) {
    final next = value.clamp(0.01, 100.0);
    setState(() {
      _volume = double.parse(next.toStringAsFixed(2));
      _volumeCtrl.text = _volume.toStringAsFixed(2);
    });
  }

  /// Live quote for the ticket's symbol from the app-wide market feed.
  MarketPrice get _quote =>
      Get.find<MarketWatchV2Service>().priceOf(widget.symbol).value;

  /// Pip size for the current symbol = 10^-digits (5-digit forex → 0.00001,
  /// XAU 2 digits → 0.01), with a flat 100.0 for crypto/indices priced high on
  /// ≤2 digits — mirrors the whitelabel iquote default-SL/TP rule.
  double get _pipSize {
    final q = _quote;
    if (q.digits <= 2 && q.ask > 5000) return 1.0;
    return pow(10, -q.digits).toDouble();
  }

  int get _priceDigits => _quote.digits.clamp(0, 8);

  void _toggleTpSl(bool enabled) {
    setState(() {
      _tpSlEnabled = enabled;
      if (enabled) {
        _seedDefaultTpSl();
      } else {
        _takeProfit = null;
        _stopLoss = null;
      }
    });
  }

  /// Seeds TP/SL a fixed 100 pips away from the current price when the user
  /// turns TP/SL on and hasn't set values yet. Uses BUY anchoring (ask): TP
  /// above, SL below. Offset = 100 * pipSize.
  void _seedDefaultTpSl() {
    final q = _quote;
    final entry = q.ask > 0 ? q.ask : q.bid;
    if (entry <= 0) return;
    final offset = 100 * _pipSize;
    _takeProfit ??= entry + offset;
    _stopLoss ??= entry - offset;
  }

  void _bumpTakeProfit(double delta) {
    setState(() {
      final base = _takeProfit ?? (_quote.ask > 0 ? _quote.ask : 0);
      final next = (base + delta).clamp(0.0, double.infinity);
      _takeProfit = next <= 0 ? null : next;
    });
  }

  void _bumpStopLoss(double delta) {
    setState(() {
      final base = _stopLoss ?? (_quote.bid > 0 ? _quote.bid : 0);
      final next = (base + delta).clamp(0.0, double.infinity);
      _stopLoss = next <= 0 ? null : next;
    });
  }

  void _submit(TradeSide side) {
    _onVolumeEdited(_volumeCtrl.text);
    widget.onSubmit?.call(
      TradeTicket(
        symbol: widget.symbol,
        side: side,
        volume: _volume,
        takeProfit: _tpSlEnabled ? _takeProfit : null,
        stopLoss: _tpSlEnabled ? _stopLoss : null,
      ),
    );
  }

  void _openPendingOrder() {
    Get.to(() => PendingOrderView(symbol: widget.symbol));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _buildPanel(scheme);
  }

  Widget _buildPanel(ColorScheme scheme) {
    return Material(
      color: scheme.surface,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(
              color: scheme.primary.withValues(alpha: 0.25),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(scheme),
            const SizedBox(height: 8),
            _volumeStepper(scheme),
            const SizedBox(height: 6),
            _volumePresetChips(scheme),
            const SizedBox(height: 8),
            _tpSlSection(scheme),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SideButton(
                    label: 'trade.sell'.tr,
                    color: AppColors.danger,
                    onTap: () => _submit(TradeSide.sell),
                  ),
                ),
                _spreadBadge(scheme),
                Expanded(
                  child: _SideButton(
                    label: 'trade.buy'.tr,
                    color: AppColors.success,
                    onTap: () => _submit(TradeSide.buy),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _openSymbolPicker,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.symbol,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.expand_more,
                      size: 18, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        InkWell(
          onTap: _openNotifications,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.notifications_none,
                size: 22, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Future<void> _openSymbolPicker() async {
    if (widget.symbols.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  'trade.select_symbol'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              for (final s in widget.symbols)
                ListTile(
                  title: Text(s),
                  trailing: s == widget.symbol
                      ? Icon(Icons.check, color: scheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(s),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null) widget.onSymbolSelected?.call(selected);
  }

  Widget _spreadBadge(ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'trade.spread'.tr,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.spread.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _volumeStepper(ColorScheme scheme) {
    return Row(
      children: [
        _stepBtn(scheme, Icons.remove, () => _bumpVolume(-0.01)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: _controlHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _volumeCtrl,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: _onVolumeEdited,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                filled: false,
                fillColor: AppColors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _stepBtn(scheme, Icons.add, () => _bumpVolume(0.01)),
        const SizedBox(width: 8),
        _PendingButton(onTap: _openPendingOrder),
      ],
    );
  }

  Widget _stepBtn(ColorScheme scheme, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: _controlHeight,
        height: _controlHeight,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: scheme.onSurface),
      ),
    );
  }

  Widget _volumePresetChips(ColorScheme scheme) {
    return Row(
      children: [
        for (var i = 0; i < _volumePresets.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _PresetChip(
              label: _volumePresets[i].toStringAsFixed(2),
              selected: (_volume - _volumePresets[i]).abs() < 0.0001,
              onTap: () => _setVolume(_volumePresets[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _tpSlSection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'trade.tp_sl'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Switch.adaptive(
              value: _tpSlEnabled,
              activeThumbColor: scheme.primary,
              onChanged: _toggleTpSl,
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _tpSlEnabled
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _priceField(
                      scheme,
                      label: 'trade.take_profit'.tr,
                      value: _takeProfit,
                      onDec: () => _bumpTakeProfit(-_pipSize),
                      onInc: () => _bumpTakeProfit(_pipSize),
                    ),
                    const SizedBox(height: 10),
                    _priceField(
                      scheme,
                      label: 'trade.stop_loss'.tr,
                      value: _stopLoss,
                      onDec: () => _bumpStopLoss(-_pipSize),
                      onInc: () => _bumpStopLoss(_pipSize),
                    ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _priceField(
    ColorScheme scheme, {
    required String label,
    required double? value,
    required VoidCallback onDec,
    required VoidCallback onInc,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: _controlHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              _stepBtn(scheme, Icons.remove, onDec),
              Expanded(
                child: Center(
                  child: Text(
                    value == null
                        ? 'trade.not_set'.tr
                        : value.toStringAsFixed(_priceDigits),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: value == null
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                    ),
                  ),
                ),
              ),
              _stepBtn(scheme, Icons.add, onInc),
            ],
          ),
        ),
      ],
    );
  }

  void _openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints.expand(height: 360),
      builder: (context) => const NotificationsSheet(),
    );
  }
}

/// Selectable lot-size preset chip shown above the volume field. Highlights in
/// the brand primary when its value matches the current volume.
class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pending-order button that sits in the volume row, matching the +/- steppers'
/// height. Icon over a tiny "Pending" caption in a tinted pill.
class _PendingButton extends StatelessWidget {
  const _PendingButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pending_actions, size: 18, color: scheme.primary),
            const SizedBox(height: 2),
            Text(
              'trade.pending'.tr,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
