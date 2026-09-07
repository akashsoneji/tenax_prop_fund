import 'package:get/get.dart';

/// The four calculator modes shown in the top segmented control.
enum CalcMode { positionSize, pipValue, margin, profitLoss }

extension CalcModeLabel on CalcMode {
  String get label {
    switch (this) {
      case CalcMode.positionSize:
        return 'Position size';
      case CalcMode.pipValue:
        return 'Pip value';
      case CalcMode.margin:
        return 'Margin';
      case CalcMode.profitLoss:
        return 'Profit/loss';
    }
  }
}

/// Buy/Sell side for the profit/loss calculator.
enum TradeSide { buy, sell }

/// Owns all calculator inputs and derived results. Every input is an [Rx] so
/// the result card recomputes reactively as the user types — no explicit
/// "Calculate" button. Computations are pure and defensive against empty /
/// invalid input (parse failures fall back to 0), so the UI never throws.
class CalculatorsController extends GetxController {
  final mode = CalcMode.positionSize.obs;

  // Shared
  final symbol = 'XAUUSD'.obs;
  final symbols = const <String>['XAUUSD', 'EURUSD', 'GBPUSD', 'USDJPY', 'BTCUSD'];

  // Position size
  final balance = '100000'.obs;
  final riskPercent = '1'.obs;
  final stopLossPips = '30'.obs;

  // Pip value / margin
  final lots = '0.1'.obs;

  // Profit / loss
  final side = TradeSide.buy.obs;
  final entry = '2441.83'.obs;
  final exit = '2441.83'.obs;

  /// Per-lot pip value in USD. XAUUSD moves $10/pip per lot; FX majors ~$10;
  /// kept as a simple lookup for demo purposes.
  double get _pipValuePerLot => symbol.value == 'USDJPY' ? 9.1 : 10.0;

  /// Contract size shown in the pip-value helper text.
  int get contractSize => symbol.value == 'XAUUSD' ? 100 : 100000;

  double _num(RxString s) => double.tryParse(s.value.trim()) ?? 0;

  void setMode(CalcMode m) {
    if (mode.value == m) return;
    mode.value = m;
  }

  void setSymbol(String s) => symbol.value = s;
  void setSide(TradeSide s) => side.value = s;

  // --- Position size -------------------------------------------------------
  double get riskAmount => _num(balance) * _num(riskPercent) / 100;

  double get pipValueForOneLot => _pipValuePerLot;

  double get positionLots {
    final pips = _num(stopLossPips);
    if (pips <= 0) return 0;
    return riskAmount / (pips * _pipValuePerLot);
  }

  double get riskPerPip => positionLots * _pipValuePerLot;

  // --- Pip value -----------------------------------------------------------
  double get pipValue => _num(lots) * _pipValuePerLot;

  double get pipValueStopRisk => pipValue * 30;

  // --- Margin --------------------------------------------------------------
  static const int _leverage = 20;
  double get _price => _num(entry) > 0 ? _num(entry) : 2439.5;

  double get notional => _num(lots) * contractSize * _price;

  double get marginRequired => notional / _leverage;

  int get leverage => _leverage;

  double get freeMarginAfter => _num(balance) - marginRequired;

  // --- Profit / loss -------------------------------------------------------
  double get pipsMoved {
    final diff = _num(exit) - _num(entry);
    final signed = side.value == TradeSide.buy ? diff : -diff;
    // XAUUSD: 1 pip = 0.1 of price. FX majors: 0.0001.
    final pipSize = symbol.value == 'XAUUSD' ? 0.1 : 0.0001;
    return signed / pipSize;
  }

  double get plPerPip => _num(lots) * _pipValuePerLot;

  double get profitLoss => pipsMoved * plPerPip;
}
