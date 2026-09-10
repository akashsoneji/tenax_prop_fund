import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../controllers/calculators_controller.dart';
import '../widgets/calc_inputs.dart';
import '../widgets/calc_result_card.dart';
import '../widgets/calc_segmented_tabs.dart';

/// Calculators screen — four trading calculators behind a segmented control:
/// Position size, Pip value, Margin and Profit/loss. Each tab reactively
/// recomputes from [CalculatorsController] as the user types. Fully
/// theme-driven and composed from reusable calc widgets.
class CalculatorsView extends StatelessWidget {
  const CalculatorsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<CalculatorsController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'calculators.title'.tr),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Obx(
                    () => CalcSegmentedTabs(
                      labels: [
                        'calculators.tab_position_size'.tr,
                        'calculators.tab_pip_value'.tr,
                        'calculators.tab_margin'.tr,
                        'calculators.tab_profit_loss'.tr,
                      ],
                      selectedIndex: c.mode.value.index,
                      onSelected: (i) => c.setMode(CalcMode.values[i]),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Obx(
                    () => AnimatedSwitcher(
                      duration: AppMotion.base,
                      switchInCurve: AppMotion.enter,
                      transitionBuilder: (child, anim) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0, 0.03),
                          end: Offset.zero,
                        ).animate(anim);
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(c.mode.value),
                        child: _buildTab(c.mode.value, c),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(CalcMode mode, CalculatorsController c) {
    switch (mode) {
      case CalcMode.positionSize:
        return _PositionSizeTab(c: c);
      case CalcMode.pipValue:
        return _PipValueTab(c: c);
      case CalcMode.margin:
        return _MarginTab(c: c);
      case CalcMode.profitLoss:
        return _ProfitLossTab(c: c);
    }
  }
}

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------
String _money(double v) {
  final rounded = v.round();
  final s = rounded.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}\$$buf';
}

String _num2(double v) => v.toStringAsFixed(2);

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------
Widget _symbolField(CalculatorsController c) => Obx(
      () => CalcSymbolDropdown(
        value: c.symbol.value,
        items: c.symbols,
        onChanged: c.setSymbol,
      ),
    );

// ---------------------------------------------------------------------------
// Position size
// ---------------------------------------------------------------------------
class _PositionSizeTab extends StatelessWidget {
  const _PositionSizeTab({required this.c});
  final CalculatorsController c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _symbolField(c),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: CalcInputField(
                label: 'calculators.balance'.tr,
                value: c.balance.value,
                onChanged: (v) => c.balance.value = v,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: CalcInputField(
                label: 'calculators.risk_percent'.tr,
                value: c.riskPercent.value,
                onChanged: (v) => c.riskPercent.value = v,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        CalcInputField(
          label: 'calculators.stop_loss_pips'.tr,
          value: c.stopLossPips.value,
          onChanged: (v) => c.stopLossPips.value = v,
        ),
        SizedBox(height: 20.h),
        Obx(
          () => CalcResultCard(
            headline: '${_num2(c.positionLots)} lots',
            subtitle:
                'Risking ${_money(c.riskAmount)} · ${_money(c.riskPerPip)} per pip',
          ),
        ),
        SizedBox(height: 14.h),
        const CalcNoteBanner(
          tone: CalcNoteTone.success,
          text: 'Inside your per-trade cap and today\u2019s remaining room.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pip value
// ---------------------------------------------------------------------------
class _PipValueTab extends StatelessWidget {
  const _PipValueTab({required this.c});
  final CalculatorsController c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _symbolField(c),
        SizedBox(height: 14.h),
        CalcInputField(
          label: 'calculators.lots'.tr,
          value: c.lots.value,
          onChanged: (v) => c.lots.value = v,
        ),
        SizedBox(height: 20.h),
        Obx(
          () => CalcResultCard(
            headline: '${_money(c.pipValue)} per pip',
            subtitle:
                'On ${c.lots.value} lots of ${c.symbol.value} · contract ${c.contractSize}',
          ),
        ),
        SizedBox(height: 14.h),
        Obx(
          () => CalcNoteBanner(
            text: 'A 30 pip stop on this size risks ${_money(c.pipValueStopRisk)}.',
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Margin
// ---------------------------------------------------------------------------
class _MarginTab extends StatelessWidget {
  const _MarginTab({required this.c});
  final CalculatorsController c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _symbolField(c),
        SizedBox(height: 14.h),
        CalcInputField(
          label: 'calculators.lots'.tr,
          value: c.lots.value,
          onChanged: (v) => c.lots.value = v,
        ),
        SizedBox(height: 20.h),
        Obx(
          () => CalcResultCard(
            headline: '${_money(c.marginRequired)} margin',
            subtitle: 'Notional ${_money(c.notional)} at 1:${c.leverage}',
          ),
        ),
        SizedBox(height: 14.h),
        Obx(
          () => CalcNoteBanner(
            text:
                'Free margin left after this trade: ${_money(c.freeMarginAfter)}.',
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profit / loss
// ---------------------------------------------------------------------------
class _ProfitLossTab extends StatelessWidget {
  const _ProfitLossTab({required this.c});
  final CalculatorsController c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _symbolField(c),
        SizedBox(height: 14.h),
        Obx(
          () => CalcTwoWayToggle(
            leftLabel: 'calculators.buy'.tr,
            rightLabel: 'calculators.sell'.tr,
            leftSelected: c.side.value == TradeSide.buy,
            onChanged: (buy) =>
                c.setSide(buy ? TradeSide.buy : TradeSide.sell),
          ),
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: CalcInputField(
                label: 'calculators.entry'.tr,
                value: c.entry.value,
                onChanged: (v) => c.entry.value = v,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: CalcInputField(
                label: 'calculators.exit'.tr,
                value: c.exit.value,
                onChanged: (v) => c.exit.value = v,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        CalcInputField(
          label: 'calculators.lots'.tr,
          value: c.lots.value,
          onChanged: (v) => c.lots.value = v,
        ),
        SizedBox(height: 20.h),
        Obx(() {
          final pl = c.profitLoss;
          final sign = pl >= 0 ? '+' : '';
          return CalcResultCard(
            headline: '$sign${_money(pl)}',
            subtitle:
                '${c.pipsMoved.toStringAsFixed(1)} pips · ${_money(c.plPerPip)} per pip',
          );
        }),
      ],
    );
  }
}
