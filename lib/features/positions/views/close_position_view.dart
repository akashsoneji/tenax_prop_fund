import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../symbols/services/market_watch_v2_service.dart';
import '../controllers/positions_controller.dart';
import '../models/positions_models.dart';

/// Close / Modify screen for one open position — logic ported from the
/// white_label Close-Position screen so both apps behave identically:
/// - Live bid/ask + live P&L from the trade socket (auto-updating).
/// - Optional partial-close slider; P&L scales by close ratio.
/// - Optional Take-Profit / Stop-Loss editing.
/// - One dynamic primary button: MODIFY when TP/SL changed, else
///   "Close with Profit/Loss ±$X" (green/red), or the partial variant.
class ClosePositionView extends StatefulWidget {
  const ClosePositionView({super.key, required this.position});

  final TradePosition position;

  @override
  State<ClosePositionView> createState() => _ClosePositionViewState();
}

class _ClosePositionViewState extends State<ClosePositionView> {
  late final PositionsController _controller = Get.find<PositionsController>();
  late final MarketWatchV2Service _market = Get.find<MarketWatchV2Service>();

  bool _partial = false;
  late double _closeVolume;
  bool _tpEnabled = false;
  bool _slEnabled = false;

  // Live TP/SL prices being edited (0 = not set). Editable via the − / + stepper
  // OR by typing directly in the field. Socket ticks never overwrite these —
  // the value stays exactly what the user set until they submit or leave.
  double _tpPrice = 0;
  double _slPrice = 0;
  final _tpCtrl = TextEditingController();
  final _slCtrl = TextEditingController();

  // Original TP/SL captured on open, to detect a real modification.
  double _originalTp = 0;
  double _originalSl = 0;

  double get _totalVolume => widget.position.volume;
  int get _digits => widget.position.digits;
  bool get _isBuy => widget.position.isBuy;

  /// One last-digit tick for this symbol (0.01 for digits=2, 0.0001 for 4…).
  double get _tick => 1 / _pow10(_digits);

  /// Contract size per lot — metals 100, crypto 1, forex 100000.
  double get _contractSize {
    final s = widget.position.symbol.toUpperCase();
    if (s.startsWith('XAU') ||
        s.startsWith('XAG') ||
        s.startsWith('XPT') ||
        s.startsWith('XPD')) {
      return 100.0;
    }
    if (s.startsWith('BTC') ||
        s.startsWith('ETH') ||
        s.startsWith('LTC') ||
        s.startsWith('XRP') ||
        s.startsWith('EOS') ||
        s.startsWith('DOT') ||
        s.startsWith('DOG')) {
      return 1.0;
    }
    return 100000.0;
  }

  @override
  void initState() {
    super.initState();
    _closeVolume = _totalVolume;
    _originalTp = double.tryParse(widget.position.takeProfit) ?? 0;
    _originalSl = double.tryParse(widget.position.stopLoss) ?? 0;
    if (_originalTp != 0) {
      _tpEnabled = true;
      _tpPrice = _originalTp;
      _tpCtrl.text = _fmt(_tpPrice);
    }
    if (_originalSl != 0) {
      _slEnabled = true;
      _slPrice = _originalSl;
      _slCtrl.text = _fmt(_slPrice);
    }
    _market.subscribeSymbols([widget.position.symbol]);
  }

  @override
  void dispose() {
    _tpCtrl.dispose();
    _slCtrl.dispose();
    super.dispose();
  }

  double get _entryPrice =>
      double.tryParse(widget.position.entryPrice) ?? 0;

  double get _liveBid => _market.priceOf(widget.position.symbol).value.bid;
  double get _liveAsk => _market.priceOf(widget.position.symbol).value.ask;

  String _fmt(double v) => v == 0 ? '' : v.toStringAsFixed(_digits);

  /// Anchors a fresh TP/SL when the toggle is first switched on, mirroring
  /// white_label: TP = entry ±100 ticks in the PROFIT direction, SL = entry
  /// ±50 ticks in the LOSS direction (direction flips for Sell).
  void _seedTp() {
    final base = _entryPrice != 0 ? _entryPrice : (_isBuy ? _liveAsk : _liveBid);
    final dir = _isBuy ? 1 : -1;
    _tpPrice = _round(base + dir * 100 * _tick);
    _tpCtrl.text = _fmt(_tpPrice);
  }

  void _seedSl() {
    final base = _entryPrice != 0 ? _entryPrice : (_isBuy ? _liveAsk : _liveBid);
    final dir = _isBuy ? 1 : -1;
    _slPrice = _round(base - dir * 50 * _tick);
    _slCtrl.text = _fmt(_slPrice);
  }

  void _stepTp(int steps) => setState(() {
        _tpPrice = _round((_tpPrice + steps * _tick).clamp(0, double.infinity));
        _tpCtrl.text = _fmt(_tpPrice);
        _tpCtrl.selection =
            TextSelection.collapsed(offset: _tpCtrl.text.length);
      });

  void _stepSl(int steps) => setState(() {
        _slPrice = _round((_slPrice + steps * _tick).clamp(0, double.infinity));
        _slCtrl.text = _fmt(_slPrice);
        _slCtrl.selection =
            TextSelection.collapsed(offset: _slCtrl.text.length);
      });

  // Typed input — update the numeric state without rewriting the field (so the
  // caret and half-typed values like "1.16" are preserved).
  void _onTpTyped(String s) => setState(() => _tpPrice = double.tryParse(s) ?? 0);
  void _onSlTyped(String s) => setState(() => _slPrice = double.tryParse(s) ?? 0);

  /// Potential P&L if the position closed exactly at [target].
  double _potentialPnl(double target) {
    if (target <= 0 || _entryPrice <= 0) return 0;
    final delta = _isBuy ? target - _entryPrice : _entryPrice - target;
    return delta * _totalVolume * _contractSize;
  }

  /// TP must be on the profit side of entry, SL on the loss side.
  bool get _tpValid =>
      !_tpEnabled ||
      _tpPrice <= 0 ||
      (_isBuy ? _tpPrice > _entryPrice : _tpPrice < _entryPrice);
  bool get _slValid =>
      !_slEnabled ||
      _slPrice <= 0 ||
      (_isBuy ? _slPrice < _entryPrice : _slPrice > _entryPrice);
  bool get _inputsValid => _tpValid && _slValid;

  /// P&L for the FULL position from the live socket; falls back to snapshot.
  double get _fullPnl {
    final live = _controller.rawPositions.firstWhereOrNull(
        (p) => p.position.toString() == widget.position.orderId);
    return live?.profit ?? widget.position.profitLoss;
  }

  double get _closingPnl {
    if (_totalVolume <= 0) return _fullPnl;
    return _fullPnl * (_effectiveCloseVolume / _totalVolume);
  }

  double get _effectiveCloseVolume =>
      _partial ? _closeVolume.clamp(0.01, _totalVolume) : _totalVolume;

  bool get _isPartial => _effectiveCloseVolume < _totalVolume;

  bool get _tpModified =>
      _tpEnabled != (_originalTp != 0) || (_tpEnabled && _tpPrice != _originalTp);
  bool get _slModified =>
      _slEnabled != (_originalSl != 0) || (_slEnabled && _slPrice != _originalSl);

  bool get _hasTpSl => _tpEnabled || _slEnabled;
  bool get _isModify => _hasTpSl && (_tpModified || _slModified);

  double _round(double v) {
    final f = _pow10(_digits);
    return (v * f).roundToDouble() / f;
  }

  double _pow10(int n) {
    var r = 1.0;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  Future<void> _submit() async {
    if (_isModify) {
      if (!_inputsValid) return;
      final ok = await _controller.updateTPSL(
        widget.position,
        takeProfit: _tpEnabled ? _tpPrice : 0,
        stopLoss: _slEnabled ? _slPrice : 0,
      );
      if (ok) Get.back<void>();
      return;
    }
    final ok = await _controller.closePosition(
      widget.position,
      volume: _isPartial ? _effectiveCloseVolume : null,
    );
    if (ok) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      resizeToAvoidBottomInset: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'positions.close_modify_title'.tr),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _header(scheme),
                SizedBox(height: 16.h),
                _bidAsk(scheme),
                SizedBox(height: 16.h),
                _partialSection(scheme),
                SizedBox(height: 16.h),
                _tpSlSection(scheme),
                SizedBox(height: 16.h),
                _pnlCard(scheme),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomButton(scheme),
    );
  }

  Widget _header(ColorScheme scheme) {
    final p = widget.position;
    return Text(
      '${p.isBuy ? 'positions.buy'.tr : 'positions.sell'.tr} ${p.volume} ${p.symbol}',
      style: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _bidAsk(ColorScheme scheme) {
    final rx = _market.priceOf(widget.position.symbol);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 12.r),
      child: Obx(() {
        final price = rx.value;
        final digits = widget.position.digits;
        return Row(
          children: [
            Expanded(
              child: _priceCol('positions.bid'.tr,
                  price.bid.toStringAsFixed(digits), AppColors.danger),
            ),
            Container(
                width: 1, height: 32.h, color: scheme.outline.withOpacity(0.2)),
            Expanded(
              child: _priceCol('positions.ask'.tr,
                  price.ask.toStringAsFixed(digits), scheme.onSurface),
            ),
          ],
        );
      }),
    );
  }

  Widget _priceCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12.sp)),
        SizedBox(height: 4.h),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18.sp, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _partialSection(ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: AppTheme.surfaceCard(scheme, radius: 12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('positions.partial_close'.tr,
                    style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600)),
              ),
              Switch(
                value: _partial,
                onChanged: (v) => setState(() {
                  _partial = v;
                  if (!v) _closeVolume = _totalVolume;
                }),
              ),
            ],
          ),
          if (_partial) ...[
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: scheme.primary.withOpacity(0.3)),
              ),
              child: Text(
                '${'positions.selected'.tr}: ${_effectiveCloseVolume.toStringAsFixed(2)} '
                '${'trade.lot'.tr} (${(_effectiveCloseVolume / _totalVolume * 100).toStringAsFixed(1)}%)',
                style: TextStyle(
                    color: scheme.primary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Slider(
              value: _closeVolume.clamp(0.01, _totalVolume),
              min: 0.01,
              max: _totalVolume,
              divisions: (_totalVolume / 0.01).round().clamp(1, 1000),
              label: _closeVolume.toStringAsFixed(2),
              onChanged: (v) => setState(() => _closeVolume = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tpSlSection(ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: AppTheme.surfaceCard(scheme, radius: 12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _toggleRow('positions.take_profit'.tr, _tpEnabled, (v) {
            setState(() {
              _tpEnabled = v;
              if (v && _tpPrice == 0) _seedTp();
            });
          }),
          if (_tpEnabled)
            _stepper(
              scheme,
              controller: _tpCtrl,
              onStep: _stepTp,
              onTyped: _onTpTyped,
              label: 'positions.potential_profit_tp'.tr,
              pnl: _potentialPnl(_tpPrice),
              valid: _tpValid,
            ),
          SizedBox(height: 10.h),
          _toggleRow('positions.stop_loss'.tr, _slEnabled, (v) {
            setState(() {
              _slEnabled = v;
              if (v && _slPrice == 0) _seedSl();
            });
          }),
          if (_slEnabled)
            _stepper(
              scheme,
              controller: _slCtrl,
              onStep: _stepSl,
              onTyped: _onSlTyped,
              label: 'positions.potential_loss_sl'.tr,
              pnl: _potentialPnl(_slPrice),
              valid: _slValid,
            ),
        ],
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600)),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  /// Stepper row: − [ value ] + with a "Potential Profit/Loss" line below.
  Widget _stepper(
    ColorScheme scheme, {
    required TextEditingController controller,
    required void Function(int steps) onStep,
    required ValueChanged<String> onTyped,
    required String label,
    required double pnl,
    required bool valid,
  }) {
    final pnlColor = pnl >= 0 ? AppColors.success : AppColors.danger;
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onTyped,
            textAlign: TextAlign.center,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_DecimalFormatter(_digits)],
            style: TextStyle(
              color: valid ? scheme.onSurface : AppColors.danger,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8.h),
              filled: true,
              fillColor: scheme.surface,
              prefixIcon: _stepBtn(scheme, Icons.remove, () => onStep(-1)),
              suffixIcon: _stepBtn(scheme, Icons.add, () => onStep(1)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: scheme.outline.withOpacity(0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: scheme.primary, width: 1.5),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 12.sp)),
              ),
              Text(
                '${pnl >= 0 ? '+' : '-'}\$${pnl.abs().toStringAsFixed(2)}',
                style: TextStyle(
                    color: pnlColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (!valid)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('positions.invalid_level'.tr,
                    style:
                        TextStyle(color: AppColors.danger, fontSize: 11.sp)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepBtn(ColorScheme scheme, IconData icon, VoidCallback onTap) {
    return Center(
      widthFactor: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary, width: 1.5),
          ),
          child: Icon(icon, color: scheme.primary, size: 18.sp),
        ),
      ),
    );
  }

  Widget _pnlCard(ColorScheme scheme) {
    return Obx(() {
      final full = _fullPnl;
      final closing = _closingPnl;
      final positive = full >= 0;
      final color = positive ? AppColors.success : AppColors.danger;
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(positive ? Icons.trending_up : Icons.trending_down,
                    color: color, size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    '${'positions.current_pnl'.tr}: ${_money(full)}',
                    style: TextStyle(
                        color: color,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            _breakdownRow('positions.full_position'.tr, _money(full), color),
            SizedBox(height: 2.h),
            _breakdownRow(
              'positions.closing'.tr,
              '${_effectiveCloseVolume.toStringAsFixed(2)} ${'trade.lot'.tr}'
              '${_isPartial ? '  ·  ${_money(closing)}' : ''}',
              scheme.onSurface,
            ),
          ],
        ),
      );
    });
  }

  Widget _breakdownRow(String label, String value, Color valueColor) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                color: scheme.onSurfaceVariant, fontSize: 12.sp)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _bottomButton(ColorScheme scheme) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        child: Obx(() {
          final busy = _controller.busy.value;
          // MODIFY → brand gradient button. CLOSE → solid green/red by P&L sign.
          if (_isModify) {
            final enabled = !busy && _inputsValid;
            return AppGradientButton(
              label: 'positions.modify_position'.tr,
              loading: busy,
              onPressed: enabled ? _submit : null,
            );
          }
          final pnl = _closingPnl;
          final positive = pnl >= 0;
          final color = positive ? AppColors.success : AppColors.danger;
          return SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
                elevation: 0,
              ),
              child: busy
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _closeLabel(positive, pnl),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700),
                    ),
            ),
          );
        }),
      ),
    );
  }

  String _closeLabel(bool positive, double pnl) {
    final amount = _money(pnl);
    final outcome = positive
        ? '${'positions.with_profit'.tr} $amount'
        : '${'positions.with_loss'.tr} $amount';
    if (_isPartial) {
      return '${'positions.close'.tr} ${_effectiveCloseVolume.toStringAsFixed(2)} '
          '${'trade.lot'.tr} $outcome';
    }
    return '${'positions.close_position'.tr} · $outcome';
  }

  String _money(double v) =>
      '${v >= 0 ? '+' : '-'}\$${v.abs().toStringAsFixed(2)}';
}

/// Allows only a valid decimal number with at most [decimals] fraction digits
/// and a SINGLE decimal point (blocks a second "." being typed).
class _DecimalFormatter extends TextInputFormatter {
  _DecimalFormatter(this.decimals);
  final int decimals;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    // At most one dot, only digits + dot, and limited fraction length.
    final pattern = RegExp('^\\d*(\\.\\d{0,$decimals})?\$');
    if (!pattern.hasMatch(text)) return oldValue;
    return newValue;
  }
}
