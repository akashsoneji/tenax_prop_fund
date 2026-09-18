import 'package:flutter/foundation.dart';

enum ChallengeMode { paid, freeTrial }
enum ChallengeStep { twoStep, oneStep, instant }

@immutable
class ChallengePlan {
  const ChallengePlan({
    required this.id,
    required this.name,
    required this.slug,
    required this.format,
    required this.size,
    required this.price,
    required this.original,
    required this.discountLabel,
    required this.currency,
    required this.versions,
    required this.ruleBoxes,
    required this.challengeRules,
    required this.fundedRules,
  });

  final int id;
  final String name;
  final String slug;
  final String format;
  final String size;
  final String price;
  final String original;
  final String discountLabel;
  final String currency;
  final List<ChallengeVersion> versions;
  final List<ChallengeRuleBox> ruleBoxes;
  final List<ChallengeRule> challengeRules;
  final List<ChallengeRule> fundedRules;

  ChallengeVersion? get defaultVersion =>
      versions.isEmpty ? null : versions.first;

  factory ChallengePlan.fromJson(Map<String, dynamic> json) {
    final meta = _map(json['meta']);
    final versions = _maps(json['versions'])
        .map(ChallengeVersion.fromJson)
        .toList(growable: false);
    final firstVersion = versions.isNotEmpty ? versions.first : null;
    final priceMinor = firstVersion?.salePriceMinor ??
        (json['from_price_minor'] as num?)?.toInt() ?? 0;
    final originalMinor = firstVersion?.priceMinor ?? priceMinor;
    final discount = (meta['discount_percent'] as num?)?.toInt() ?? 0;
    final rows = _map(json['rule_rows']);

    return ChallengePlan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      format: meta['format'] as String? ?? json['short'] as String? ?? '',
      size: _sizeLabel(json['popular_size_minor'] ?? 0),
      price: _money(priceMinor),
      original: originalMinor > priceMinor ? _money(originalMinor) : '',
      discountLabel: discount > 0 ? '$discount% OFF' : '',
      currency: json['currency'] as String? ?? 'USD',
      versions: versions,
      ruleBoxes: _maps(rows['boxes'])
          .map(ChallengeRuleBox.fromJson)
          .toList(growable: false),
      challengeRules: _rules(rows['challenge']),
      fundedRules: _rules(rows['funded']),
    );
  }

  static List<ChallengeRule> _rules(dynamic value) => _maps(value)
      .map(ChallengeRule.fromJson)
      .toList(growable: false);

  static String _sizeLabel(dynamic minorValue) {
    final dollars = ((minorValue as num?)?.toInt() ?? 0) ~/ 100;
    if (dollars >= 1000) {
      final k = dollars / 1000;
      return '\$${k == k.roundToDouble() ? k.toStringAsFixed(0) : k}K';
    }
    return '\$$dollars';
  }

  static String _money(int minor) => '\$${minor ~/ 100}';
}

String _formatNumber(num value) => value % 1 == 0
    ? value.toInt().toString()
    : value.toString();

@immutable
class ChallengeVersion {
  const ChallengeVersion({
    required this.id,
    required this.accountSizeMinor,
    required this.priceMinor,
    required this.salePriceMinor,
    required this.currency,
    required this.leverage,
    required this.rules,
    required this.stages,
  });

  final int id;
  final int accountSizeMinor;
  final int priceMinor;
  final int salePriceMinor;
  final String currency;
  final int leverage;
  final ChallengeVersionRules rules;
  final List<ChallengeStage> stages;

  int get displayedPriceMinor => salePriceMinor > 0 ? salePriceMinor : priceMinor;

  factory ChallengeVersion.fromJson(Map<String, dynamic> json) {
    return ChallengeVersion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      accountSizeMinor: (json['account_size_minor'] as num?)?.toInt() ?? 0,
      priceMinor: (json['price_minor'] as num?)?.toInt() ?? 0,
      salePriceMinor: (json['sale_price_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      leverage: (json['leverage'] as num?)?.toInt() ?? 0,
      rules: ChallengeVersionRules.fromJson(_map(json['rules'])),
      stages: _maps(json['stages'])
          .map(ChallengeStage.fromJson)
          .toList(growable: false),
    );
  }
}

@immutable
class ChallengeVersionRules {
  const ChallengeVersionRules({
    required this.drawdownType,
    required this.rewardShareBps,
    required this.consistencyBps,
    required this.perTradeLossBps,
    required this.firstRewardDays,
    required this.refundPolicy,
    required this.maxLotPerTrade,
    required this.maxTotalOpenLots,
    required this.maxOpenPositions,
    required this.dailyResetHour,
    required this.dailyResetTimezone,
    required this.inactivityWarnDays,
  });

  final String drawdownType;
  final int rewardShareBps;
  final int consistencyBps;
  final int perTradeLossBps;
  final int firstRewardDays;
  final String refundPolicy;
  final double? maxLotPerTrade;
  final double? maxTotalOpenLots;
  final int? maxOpenPositions;
  final int? dailyResetHour;
  final String dailyResetTimezone;
  final int? inactivityWarnDays;

  factory ChallengeVersionRules.fromJson(Map<String, dynamic> json) {
    return ChallengeVersionRules(
      drawdownType: json['drawdown_type'] as String? ?? '',
      rewardShareBps: (json['reward_share_bps'] as num?)?.toInt() ?? 0,
      consistencyBps: (json['consistency_bps'] as num?)?.toInt() ?? 0,
      perTradeLossBps: (json['per_trade_loss_bps'] as num?)?.toInt() ?? 0,
      firstRewardDays: (json['first_reward_days'] as num?)?.toInt() ?? 0,
      refundPolicy: json['refund_policy'] as String? ?? '',
      maxLotPerTrade: (json['max_lot_per_trade'] as num?)?.toDouble(),
      maxTotalOpenLots: (json['max_total_open_lots'] as num?)?.toDouble(),
      maxOpenPositions: (json['max_open_positions'] as num?)?.toInt(),
      dailyResetHour: (json['daily_reset_hour'] as num?)?.toInt(),
      dailyResetTimezone: json['daily_reset_timezone'] as String? ?? 'UTC',
      inactivityWarnDays: (json['inactivity_warn_days'] as num?)?.toInt(),
    );
  }
}

@immutable
class ChallengeStage {
  const ChallengeStage({required this.name, required this.kind, required this.rows});
  final String name;
  final String kind;
  final List<ChallengeRule> rows;

  factory ChallengeStage.fromJson(Map<String, dynamic> json) {
    return ChallengeStage(
      name: json['name'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      rows: [
        if (json['profit_target_bps'] != null)
          ChallengeRule('Profit target', '${(json['profit_target_bps'] as num).toInt() / 100}%'),
        if (json['max_daily_loss_bps'] != null)
          ChallengeRule('Daily loss limit', '${(json['max_daily_loss_bps'] as num).toInt() / 100}%'),
        if (json['max_total_loss_bps'] != null)
          ChallengeRule('Maximum loss limit', '${(json['max_total_loss_bps'] as num).toInt() / 100}%'),
        if (json['min_trading_days'] != null)
          ChallengeRule('Minimum trading days', '${json['min_trading_days']} days'),
      ],
    );
  }
}

@immutable
class ChallengeRule {
  const ChallengeRule(this.label, this.value, {this.tip = '', this.tone});
  final String label;
  final String value;
  final String tip;
  final String? tone;

  factory ChallengeRule.fromJson(Map<String, dynamic> json) {
    final text = json['text'] as String?;
    final pct = json['pct'];
    return ChallengeRule(
      json['label'] as String? ?? '',
      text?.isNotEmpty == true ? text! : pct is num ? '${_formatNumber(pct)}%' : '',
      tip: json['tip'] as String? ?? '',
      tone: json['tone'] as String?,
    );
  }
}

@immutable
class ChallengeRuleBox {
  const ChallengeRuleBox({required this.title, required this.caption, required this.wide, required this.rows});
  final String title;
  final String caption;
  final bool wide;
  final List<ChallengeRule> rows;

  factory ChallengeRuleBox.fromJson(Map<String, dynamic> json) => ChallengeRuleBox(
        title: json['title'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        wide: json['wide'] as bool? ?? false,
        rows: _maps(json['rows']).map(ChallengeRule.fromJson).toList(growable: false),
      );
}

@immutable
class ChallengeAddon {
  const ChallengeAddon({required this.id, required this.name, required this.description, required this.priceMinor, required this.percentOfFee, required this.currency});

  final int id;
  final String name;
  final String description;
  final int priceMinor;
  final int percentOfFee;
  final String currency;

  factory ChallengeAddon.fromJson(Map<String, dynamic> json) => ChallengeAddon(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        priceMinor: (json['price_minor'] as num?)?.toInt() ?? 0,
        percentOfFee: (json['percent_of_fee'] as num?)?.toInt() ?? 0,
        currency: json['currency'] as String? ?? 'USD',
      );
}

@immutable
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    required this.isManual,
    required this.instructions,
  });
  final int id;
  final String name;
  final String type;
  final bool isManual;
  final String instructions;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '',
        isManual: json['is_manual'] as bool? ?? false,
        instructions: json['instructions'] as String? ?? '',
      );
}

@immutable
class ChallengePlatform {
  const ChallengePlatform({required this.id, required this.value, required this.label, required this.isDefault, required this.feeMinor});
  final int id;
  final String value;
  final String label;
  final bool isDefault;
  final int feeMinor;

  factory ChallengePlatform.fromJson(Map<String, dynamic> json) => ChallengePlatform(
        id: (json['id'] as num?)?.toInt() ?? 0,
        value: json['value'] as String? ?? '',
        label: json['label'] as String? ?? '',
        isDefault: json['default'] as bool? ?? false,
        feeMinor: (json['fee_minor'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class ChallengeTrial {
  const ChallengeTrial({required this.enabled, required this.name, required this.accountSizeMinor, required this.days, required this.profitTargetPercent, required this.dailyLossPercent, required this.maxLossPercent, required this.minTradingDays, required this.passRewardPercent, required this.couponCode, required this.requiresKyc});
  final bool enabled;
  final String name;
  final int accountSizeMinor;
  final int days;
  final num profitTargetPercent;
  final num dailyLossPercent;
  final num maxLossPercent;
  final int minTradingDays;
  final num passRewardPercent;
  final String couponCode;
  final bool requiresKyc;

  factory ChallengeTrial.fromJson(Map<String, dynamic> json) => ChallengeTrial(
        enabled: json['enabled'] as bool? ?? false,
        name: json['name'] as String? ?? '',
        accountSizeMinor: (json['account_size_minor'] as num?)?.toInt() ?? 0,
        days: (json['days'] as num?)?.toInt() ?? 0,
        profitTargetPercent: json['profit_target_percent'] as num? ?? 0,
        dailyLossPercent: json['daily_loss_percent'] as num? ?? 0,
        maxLossPercent: json['max_loss_percent'] as num? ?? 0,
        minTradingDays: (json['min_trading_days'] as num?)?.toInt() ?? 0,
        passRewardPercent: json['pass_reward_percent'] as num? ?? 0,
        couponCode: json['pass_coupon_code'] as String? ?? '',
        requiresKyc: json['requires_kyc'] as bool? ?? false,
      );
}

@immutable
class ChallengeData {
  const ChallengeData({required this.plans, required this.challengeRules, required this.fundedRules, required this.trialRules, required this.addons, required this.platforms, required this.paymentMethods, required this.trial, required this.currency});
  final List<ChallengePlan> plans;
  final List<ChallengeRule> challengeRules;
  final List<ChallengeRule> fundedRules;
  final List<ChallengeRule> trialRules;
  final List<ChallengeAddon> addons;
  final List<ChallengePlatform> platforms;
  final List<PaymentMethod> paymentMethods;
  final ChallengeTrial? trial;
  final String currency;

  bool get isEmpty => plans.isEmpty && trial == null;

  factory ChallengeData.fromJson(Map<String, dynamic> json) {
    final plans = _maps(json['plans']).map(ChallengePlan.fromJson).toList(growable: false);
    final first = plans.isNotEmpty ? plans.first : null;
    final trial = json['trial'] is Map<String, dynamic> ? ChallengeTrial.fromJson(json['trial'] as Map<String, dynamic>) : null;
    return ChallengeData(
      plans: plans,
      challengeRules: first?.challengeRules ?? const [],
      fundedRules: first?.fundedRules ?? const [],
      trialRules: const [],
      addons: _maps(json['addons']).map(ChallengeAddon.fromJson).toList(growable: false),
      platforms: _maps(json['platforms']).map(ChallengePlatform.fromJson).toList(growable: false),
      paymentMethods: _maps(json['paymentMethods']).map(PaymentMethod.fromJson).toList(growable: false),
      trial: trial,
      currency: json['currency'] as String? ?? 'USD',
    );
  }
}

List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value.whereType<Map<String, dynamic>>().toList()
    : const [];
Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : const {};

@immutable
class ChallengeQuote {
  const ChallengeQuote({
    required this.subtotalMinor,
    required this.discountMinor,
    required this.totalMinor,
    required this.currency,
    required this.quantity,
    required this.planUnitMinor,
    required this.planNetMinor,
    required this.addonsMinor,
    required this.addonsNetMinor,
    required this.swapFeeMinor,
    required this.swapNetMinor,
    required this.swapQuoteMinor,
    required this.swapPercent,
    required this.platformFeeMinor,
    required this.platformNetMinor,
    required this.addonPrices,
    this.couponCode,
  });

  final int subtotalMinor;
  final int discountMinor;
  final int totalMinor;
  final String currency;
  final int quantity;
  final int planUnitMinor;
  final int planNetMinor;
  final int addonsMinor;
  final int addonsNetMinor;
  final int swapFeeMinor;
  final int swapNetMinor;
  final int swapQuoteMinor;
  final num swapPercent;
  final int platformFeeMinor;
  final int platformNetMinor;
  final Map<String, ChallengeQuoteAddon> addonPrices;

  /// Applied coupon code (upper-cased by the server), or null when none.
  final String? couponCode;

  factory ChallengeQuote.fromJson(Map<String, dynamic> json) => ChallengeQuote(
        subtotalMinor: _minor(json['subtotal_minor']),
        discountMinor: _minor(json['discount_minor']),
        totalMinor: _minor(json['total_minor']),
        currency: json['currency'] as String? ?? 'USD',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        planUnitMinor: _minor(json['plan_unit_minor']),
        planNetMinor: _minor(json['plan_net_minor']),
        addonsMinor: _minor(json['addons_minor']),
        addonsNetMinor: _minor(json['addons_net_minor']),
        swapFeeMinor: _minor(json['swap_fee_minor']),
        swapNetMinor: _minor(json['swap_net_minor']),
        swapQuoteMinor: _minor(json['swap_quote_minor']),
        swapPercent: json['swap_pct'] as num? ?? 0,
        platformFeeMinor: _minor(json['platform_fee_minor']),
        platformNetMinor: _minor(json['platform_net_minor']),
        addonPrices: _map(json['addon_prices']).map(
          (key, value) => MapEntry(key, ChallengeQuoteAddon.fromJson(_map(value))),
        ),
        couponCode: _map(json['coupon'])['code'] as String?,
      );

  String get totalLabel => '\$${(totalMinor / 100).toStringAsFixed(2)}';
}

@immutable
class ChallengeQuoteAddon {
  const ChallengeQuoteAddon({required this.unitMinor, required this.netMinor});
  final int unitMinor;
  final int netMinor;

  factory ChallengeQuoteAddon.fromJson(Map<String, dynamic> json) => ChallengeQuoteAddon(
        unitMinor: _minor(json['unit_minor']),
        netMinor: _minor(json['net_minor']),
      );
}

int _minor(dynamic value) => (value as num?)?.toInt() ?? 0;

/// Outcome of `POST /challenges/purchase`. [path] is `free` (instant, no
/// payment), `manual` (upload proof) or `gateway` (redirect to [gatewayUrl]).
@immutable
class PurchaseResult {
  const PurchaseResult({
    required this.orderId,
    required this.path,
    required this.gatewayUrl,
  });
  final String orderId;
  final String path;
  final String? gatewayUrl;

  bool get isManual => path == 'manual';
  bool get isFree => path == 'free';
  bool get isGateway => path == 'gateway';

  factory PurchaseResult.fromJson(Map<String, dynamic> json) => PurchaseResult(
        orderId: '${json['order_id'] ?? ''}',
        path: json['path'] as String? ?? '',
        gatewayUrl: json['gateway_url'] as String?,
      );
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
