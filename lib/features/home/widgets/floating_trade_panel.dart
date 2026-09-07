import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'dart:math';

import '../../../shared/theme/app_colors.dart';
import '../../symbols/services/market_watch_v2_service.dart';
import '../views/pending_order_view.dart';
import 'notifications_sheet.dart';

/// A draggable, collapsible trading order ticket that floats over the Markets
/// chart. The user can drag it anywhere on screen (it snaps within bounds) and
/// collapse it to a small pill. It exposes Buy / Sell, live spread, order type
/// (Market / Pending) with an optional price field, a volume/lot stepper, and a
/// notify-on-fill toggle.
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

class _FloatingTradePanelState extends State<FloatingTradePanel>
    with SingleTickerProviderStateMixin {
  Offset _pos = const Offset(16, 120);
  bool _collapsed = false;
  double _volume = 0.01;
  bool _tpSlEnabled = false;
  double? _takeProfit;
  double? _stopLoss;

  /// Quick-set lot presets shown as chips above the volume field.
  static const List<double> _volumePresets = [0.01, 0.10, 0.50, 1.00];

  /// Step size for the TP/SL +/- steppers (in price units).
  static const double _tpSlStep = 0.10;

  /// Shared height for the volume field, +/- steppers and Pending button so
  /// they line up on one row.
  static const double _controlHeight = 44;

  /// Collapsed pill diameter and an estimated open-panel height, used to anchor
  /// the grow/shrink origin to the corner nearest the pill.
  static const double _pillSize = 56;
  static const double _panelHeightEstimate = 300;

  final _volumeCtrl = TextEditingController(text: '0.01');

  /// Drives the open (1) <-> collapsed (0) transition with an ease-in-out feel.
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: _collapsed ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    _volumeCtrl.dispose();
    super.dispose();
  }

  void _setCollapsed(bool collapsed) {
    setState(() => _collapsed = collapsed);
    if (collapsed) {
      _anim.reverse();
    } else {
      _anim.forward();
    }
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Panel spans 65% of the device width (35% narrower than full width).
        final panelWidth = constraints.maxWidth * 0.65;

        // The pill roams the WHOLE screen; clamp its top-left to the pill size.
        final maxX =
            (constraints.maxWidth - _pillSize).clamp(0.0, double.infinity);
        final maxY =
            (constraints.maxHeight - _pillSize).clamp(0.0, double.infinity);
        final pill = Offset(
          _pos.dx.clamp(0.0, maxX),
          _pos.dy.clamp(0.0, maxY),
        );

        // Anchor the panel to the pill corner nearest the screen edge so it
        // opens/collapses FROM the pill wherever it rests (grows leftward when
        // docked right, upward when docked at the bottom, etc.).
        final onRight = pill.dx + _pillSize / 2 > constraints.maxWidth / 2;
        final onBottom = pill.dy + _pillSize / 2 > constraints.maxHeight / 2;
        final panelLeft = onRight ? pill.dx + _pillSize - panelWidth : pill.dx;
        final panelTop =
            onBottom ? pill.dy + _pillSize - _panelHeightEstimate : pill.dy;
        final origin = Alignment(onRight ? 1 : -1, onBottom ? 1 : -1);

        // When the keyboard opens (editing volume), lift the panel so its
        // bottom stays visible above the keyboard, with an 8px breathing gap.
        final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
        final keyboardTop = constraints.maxHeight - keyboardInset;
        final panelBottom = panelTop + _panelHeightEstimate;
        final overlap = panelBottom - keyboardTop + 8;
        final liftedTop = (keyboardInset > 0 && overlap > 0)
            ? (panelTop - overlap).clamp(0.0, panelTop)
            : panelTop;

        final curved = CurvedAnimation(
          parent: _anim,
          curve: Curves.easeInOutCubic,
          reverseCurve: Curves.easeInOutCubic,
        );

        return Stack(
          children: [
            // Pill layer — draggable in either state, fades/shrinks as it opens.
            Positioned(
              left: pill.dx,
              top: pill.dy,
              child: GestureDetector(
                onPanUpdate: (d) => setState(() => _pos = pill + d.delta),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1, end: 0).animate(curved),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1, end: 0.6).animate(curved),
                    child: IgnorePointer(
                      ignoring: !_collapsed,
                      child: _CollapsedPill(
                        symbol: widget.symbol,
                        onTap: () => _setCollapsed(false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Panel layer — grows out of the pill corner with ease-in-out.
            // The whole panel is draggable; it also lifts above the keyboard
            // when the volume field is being edited.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              left: panelLeft,
              top: liftedTop,
              child: FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: curved,
                  alignment: origin,
                  child: IgnorePointer(
                    ignoring: _collapsed,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanUpdate: (d) => setState(() => _pos = pill + d.delta),
                      child: _buildPanel(scheme, panelWidth, pill),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPanel(ColorScheme scheme, double panelWidth, Offset pill) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(20),
      color: AppColors.transparent,
      shadowColor: scheme.primary.withValues(alpha: isDark ? 0.45 : 0.28),
      child: Container(
        width: panelWidth,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(scheme, pill),
            const SizedBox(height: 12),
            _volumeStepper(scheme),
            const SizedBox(height: 8),
            _volumePresetChips(scheme),
            const SizedBox(height: 12),
            _tpSlSection(scheme),
            const SizedBox(height: 12),
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

  Widget _header(ColorScheme scheme, Offset pill) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(Icons.drag_indicator,
              size: 18, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: 2),
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
        const SizedBox(width: 4),
        InkWell(
          onTap: () => _setCollapsed(true),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.close,
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
          child: SizedBox(
            height: _controlHeight,
            child: Center(
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
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
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
class _CollapsedPill extends StatelessWidget {
  const _CollapsedPill({required this.symbol, required this.onTap});

  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: scheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.45),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Icon(Icons.candlestick_chart, color: scheme.onPrimary),
        ),
      ),
    );
  }
}
