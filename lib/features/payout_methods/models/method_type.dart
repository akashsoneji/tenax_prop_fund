/// An admin-configured payout rail (Bank, USDT…) returned by
/// `GET /finance/method-types`, plus the fields the user must fill to save a
/// method of that type.
///
/// NOTE: the exact response keys are not yet verified against a live payload.
/// Parsing is intentionally defensive (multiple key fallbacks) and should be
/// tightened once a real `GET /finance/method-types` response is captured.
class MethodType {
  const MethodType({
    required this.value,
    required this.label,
    required this.fields,
    this.currency,
  });

  /// The `type` value sent back to `POST /finance/methods` (e.g. `bank`,
  /// `crypto`, `upi`).
  final String value;

  /// Display name for the rail (e.g. "Bank transfer").
  final String label;

  /// Currency the rail settles in, when the API pins one.
  final String? currency;

  /// The input fields this rail requires.
  final List<MethodTypeField> fields;

  factory MethodType.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'] ?? json['details'] ?? json['inputs'];
    final fields = rawFields is List
        ? rawFields
            .whereType<Map<String, dynamic>>()
            .map(MethodTypeField.fromJson)
            .toList()
        : <MethodTypeField>[];
    return MethodType(
      value: (json['value'] ?? json['type'] ?? json['key'] ?? '').toString(),
      label: (json['label'] ?? json['name'] ?? json['title'] ?? '—').toString(),
      currency: (json['currency'] as String?)?.trim().isNotEmpty == true
          ? json['currency'] as String
          : null,
      fields: fields,
    );
  }
}

/// One input a payout method of a given [MethodType] needs. Goes into the
/// `details` map of `POST /finance/methods` under [key].
class MethodTypeField {
  const MethodTypeField({
    required this.key,
    required this.label,
    required this.required,
    required this.type,
    this.placeholder,
  });

  /// Hint shown inside the empty input (e.g. `TRC20`, `name@upi`).
  final String? placeholder;

  /// The details-map key (e.g. `account_number`, `ifsc`, `address`, `network`).
  final String key;

  /// Human label for the form field.
  final String label;

  final bool required;

  /// Loose input type hint: `text`, `number`, `email`… defaults to `text`.
  final String type;

  factory MethodTypeField.fromJson(Map<String, dynamic> json) {
    return MethodTypeField(
      key: (json['key'] ?? json['name'] ?? json['field'] ?? '').toString(),
      label: (json['label'] ?? json['title'] ?? json['name'] ?? '—').toString(),
      required: json['required'] as bool? ??
          json['is_required'] as bool? ??
          true,
      type: (json['type'] ?? json['input'] ?? 'text').toString(),
      placeholder: (json['placeholder'] ?? json['hint'])?.toString(),
    );
  }
}
