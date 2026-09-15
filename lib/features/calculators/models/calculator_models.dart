import 'package:flutter/foundation.dart';

class CalculatorTab {
  const CalculatorTab({required this.value, required this.label});
  final String value;
  final String label;

  factory CalculatorTab.fromJson(Map<String, dynamic> json) => CalculatorTab(
        value: _string(json['value']),
        label: _string(json['label']),
      );
}

class CalculatorField {
  const CalculatorField({
    required this.key,
    required this.label,
    required this.type,
    required this.options,
    required this.defaultValue,
  });
  final String key;
  final String label;
  final String type;
  final List<String> options;
  final String defaultValue;

  bool get isSelect => type == 'select' || options.isNotEmpty;

  factory CalculatorField.fromJson(Map<String, dynamic> json) => CalculatorField(
        key: _string(json['key']),
        label: _string(json['label']),
        type: _string(json['type'], fallback: 'number'),
        options: _list(json['options']),
        defaultValue: _valueString(json['default']),
      );
}

class CalculatorDefinition {
  const CalculatorDefinition({
    required this.key,
    required this.label,
    required this.note,
    required this.format,
    required this.fields,
  });
  final String key;
  final String label;
  final String note;
  final String format;
  final List<CalculatorField> fields;

  factory CalculatorDefinition.fromJson(String key, Map<String, dynamic> json) =>
      CalculatorDefinition(
        key: key,
        label: _string(json['label'], fallback: key),
        note: _string(json['note']),
        format: _string(json['fmt'], fallback: '0.00'),
        fields: _mapList(json['fields'])
            .map(CalculatorField.fromJson)
            .where((field) => field.key.isNotEmpty)
            .toList(growable: false),
      );
}

class CalculatorsData {
  const CalculatorsData({
    required this.tabs,
    required this.definitions,
    required this.disclaimer,
    required this.instrumentContracts,
  });
  final List<CalculatorTab> tabs;
  final Map<String, CalculatorDefinition> definitions;
  final String disclaimer;
  final Map<String, double> instrumentContracts;

  factory CalculatorsData.fromJson(Map<String, dynamic> json) {
    final calculators = json['calculators'] is Map
        ? Map<String, dynamic>.from(json['calculators'] as Map)
        : json;
    final rawDefs = calculators['defs'];
    return CalculatorsData(
      tabs: _mapList(calculators['tabs'])
          .map(CalculatorTab.fromJson)
          .where((tab) => tab.value.isNotEmpty)
          .toList(growable: false),
      definitions: rawDefs is Map
          ? rawDefs.map((key, value) => MapEntry(
                key.toString(),
                CalculatorDefinition.fromJson(
                  key.toString(),
                  value is Map ? Map<String, dynamic>.from(value) : const {},
                ),
              ))
          : const {},
      disclaimer: _string(calculators['disclaimer']),
      instrumentContracts: _contracts(calculators['instrumentContracts']),
    );
  }
}

List<Map<String, dynamic>> _mapList(dynamic value) => value is List
    ? value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
    : const [];

List<String> _list(dynamic value) => value is List
    ? value.map(_valueString).where((item) => item.isNotEmpty).toList()
    : const [];

Map<String, double> _contracts(dynamic value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), _number(item)));
  }
  if (value is List) {
    return value.whereType<Map>().fold<Map<String, double>>({}, (result, item) {
      final map = Map<String, dynamic>.from(item);
      final key = _string(map['symbol'], fallback: _string(map['key']));
      if (key.isNotEmpty) result[key] = _number(map['contract']);
      return result;
    });
  }
  return const {};
}

double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
String _string(dynamic value, {String fallback = ''}) =>
    value?.toString().trim().isNotEmpty == true ? value.toString().trim() : fallback;
String _valueString(dynamic value) => value is num ? value.toString() : _string(value);

@visibleForTesting
double parseCalculatorNumber(String value) => double.tryParse(value.trim()) ?? 0;
