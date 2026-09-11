import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../chart/services/chart_preload_service.dart';
import '../../chart/widgets/chart_in_app_webview.dart';
import '../../positions/controllers/positions_controller.dart';
import '../../positions/models/positions_models.dart';
import '../../symbols/services/market_watch_v2_service.dart';
import '../widgets/pending_order_widgets.dart';

/// Full-screen pending order editor, opened from the floating trade ticket's
/// pending-order action. Lots / trigger price / TP / SL are assembled here and
/// submitted through [PositionsController.placePendingOrder].
class PendingOrderView extends StatefulWidget {
  const PendingOrderView({super.key, required this.symbol});

  final String symbol;

  @override
  State<PendingOrderView> createState() => _PendingOrderViewState();
}

class _PendingOrderViewState extends State<PendingOrderView> {
  static const List<double> _lotPresets = [0.01, 0.10, 0.50, 1.00];
  static const double _minLot = 0.01;
  static const double _maxLot = 100.0;

  final _volumeCtrl = TextEditingController(text: '0.01');
  final _priceCtrl = TextEditingController();
  final _limitPriceCtrl = TextEditingController();
  final _takeProfitCtrl = TextEditingController();
  final _stopLossCtrl = TextEditingController();

  /// Every pending type the trade host accepts, in the web terminal's order.
  static const List<OrderType> _pendingTypes = [
    OrderType.buyLimit,
    OrderType.sellLimit,
    OrderType.buyStop,
    OrderType.sellStop,
    OrderType.buyStopLimit,
    OrderType.sellStopLimit,
  ];

  OrderType _orderType = OrderType.buyLimit;
  bool _showChart = false;
  bool _triggerPriceEnabled = true;
  bool _riskExpanded = true;
  bool _takeProfitEnabled = false;
  bool _stopLossEnabled = false;
  bool _priceEditedManually = false;
  bool _isPlacing = false;

  double _volume = 0.01;

  @override
  void initState() {
    super.initState();
    _syncPriceWithQuote();
  }

  @override
  void dispose() {
    _volumeCtrl.dispose();
    _priceCtrl.dispose();
    _limitPriceCtrl.dispose();
    _takeProfitCtrl.dispose();
    _stopLossCtrl.dispose();
    super.dispose();
  }

  MarketPrice get _quote =>
      Get.find<MarketWatchV2Service>().priceOf(widget.symbol).value;

  int get _digits => _quote.digits.clamp(0, 8);

  /// Trigger-price step = one point at the symbol's precision, with a flat 1.0
  /// for high-priced instruments quoted on <= 2 digits (crypto / indices).
  double get _priceStep {
    final q = _quote;
    if (q.digits <= 2 && q.ask > 5000) return 1.0;
    return pow(10, -_digits).toDouble();
  }

  bool get _isBuy => _orderType.isBuy;

  /// Stop-limit types carry a second level: the limit price the order rests at
  /// once the stop price is hit.
  bool get _isStopLimit =>
      _orderType == OrderType.buyStopLimit ||
      _orderType == OrderType.sellStopLimit;

  /// Buy orders anchor on the ask, sell orders on the bid.
  double get _anchorPrice {
    final q = _quote;
    final anchor = _isBuy ? q.ask : q.bid;
    return anchor > 0 ? anchor : (q.ask > 0 ? q.ask : q.bid);
  }

  double get _triggerPrice =>
      double.tryParse(_priceCtrl.text.trim()) ?? _anchorPrice;

  double? get _limitPrice => double.tryParse(_limitPriceCtrl.text.trim());

  /// Primary price field label: stop types trigger on a stop price, limit types
  /// on a limit price.
  String get _priceLabel {
    switch (_orderType) {
      case OrderType.buyStop:
      case OrderType.sellStop:
      case OrderType.buyStopLimit:
      case OrderType.sellStopLimit:
        return 'pending_order.stop_price'.tr;
      default:
        return 'pending_order.price'.tr;
    }
  }

  String _labelOf(OrderType type) {
    switch (type) {
      case OrderType.sellLimit:
        return 'pending_order.sell_limit'.tr;
      case OrderType.buyStop:
        return 'pending_order.buy_stop'.tr;
      case OrderType.sellStop:
        return 'pending_order.sell_stop'.tr;
      case OrderType.buyStopLimit:
        return 'pending_order.buy_stop_limit'.tr;
      case OrderType.sellStopLimit:
        return 'pending_order.sell_stop_limit'.tr;
      default:
        return 'pending_order.buy_limit'.tr;
    }
  }

  String get _orderTypeLabel => _labelOf(_orderType);

  void _syncPriceWithQuote() {
    if (_priceEditedManually) return;
    final anchor = _anchorPrice;
    if (anchor <= 0) return;
    _priceCtrl.text = anchor.toStringAsFixed(_digits);
    if (_isStopLimit) _limitPriceCtrl.text = _priceCtrl.text;
  }

  void _setOrderType(OrderType type) {
    if (_orderType == type) return;
    setState(() {
      _orderType = type;
      _priceEditedManually = false;
      _syncPriceWithQuote();
      _seedRiskLevels();
    });
  }


  void _setVolume(double value) {
    final clamped = value.clamp(_minLot, _maxLot);
    setState(() {
      _volume = double.parse(clamped.toStringAsFixed(2));
      _volumeCtrl.text = _volume.toStringAsFixed(2);
    });
  }

  void _bumpPrice(double direction) {
    final next = (_triggerPrice + direction * _priceStep).clamp(
      0.0,
      double.infinity,
    );
    setState(() {
      _priceEditedManually = true;
      _priceCtrl.text = next.toStringAsFixed(_digits);
      _seedRiskLevels();
    });
  }

  /// Seeds TP above / SL below the trigger price (mirrored for sell) whenever a
  /// level is switched on or the entry moves and the user hasn't typed a value.
  void _seedRiskLevels() {
    final entry = _triggerPrice;
    if (entry <= 0) return;
    final offset = entry * 0.0115;
    if (_takeProfitEnabled && _takeProfitCtrl.text.trim().isEmpty) {
      final tp = _isBuy ? entry + offset : entry - offset;
      _takeProfitCtrl.text = tp.toStringAsFixed(_digits);
    }
    if (_stopLossEnabled && _stopLossCtrl.text.trim().isEmpty) {
      final sl = _isBuy ? entry - offset : entry + offset;
      _stopLossCtrl.text = sl.toStringAsFixed(_digits);
    }
  }

  void _bumpLevel(TextEditingController controller, double direction) {
    final current = double.tryParse(controller.text.trim()) ?? _triggerPrice;
    final next = (current + direction * _priceStep).clamp(0.0, double.infinity);
    setState(() => controller.text = next.toStringAsFixed(_digits));
  }

  double? _levelOf(TextEditingController controller, {required bool enabled}) {
    if (!enabled) return null;
    final value = double.tryParse(controller.text.trim());
    return (value == null || value <= 0) ? null : value;
  }

  Future<void> _placeOrder() async {
    if (_isPlacing) return;
    final price = _triggerPrice;
    if (price <= 0 || _volume <= 0) return;

    setState(() => _isPlacing = true);
    try {
      final placed = await Get.find<PositionsController>().placePendingOrder(
        symbol: widget.symbol,
        volume: _volume,
        orderType: _orderType,
        price: price,
        limitPrice: _isStopLimit ? _limitPrice : null,
        takeProfit: _levelOf(_takeProfitCtrl, enabled: _takeProfitEnabled),
        stopLoss: _levelOf(_stopLossCtrl, enabled: _stopLossEnabled),
      );
      if (placed && mounted) Get.back();
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        titleSpacing: 0,
        toolbarHeight: 72.h,
        title: _title(context),
        actions: [
          Obx(() {
            final quote = Get.find<MarketWatchV2Service>()
                .priceOf(widget.symbol)
                .value;
            _syncPriceWithQuote();
            return PendingOrderQuotePill(
              bid: quote.bid,
              ask: quote.ask,
              digits: quote.digits.clamp(0, 8),
              bidLabel: 'positions.bid'.tr,
              askLabel: 'positions.ask'.tr,
            );
          }),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _chartSection(scheme),
              SizedBox(height: 10.h),
              _ticketPanel(scheme),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        child: _placeButton(),
      ),
    );
  }

  Widget _title(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'pending_order.title'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 2.h),
        Text(
          '$_orderTypeLabel ${widget.symbol}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelMedium?.copyWith(fontSize: 12.sp),
        ),
      ],
    );
  }

  Widget _chartSection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40.h,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'pending_order.chart'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PendingOrderSwitch(
                value: _showChart,
                onChanged: (value) => setState(() => _showChart = value),
              ),
            ],
          ),
        ),
        if (_showChart)
          Container(
            // Screen-relative so the candles get real room on every device
            // instead of a cramped fixed box.
            height: (MediaQuery.sizeOf(context).height * 0.34).clamp(
              220.0,
              360.0,
            ),
            margin: EdgeInsets.only(top: 6.h),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12.r),
            ),
            clipBehavior: Clip.antiAlias,
            // Reuse the warm preloaded URL so the shared webview is never
            // reloaded; the symbol is applied via JS injection.
            child: ChartInAppWebView(
              url: Get.find<ChartPreloadService>().preloadUrl,
              symbol: widget.symbol,
            ),
          ),
      ],
    );
  }

  Widget _ticketPanel(ColorScheme scheme) {
    final divider = Divider(
      height: 18.h,
      thickness: 1,
      color: scheme.outlineVariant.withValues(alpha: AppColors.alphaFaint),
    );

    return Card(
      elevation: 3,
      shadowColor: scheme.primary.withValues(alpha: AppColors.alphaHairline),
      color: scheme.surface,
      surfaceTintColor: AppColors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: AppColors.alphaFaint),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        child: LayoutBuilder(
        builder: (context, constraints) {
          final presetsWidth = (constraints.maxWidth * 0.58).clamp(
            150.0,
            constraints.maxWidth - 110.w,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PendingOrderTypeSelector(
                label: 'pending_order.order_type'.tr,
                selectedLabel: _orderTypeLabel,
                options: _pendingTypes.map(_labelOf).toList(),
                selectedIndex: _pendingTypes.indexOf(_orderType),
                onSelected: (i) => _setOrderType(_pendingTypes[i]),
              ),
              divider,
              PendingOrderSectionHeader(
                icon: Icons.tune_rounded,
                title: 'pending_order.quantity'.tr,
                trailing: PendingOrderLotPresets(
                  presets: _lotPresets,
                  volume: _volume,
                  maxWidth: presetsWidth,
                  onSelected: _setVolume,
                ),
              ),
              SizedBox(height: 8.h),
              _volumeField(),
              divider,
              PendingOrderSectionHeader(
                icon: Icons.show_chart_rounded,
                title: 'pending_order.trigger_price'.tr,
                trailing: PendingOrderSwitch(
                  value: _triggerPriceEnabled,
                  onChanged: (value) =>
                      setState(() => _triggerPriceEnabled = value),
                ),
              ),
              if (_triggerPriceEnabled) ...[
                SizedBox(height: 8.h),
                _priceField(),
                if (_isStopLimit) ...[
                  SizedBox(height: 8.h),
                  _limitPriceField(),
                ],
              ],
              divider,
              PendingOrderSectionHeader(
                icon: Icons.shield_outlined,
                title: 'pending_order.risk_management'.tr,
                trailing: IconButton(
                  onPressed: () =>
                      setState(() => _riskExpanded = !_riskExpanded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _riskExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 22.w,
                    color: scheme.primary,
                  ),
                ),
              ),
              if (_riskExpanded) ...[
                SizedBox(height: 8.h),
                _riskSection(scheme),
              ],
            ],
          );
          },
        ),
      ),
    );
  }

  Widget _volumeField() {
    return PendingOrderStepperField(
      controller: _volumeCtrl,
      label: 'pending_order.lots'.tr,
      inputFormatters: const [DecimalPrecisionFormatter(2)],
      onMinus: () => _setVolume(_volume - 0.01),
      onPlus: () => _setVolume(_volume + 0.01),
      onChanged: (value) {
        final parsed = double.tryParse(value.trim());
        if (parsed == null || parsed <= 0) return;
        _volume = parsed.clamp(_minLot, _maxLot);
      },
      onEditingComplete: () {
        _setVolume(double.tryParse(_volumeCtrl.text.trim()) ?? _minLot);
        FocusScope.of(context).unfocus();
      },
    );
  }

  Widget _priceField() {
    return PendingOrderStepperField(
      controller: _priceCtrl,
      label: _priceLabel,
      inputFormatters: [DecimalPrecisionFormatter(_digits)],
      onMinus: () => _bumpPrice(-1),
      onPlus: () => _bumpPrice(1),
      onChanged: (_) {
        _priceEditedManually = true;
        setState(_seedRiskLevels);
      },
    );
  }

  Widget _limitPriceField() {
    return PendingOrderStepperField(
      controller: _limitPriceCtrl,
      label: 'pending_order.limit_price'.tr,
      inputFormatters: [DecimalPrecisionFormatter(_digits)],
      onMinus: () => _bumpLevel(_limitPriceCtrl, -1),
      onPlus: () => _bumpLevel(_limitPriceCtrl, 1),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _riskSection(ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _riskRow(
            label: 'pending_order.take_profit'.tr,
            accent: AppColors.success,
            enabled: _takeProfitEnabled,
            controller: _takeProfitCtrl,
            onToggled: (value) => setState(() {
              _takeProfitEnabled = value;
              if (value) {
                _seedRiskLevels();
              } else {
                _takeProfitCtrl.clear();
              }
            }),
          ),
          SizedBox(height: 6.h),
          _riskRow(
            label: 'pending_order.stop_loss'.tr,
            accent: AppColors.danger,
            enabled: _stopLossEnabled,
            controller: _stopLossCtrl,
            onToggled: (value) => setState(() {
              _stopLossEnabled = value;
              if (value) {
                _seedRiskLevels();
              } else {
                _stopLossCtrl.clear();
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _riskRow({
    required String label,
    required bool enabled,
    required TextEditingController controller,
    required ValueChanged<bool> onToggled,
    required Color accent,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: enabled
            ? accent.withValues(alpha: AppColors.alphaHairline)
            : scheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: enabled
              ? accent.withValues(alpha: AppColors.alphaFaint)
              : scheme.outlineVariant.withValues(alpha: AppColors.alphaFaint),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: enabled ? accent : scheme.outlineVariant,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PendingOrderSwitch(value: enabled, onChanged: onToggled),
            ],
          ),
          if (enabled) ...[
            SizedBox(height: 8.h),
            PendingOrderStepperField(
              controller: controller,
              label: 'pending_order.price'.tr,
              inputFormatters: [DecimalPrecisionFormatter(_digits)],
              onMinus: () => _bumpLevel(controller, -1),
              onPlus: () => _bumpLevel(controller, 1),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
    );
  }

  Widget _placeButton() {
    final canPlace = !_isPlacing && _volume > 0 && _triggerPrice > 0;
    return AppGradientButton(
      label: _isPlacing ? 'pending_order.placing'.tr : 'pending_order.place'.tr,
      loading: _isPlacing,
      height: 52.h,
      onPressed: canPlace ? _placeOrder : null,
    );
  }
}
