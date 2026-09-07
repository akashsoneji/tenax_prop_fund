import 'package:flutter/foundation.dart';

/// Top-level mode toggle on the Choose-a-challenge screen.
enum ChallengeMode { paid, freeTrial }

/// The evaluation step type (Paid mode sub-tabs).
enum ChallengeStep { twoStep, oneStep, instant }

/// A single account-size price card in the Paid grid.
@immutable
class ChallengePlan {
  const ChallengePlan({
    required this.size,
    required this.price,
    required this.original,
    required this.discountLabel,
  });

  final String size;
  final String price;
  final String original;
  final String discountLabel;

  /// Builds one price card from a plan `version`. `[discountPercent]` comes from
  /// the plan's `meta.discount_percent`; when > 0 the pre-sale price is shown as
  /// the struck-through original.
  factory ChallengePlan.fromJson(
    Map<String, dynamic> json,
    dynamic discountPercent,
  ) {
    final sizeMinor = (json['account_size_minor'] as num?)?.toInt() ?? 0;
    final priceMinor = (json['sale_price_minor'] as num?)?.toInt() ??
        (json['price_minor'] as num?)?.toInt() ??
        0;
    final origMinor = (json['price_minor'] as num?)?.toInt() ?? priceMinor;
    final discount = (discountPercent as num?)?.toInt() ?? 0;
    return ChallengePlan(
      size: _sizeLabel(sizeMinor),
      price: _money(priceMinor),
      original: origMinor > priceMinor ? _money(origMinor) : '',
      discountLabel: discount > 0 ? '$discount% OFF' : '',
    );
  }

  /// `500000` cents -> `$5K`, `10000000` -> `$100K`.
  static String _sizeLabel(int minor) {
    final dollars = minor ~/ 100;
    if (dollars >= 1000) {
      final k = dollars / 1000;
      final text = k == k.roundToDouble() ? k.toStringAsFixed(0) : '$k';
      return '\$${text}K';
    }
    return '\$$dollars';
  }

  /// `4900` cents -> `$49`.
  static String _money(int minor) => '\$${minor ~/ 100}';
}

/// A label/value rule row used in the Challenge-rules and Funded-rules cards.
@immutable
class ChallengeRule {
  const ChallengeRule(this.label, this.value);
  final String label;
  final String value;

  /// Builds a rule row. The value is `text` when present, else `pct`% .
  factory ChallengeRule.fromJson(Map<String, dynamic> json) {
    final label = json['label'] as String? ?? '';
    final text = json['text'] as String?;
    if (text != null && text.isNotEmpty) return ChallengeRule(label, text);
    final pct = json['pct'];
    if (pct is num) return ChallengeRule(label, '$pct%');
    return ChallengeRule(label, '');
  }
}

/// The fetched payload for the Choose-a-challenge screen: the price-card plans
/// plus the three rule sections. Selection state (mode / step / selected plan)
/// is NOT here — it lives on the controller as UI state.
@immutable
class ChallengeData {
  const ChallengeData({
    required this.plans,
    required this.challengeRules,
    required this.fundedRules,
    required this.trialRules,
  });

  final List<ChallengePlan> plans;
  final List<ChallengeRule> challengeRules;
  final List<ChallengeRule> fundedRules;
  final List<ChallengeRule> trialRules;

  bool get isEmpty => plans.isEmpty;

  /// Builds from the `GET /challenges` envelope. The size cards come from the
  /// first plan's `versions`; the rule sections come from that plan's
  /// `rule_rows`. `*_minor` fields are integer cents; `pct` rule values are
  /// already whole percents.
  factory ChallengeData.fromJson(Map<String, dynamic> json) {
    final plans = (json['plans'] as List<dynamic>?) ?? const [];
    final planMaps = plans.whereType<Map<String, dynamic>>().toList();
    if (planMaps.isEmpty) {
      return const ChallengeData(
        plans: [],
        challengeRules: [],
        fundedRules: [],
        trialRules: [],
      );
    }
    final first = planMaps.first;
    final versions = (first['versions'] as List<dynamic>?) ?? const [];
    final discount =
        (first['meta'] as Map<String, dynamic>?)?['discount_percent'];
    final cards = versions
        .whereType<Map<String, dynamic>>()
        .map((v) => ChallengePlan.fromJson(v, discount))
        .toList();

    final ruleRows = first['rule_rows'] as Map<String, dynamic>? ?? const {};
    final trial = json['trial'] as Map<String, dynamic>?;
    final trialRows = trial?['rule_rows'] as Map<String, dynamic>? ?? const {};

    return ChallengeData(
      plans: cards,
      challengeRules: _rules(ruleRows['challenge']),
      fundedRules: _rules(ruleRows['funded']),
      trialRules: _rules(trialRows['challenge']),
    );
  }

  static List<ChallengeRule> _rules(dynamic rows) {
    if (rows is! List) return const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ChallengeRule.fromJson)
        .toList();
  }
}

extension ChallengeStepLabel on ChallengeStep {
  String get label {
    switch (this) {
      case ChallengeStep.twoStep:
        return '2-Step';
      case ChallengeStep.oneStep:
        return '1-Step';
      case ChallengeStep.instant:
        return 'Instant';
    }
  }
}
