import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../../../core/state/data_state.dart';
import '../models/calculator_models.dart';
import '../repositories/calculators_repository.dart';

enum TradeSide { buy, sell }

class CalculatorsController extends BaseController<CalculatorsData> {
  CalculatorsController(this._repository);

  final CalculatorsRepository _repository;
  final selectedTab = 0.obs;
  final fieldValues = <String, RxString>{}.obs;
  final side = TradeSide.buy.obs;

  CalculatorsData? get calculators => state.valueOrNull;
  CalculatorDefinition? get selectedDefinition {
    final data = calculators;
    if (data == null || data.tabs.isEmpty) return null;
    final tab = data.tabs[selectedTab.value.clamp(0, data.tabs.length - 1)];
    return data.definitions[tab.value];
  }

  @override
  Future<ApiResponse<CalculatorsData>> fetch() => _repository.getCalculators();

  @override
  void onInit() {
    everAll([stateRx], (_) {
      if (state is DataSuccess<CalculatorsData>) _selectTab(0);
    });
    super.onInit();
  }

  void selectTab(int index) {
    final data = calculators;
    if (data == null || index < 0 || index >= data.tabs.length) return;
    _selectTab(index);
  }

  void _selectTab(int index) {
    selectedTab.value = index;
    fieldValues.clear();
    for (final field in selectedDefinition?.fields ?? const <CalculatorField>[]) {
      fieldValues[field.key] = _rx(field.defaultValue);
    }
  }

  RxString _rx(String value) => RxString(value);

  void setField(String key, String value) {
    fieldValues[key] ??= _rx(value);
    fieldValues[key]!.value = value;
  }

  String field(String key) => fieldValues[key]?.value ?? '';

  void setSide(TradeSide value) => side.value = value;

  double number(String key) => double.tryParse(field(key).trim()) ?? 0;

  double get result {
    switch (selectedDefinition?.key) {
      case 'pl':
        final difference = number('exit') - number('entry');
        return (side.value == TradeSide.sell ? -difference : difference) * number('lots');
      case 'lot':
        final denominator = number('sl') * number('pip');
        return denominator <= 0 ? 0 : (number('account') * number('risk') / 100) / denominator;
      case 'swap':
        return number('lots') * number('rate') * number('nights');
      case 'margin':
        final leverage = number('leverage');
        return leverage <= 0 ? 0 : number('contract') * number('lots') * number('price') / leverage;
      default:
        return 0;
    }
  }

  String formatResult() {
    final format = selectedDefinition?.format ?? '0.00';
    final decimals = format.contains('.') ? format.split('.').last.length : 0;
    return result.toStringAsFixed(decimals.clamp(0, 8));
  }
}
