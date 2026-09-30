import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'dart:math';


import '../../../features/home/views/pending_order_view.dart';

import '../../../features/home/widgets/pending_order_widgets.dart';
import '../../../features/symbols/services/market_watch_v2_service.dart';
import '../../theme/app_colors.dart';
import '../app_glass.dart';
import '../../theme/app_theme.dart';
import '../symbol_icon.dart';
import 'trade_ticket.dart';

export 'trade_ticket.dart';

/// The app's single order ticket: Buy / Sell with live prices, the spread
/// badge, order volume with +/- steppers and lot presets, an optional TP/SL
/// section and a shortcut to the pending-order screen.
///
/// It is presentation-only — every action is handed back through [onSubmit] /
/// [onSymbolSelected] so the hosting feature's controller owns the business
/// logic. [layout] switches between the portrait dock (under the chart) and the
/// landscape rail (beside the chart) without forking the widget.
///
/// Sizing: portrait (`docked`) uses ScreenUtil (`.w/.h/.sp/.r`) exactly as
/// before. The landscape rail does NOT — the root `ScreenUtilInit` is designed
/// for the PORTRAIT screen (375x812), and the device's own `MediaQuery`
/// genuinely reports landscape dimensions while this panel is on screen. That
/// mismatch scaled every dimension in the rail to the wrong size, which is what
/// showed up as overlapping, oversized text. So rail sizes are plain literal
/// points instead — see [_u]/[_v]/[_f]/[_rad] below.
class TradeTicketPanel extends StatefulWidget {
  const TradeTicketPanel({
    super.key,
    required this.symbol,
    this.symbols = const [],
    this.onSymbolSelected,
    this.spread = 0.8,
    this.onSubmit,
    this.layout = TradeTicketLayout.docked,
    this.header,
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
  final Future<void> Function(TradeTicket ticket)? onSubmit;

  /// Docked under the chart (portrait) or a rail beside it (landscape).
  final TradeTicketLayout layout;

  /// Replaces the built-in header row. The landscape rail supplies a richer
  /// one (instrument + live price) because it has no app bar above it.
  final Widget? header;

  @override
  State<TradeTicketPanel> createState() => _TradeTicketPanelState();
}

class _TradeTicketPanelState extends State<TradeTicketPanel> {
  double _volume = 0.01;
  bool _tpSlEnabled = false;

  double? _takeProfit;
  double? _stopLoss;
  bool _isSubmitting = false;

  /// Quick-set lot presets shown as chips above the volume field.
  static const List<double> _volumePresets = [0.01, 0.10, 0.50, 1.00];

  bool get _isRail => widget.layout == TradeTicketLayout.rail;

  /// Horizontal / general dimension: ScreenUtil `.w` for the portrait dock,
  /// a literal point value for the landscape rail (see class doc for why).
  double _u(double v) => _isRail ? v : v.w;

  /// Vertical dimension: ScreenUtil `.h` for the dock, literal for the rail.
  double _v(double v) => _isRail ? v : v.h;

  /// Font size: ScreenUtil `.sp` for the dock, literal for the rail.
  double _f(double v) => _isRail ? v : v.sp;

  /// Corner radius: ScreenUtil `.r` for the dock, literal for the rail.
  double _rad(double v) => _isRail ? v : v.r;

  /// Shared height for the volume field, +/- steppers and Pending button so
  /// they line up on one row.
  double get _controlHeight => _u(44);

  /// Compact height for the TP/SL price pills — deliberately shorter than
  /// [_controlHeight] so turning TP/SL on doesn't push the chart off-screen.
  double get _levelHeight => _v(34);

  final _volumeCtrl = TextEditingController(text: '0.01');
  final _tpCtrl = TextEditingController();
  final _slCtrl = TextEditingController();

  @override
  void didUpdateWidget(covariant TradeTicketPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Levels are absolute prices, so they are meaningless on a new instrument
    // (XAUUSD 4372.31 on EURUSD). Drop them and re-seed from the new quote.
    if (oldWidget.symbol != widget.symbol) {
      _takeProfit = null;
      _stopLoss = null;
      _tpCtrl.clear();
      _slCtrl.clear();
      if (_tpSlEnabled) _seedDefaultTpSl();
    }
  }

  @override
  void dispose() {
    _volumeCtrl.dispose();
    _tpCtrl.dispose();
    _slCtrl.dispose();
    super.dispose();
  }

  /// Mirrors a level into its text field after a stepper tap or a re-seed.
  void _syncLevelText(TextEditingController controller, double? value) {
    controller.text = value == null ? '' : value.toStringAsFixed(_priceDigits);
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
    if (_tpCtrl.text.isEmpty) _syncLevelText(_tpCtrl, _takeProfit);
    if (_slCtrl.text.isEmpty) _syncLevelText(_slCtrl, _stopLoss);
  }

  void _bumpTakeProfit(double delta) {
    setState(() {
      final base = _takeProfit ?? (_quote.ask > 0 ? _quote.ask : 0);
      final next = (base + delta).clamp(0.0, double.infinity);
      _takeProfit = next <= 0 ? null : next;
      _syncLevelText(_tpCtrl, _takeProfit);
    });
  }

  void _bumpStopLoss(double delta) {
    setState(() {
      final base = _stopLoss ?? (_quote.bid > 0 ? _quote.bid : 0);
      final next = (base + delta).clamp(0.0, double.infinity);
      _stopLoss = next <= 0 ? null : next;
      _syncLevelText(_slCtrl, _stopLoss);
    });
  }

  Future<void> _submit(TradeSide side) async {
    final onSubmit = widget.onSubmit;
    if (_isSubmitting || onSubmit == null) return;
    _onVolumeEdited(_volumeCtrl.text);
    _isSubmitting = true;
    try {
      await onSubmit(
        TradeTicket(
          symbol: widget.symbol,
          side: side,
          volume: _volume,
          takeProfit: _tpSlEnabled ? _takeProfit : null,
          stopLoss: _tpSlEnabled ? _stopLoss : null,
        ),
      );
    } finally {
      _isSubmitting = false;
    }
  }

  /// Pushed WITHOUT [ChartPreloadService.whileHandedOff]: handing off unmounts
  /// the Charts tab's webview, and remounting it on pop re-runs the loader —
  /// a visible reload every time the user came back. The tab keeps the warm
  /// instance; the pending screen's own chart (off by default) loads separately.
  void _openPendingOrder() {
    Get.to<void>(() => PendingOrderView(symbol: widget.symbol));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _buildPanel(scheme);
  }

  Widget _buildPanel(ColorScheme scheme) {
    final divider = BorderSide(color: scheme.primary.withValues(alpha: 0.25));
    return Material(
      color: scheme.surface,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: _isRail ? _u(10) : _u(12),
          vertical: _v(8),
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: _isRail ? BorderSide.none : divider,
            left: _isRail ? divider : BorderSide.none,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              widget.header ?? _header(scheme),
              SizedBox(height: _v(8)),
              _volumeStepper(scheme),
              // SizedBox(height: _v(6)),
              // _volumePresetChips(scheme),
              _tpSlSection(scheme),
              SizedBox(height: _v(8)),
              Obx(() {
                final quote = Get.find<MarketWatchV2Service>()
                    .priceOf(widget.symbol)
                    .value;
                final digits = quote.digits.clamp(0, 8);
                return Row(
                  children: [
                    Expanded(
                      child: _SideButton(
                        label: 'trade.sell'.tr,
                        price: quote.bid > 0
                            ? quote.bid.toStringAsFixed(digits)
                            : null,
                        color: AppColors.danger,
                        compact: _isRail,
                        isRail: _isRail,
                        onTap: () => _submit(TradeSide.sell),
                      ),
                    ),
                    _spreadBadge(
                      scheme,
                      quote.spread > 0
                          ? quote.spread
                          : (quote.ask > 0 && quote.bid > 0
                              ? quote.ask - quote.bid
                              : widget.spread),
                    ),
                    Expanded(
                      child: _SideButton(
                        label: 'trade.buy'.tr,
                        price: quote.ask > 0
                            ? quote.ask.toStringAsFixed(digits)
                            : null,
                        color: AppColors.success,
                        compact: _isRail,
                        isRail: _isRail,
                        onTap: () => _submit(TradeSide.buy),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
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
            borderRadius: BorderRadius.circular(_rad(10)),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: _v(4), horizontal: _u(4)),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.symbol,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: _f(15),
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  SizedBox(width: _u(2)),
                  Icon(Icons.expand_more,
                      size: _u(18), color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        _tpSlToggle(scheme),
      ],
    );
  }

  Future<void> _openSymbolPicker() async {
    if (widget.symbols.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      // Landscape leaves ~375pt of height, so there the sheet must be
      // scrollable and safe-area aware or the list is clipped by the home
      // indicator. Portrait keeps its original behaviour untouched.
      isScrollControlled: _isRail,
      useSafeArea: _isRail,
      constraints: _isRail ? const BoxConstraints(maxHeight: 260) : null,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(_u(20), _v(4), _u(20), _v(12)),
                child: Text(
                  'trade.select_symbol'.tr,
                  style: TextStyle(
                    fontSize: _f(16),
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: widget.symbols.length,
                  itemBuilder: (context, i) {
                    final s = widget.symbols[i];
                    return ListTile(
                      dense: _isRail,
                      leading: SymbolIcon(code: s),
                      title: Text(
                        s,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: s == widget.symbol
                          ? Icon(Icons.check, color: scheme.primary)
                          : null,
                      onTap: () => Navigator.of(context).pop(s),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) widget.onSymbolSelected?.call(selected);
  }

  Widget _spreadBadge(ColorScheme scheme, double spread) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _isRail ? _u(6) : _u(8)),
      padding: EdgeInsets.symmetric(horizontal: _u(10), vertical: _v(6)),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(_rad(10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'trade.spread'.tr,
            style: TextStyle(
              fontSize: _f(9),
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: _v(2)),
          Text(
            spread == spread.roundToDouble()
                ? spread.toStringAsFixed(0)
                : spread.toStringAsFixed(1),
            style: TextStyle(
              fontSize: _f(13),
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
        SizedBox(width: _u(8)),
        Expanded(
          child: Container(
            height: _controlHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(_rad(10)),
            ),
            child: TextField(
              controller: _volumeCtrl,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [DecimalPrecisionFormatter(2)],
              onChanged: _onVolumeEdited,
              style: TextStyle(
                fontSize: _f(16),
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
        SizedBox(width: _u(8)),
        _stepBtn(scheme, Icons.add, () => _bumpVolume(0.01)),
        // Pending lives in the portrait dock only: the landscape rail is a
        // focused quick-trade surface, and the pending-order screen is a
        // portrait-authored full page that has no place inside a 300pt rail.
        if (!_isRail) ...[
          SizedBox(width: _u(8)),
          _PendingButton(onTap: _openPendingOrder),
        ],
      ],
    );
  }

  Widget _stepBtn(ColorScheme scheme, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_rad(10)),
      child: Container(
        width: _controlHeight,
        height: _controlHeight,
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient(scheme),
          borderRadius: BorderRadius.circular(_rad(10)),
        ),
        child: Icon(icon, size: _u(18), color: AppColors.white),
      ),
    );
  }

  Widget _volumePresetChips(ColorScheme scheme) {
    return Row(
      children: [
        for (var i = 0; i < _volumePresets.length; i++) ...[
          if (i > 0) SizedBox(width: _u(8)),
          Expanded(
            child: _PresetChip(
              label: _volumePresets[i].toStringAsFixed(2),
              selected: (_volume - _volumePresets[i]).abs() < 0.0001,
              isRail: _isRail,
              onTap: () => _setVolume(_volumePresets[i]),
            ),
          ),
        ],
      ],
    );
  }

  /// Compact "TP/SL" caption + switch. Lives at the end of the built-in header;
  /// a custom [TradeTicketPanel.header] (landscape rail) has no slot for
  /// it, so there it falls back to its own row inside [_tpSlSection].
  Widget _tpSlToggle(ColorScheme scheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'trade.tp_sl'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: _f(13),
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        Transform.scale(
          scale: 0.85,
          child: Switch.adaptive(
            value: _tpSlEnabled,
            activeThumbColor: scheme.primary,
            onChanged: _toggleTpSl,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _tpSlSection(ColorScheme scheme) {
    final hasOwnToggleRow = widget.header != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasOwnToggleRow) ...[
          SizedBox(height: _v(8)),
          Align(alignment: Alignment.centerRight, child: _tpSlToggle(scheme)),
        ],
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _tpSlEnabled
              ? Padding(
                  padding: EdgeInsets.only(top: _v(8)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _levelField(
                          scheme,
                          label: 'trade.take_profit'.tr,
                          controller: _tpCtrl,
                          onDec: () => _bumpTakeProfit(-_pipSize),
                          onInc: () => _bumpTakeProfit(_pipSize),
                          onChanged: (raw) =>
                              _takeProfit = double.tryParse(raw.trim()),
                        ),
                      ),
                      SizedBox(width: _u(8)),
                      Expanded(
                        child: _levelField(
                          scheme,
                          label: 'trade.stop_loss'.tr,
                          controller: _slCtrl,
                          onDec: () => _bumpStopLoss(-_pipSize),
                          onInc: () => _bumpStopLoss(_pipSize),
                          onChanged: (raw) =>
                              _stopLoss = double.tryParse(raw.trim()),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  /// Compact TP/SL cell: tiny caption above a short pill holding −, the typed
  /// price and +. Two of these fit one row so the chart stays visible.
  Widget _levelField(
    ColorScheme scheme, {
    required String label,
    required TextEditingController controller,
    required VoidCallback onDec,
    required VoidCallback onInc,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: _f(10),
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: _v(4)),
        Container(
          height: _levelHeight,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(_rad(10)),
          ),
          child: Row(
            children: [
              _levelStepBtn(scheme, Icons.remove, onDec),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  // Precision follows the live quote, so a 2-digit symbol
                  // accepts 4338.70 and a 5-digit one accepts 1.15505.
                  inputFormatters: [DecimalPrecisionFormatter(_priceDigits)],
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  onChanged: onChanged,
                  style: TextStyle(
                    fontSize: _f(13),
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'trade.not_set'.tr,
                    hintStyle: TextStyle(
                      fontSize: _f(12),
                      color: scheme.onSurfaceVariant,
                    ),
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: _u(2)),
                  ),
                ),
              ),
              _levelStepBtn(scheme, Icons.add, onInc),
            ],
          ),
        ),
      ],
    );
  }

  Widget _levelStepBtn(ColorScheme scheme, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_rad(10)),
      child: Container(
        width: _levelHeight,
        height: _levelHeight,
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient(scheme),
          borderRadius: BorderRadius.circular(_rad(10)),
        ),
        child: Icon(icon, size: _u(15), color: AppColors.white),
      ),
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
    this.isRail = false,
  });

  final String label;
  final bool selected;
  final bool isRail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isRail ? 10 : 10.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: isRail ? 36 : 36.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(isRail ? 10 : 10.r),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isRail ? 13 : 13.sp,
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
    this.price,
    this.compact = false,
    this.isRail = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  /// Live side price shown under the label — bid for Sell, ask for Buy.
  final String? price;

  /// Shorter button for the landscape rail, where vertical room is scarce.
  final bool compact;

  final bool isRail;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(isRail ? 14 : 14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isRail ? 14 : 14.r),
        child: SizedBox(
          height: isRail ? 46 : (compact ? 46.h : 52.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: isRail ? 15 : 15.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              if (price != null)
                Text(
                  price!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: isRail ? 12 : 12.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
            ],
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
    final isDark = scheme.brightness == Brightness.dark;
    // The flat primary tint vanishes against the dark chart, so dark mode gets
    // a frosted surface with light content instead.
    final contentColor = isDark ? scheme.onSurface : scheme.primary;
    final radius = BorderRadius.circular(10.r);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.pending_actions, size: 18.w, color: contentColor),
        SizedBox(height: 2.h),
        Text(
          'trade.pending'.tr,
          style: TextStyle(
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            color: contentColor,
          ),
        ),
      ],
    );
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: isDark
          ? AppGlass(
              height: 44.h,
              borderRadius: radius,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Center(child: content),
            )
          : Container(
              height: 44.h,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: radius,
              ),
              child: content,
            ),
    );
  }
}
