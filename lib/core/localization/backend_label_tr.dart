import 'package:get/get.dart';

/// Translates known backend-English strings (challenge rule labels, rule
/// values, section headers) into the active app locale. The backend ships
/// everything in English regardless of app locale, so this bridge converts
/// those fixed phrases to `.tr` keys at render time.
///
/// Unknown strings are returned verbatim — so unmapped backend strings still
/// render (in English) rather than disappearing.
///
/// To localize a new backend phrase:
///   1. Add the phrase as a key in `_map` below.
///   2. Add the matching `.tr` key value in `app_translations.dart` for every
///      supported locale.
String trBackend(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return raw;
  final lower = trimmed.toLowerCase();
  final key = _map[trimmed] ?? _map[lower] ?? _lowerMap[lower];
  if (key != null) return _translateOr(key, raw);
  for (final pattern in _patterns) {
    final match = pattern.regex.firstMatch(trimmed);
    if (match == null) continue;
    final translated = pattern.key.trParams({
      for (var i = 0; i < pattern.params.length; i++)
        pattern.params[i]: match.group(i + 1) ?? '',
    });
    return translated == pattern.key ? raw : translated;
  }
  return raw;
}

/// Translates a backend string whose meaning is fixed by a stable API id
/// (e.g. calculator field `key`) rather than by its English wording. English
/// keeps the server's own text; other locales use [key], falling back to
/// [trBackend] when no translation exists.
String trByKey(String key, String fallback) {
  if (Get.locale?.languageCode == 'en') return fallback;
  final translated = key.tr;
  return translated == key ? trBackend(fallback) : translated;
}

String _translateOr(String key, String raw) {
  final translated = key.tr;
  // GetX returns the key itself when a translation is missing; fall back to
  // the original English so the UI never shows a bare `backend_rule.*` key.
  return translated == key ? raw : translated;
}

final Map<String, String> _lowerMap = {
  for (final entry in _map.entries)
    if (!_map.containsKey(entry.key.toLowerCase()))
      entry.key.toLowerCase(): entry.value,
};

class _BackendPattern {
  const _BackendPattern(this.source, this.key, this.params);
  final String source;
  final String key;
  final List<String> params;
  RegExp get regex => RegExp(source, caseSensitive: false);
}

/// Backend phrases that embed a number (days, seconds, percent, leverage).
const List<_BackendPattern> _patterns = [
  _BackendPattern(r'^every (\d+) days?$', 'backend_rule.every_days', ['n']),
  _BackendPattern(r'^after (\d+) days?$', 'backend_rule.after_days', ['n']),
  _BackendPattern(r'^(\d+) days?$', 'backend_rule.n_days', ['n']),
  _BackendPattern(r'^(\d+) to watch$', 'backend_rule.n_to_watch', ['n']),
  _BackendPattern(
      r'^(\d+(?:\.\d+)?)% of plan fee$', 'backend_rule.pct_of_plan_fee', ['n']),
  _BackendPattern(r'^leverage (1:\d+)$', 'backend_rule.leverage_value', ['v']),
  _BackendPattern(r'^increase your trading leverage to (1:\d+)x?\.?$',
      'backend_rule.leverage_desc', ['v']),
  _BackendPattern(r'^profit from trades held under (\d+) seconds\.?$',
      'backend_rule.health_quick_strike_desc', ['n']),
];

/// Backend phrase → translation key. Exact match first, then case-insensitive.
const Map<String, String> _map = {
  // --- Rule-card section headers ---
  'Account & platform': 'backend_rule.account_platform',
  'Conduct & fee': 'backend_rule.conduct_fee',
  "What's included": 'backend_rule.whats_included',
  'What’s included': 'backend_rule.whats_included',
  'Targets & limits': 'backend_rule.targets_limits',
  'Rewards': 'backend_rule.rewards',

  // --- More rule labels ---
  'Leverage': 'backend_rule.leverage',
  'Max lot per trade': 'backend_rule.max_lot_per_trade',
  'Max total open lots': 'backend_rule.max_total_open_lots',
  'Max open positions': 'backend_rule.max_open_positions',
  'Daily reset': 'backend_rule.daily_reset',
  'Per-trade loss cap': 'backend_rule.per_trade_loss_cap',
  'Inactivity warning': 'backend_rule.inactivity_warning',
  'Platform': 'backend_rule.platform',
  'News trading': 'backend_rule.news_trading',
  'Weekend holding': 'backend_rule.weekend_holding',
  'Hedging': 'backend_rule.hedging',
  'Expert advisors': 'backend_rule.expert_advisors',
  'Copy trading': 'backend_rule.copy_trading',
  'Time limit': 'backend_rule.time_limit',
  'Payout frequency': 'backend_rule.payout_frequency',
  'Max daily loss': 'backend_rule.max_daily_loss',
  'Max drawdown': 'backend_rule.max_drawdown',

  // --- More rule values ---
  'Unlimited': 'backend_rule.unlimited',
  'Allowed': 'backend_rule.allowed',
  'Not allowed': 'backend_rule.not_allowed',
  'Yes': 'backend_rule.yes',
  'No': 'backend_rule.no',
  'Included': 'backend_rule.included',
  'On demand': 'backend_rule.on_demand',
  'Daily': 'backend_rule.daily',
  'Weekly': 'backend_rule.weekly',
  'Bi-weekly': 'backend_rule.bi_weekly',
  'Monthly': 'backend_rule.monthly',
  'Balance-based': 'backend_rule.balance_based',
  'Equity-based': 'backend_rule.equity_based',

  // --- Account-health checks ---
  'Consistency': 'backend_rule.health_consistency',
  'Quick strike': 'backend_rule.health_quick_strike',
  'Hyperactivity': 'backend_rule.health_hyperactivity',
  'Share of profit made on your best single day.':
      'backend_rule.health_consistency_desc',
  'Share of profit made on your best single day':
      'backend_rule.health_consistency_desc',
  'Trades placed today.': 'backend_rule.health_hyperactivity_desc',
  'Trades placed today': 'backend_rule.health_hyperactivity_desc',
  'watch': 'backend_rule.status_watch',
  'pass': 'backend_rule.status_pass',
  'ok': 'backend_rule.status_ok',
  'breach': 'backend_rule.status_breach',

  // --- Trade side chips ---
  'buy': 'backend_rule.side_buy',
  'sell': 'backend_rule.side_sell',

  'Cryptos': 'backend_rule.crypto',

  // --- Rule labels ---
  'Account size': 'backend_rule.account_size',
  'Consistency rule': 'backend_rule.consistency_rule',
  'Daily loss limit': 'backend_rule.daily_loss_limit',
  'Drawdown type': 'backend_rule.drawdown_type',
  'Expires after': 'backend_rule.expires_after',
  'First reward': 'backend_rule.first_reward',
  'Maximum loss': 'backend_rule.maximum_loss',
  'Maximum loss limit': 'backend_rule.maximum_loss_limit',
  'Minimum trading days': 'backend_rule.minimum_trading_days',
  'Phase 1 profit target': 'backend_rule.phase_1_profit_target',
  'Phase 2 profit target': 'backend_rule.phase_2_profit_target',
  'Profit target': 'backend_rule.profit_target',
  'Refundable fee': 'backend_rule.refundable_fee',
  'Reward share': 'backend_rule.reward_share',
  'Subsequent rewards': 'backend_rule.subsequent_rewards',

  // --- Rule values ---
  'None': 'backend_rule.none',
  'Not refundable': 'backend_rule.not_refundable',
  'Refundable': 'backend_rule.refundable',
  'Static': 'backend_rule.static',
  'Trailing': 'backend_rule.trailing',

  // --- Rule-box section headers ---
  'Funded': 'backend_rule.funded',
  'Phase 1': 'backend_rule.phase_1',
  'Phase 2': 'backend_rule.phase_2',

  // --- Challenge format tabs ---
  'Instant': 'backend_rule.instant',
  'Step-1': 'backend_rule.step_1',
  'Step-2': 'backend_rule.step_2',
  'Step-3': 'backend_rule.step_3',
  '1-Step': 'backend_rule.step_1',
  '2-Step': 'backend_rule.step_2',
  '3-Step': 'backend_rule.step_3',

  // --- Payment methods ---
  'Crypto': 'backend_rule.crypto',
  'Card': 'backend_rule.card',
  'Bank transfer': 'backend_rule.bank_transfer',
  'Wire transfer': 'backend_rule.wire_transfer',

  // --- Add-ons (title / description / tag strings often sent raw) ---
  'Swap-Free': 'backend_rule.addon_swap_free',
  'Swap-free': 'backend_rule.addon_swap_free',
  'Hold positions overnight with no swap charged on this account.':
      'backend_rule.addon_swap_free_desc',
  'Hold positions overnight with no swap charged on this account':
      'backend_rule.addon_swap_free_desc',
  'Server priced': 'configure.server_priced',

  // --- Payment-screen backend strings (order status, pills, field keys,
  //      instruction notes) ---
  'awaiting payment': 'backend_rule.status_awaiting_payment',
  'awaiting_payment': 'backend_rule.status_awaiting_payment',
  'under review': 'backend_rule.status_under_review',
  'under_review': 'backend_rule.status_under_review',
  'paid': 'backend_rule.status_paid',
  'failed': 'backend_rule.status_failed',
  'expired': 'backend_rule.status_expired',
  'cancelled': 'backend_rule.status_cancelled',
  'crypto': 'backend_rule.type_crypto',
  'bank': 'backend_rule.type_bank',
  'card': 'backend_rule.type_card',
  'Network': 'backend_rule.field_network',
  'Asset': 'backend_rule.field_asset',
  'Address': 'backend_rule.field_address',
  'Memo': 'backend_rule.field_memo',
  'Tag': 'backend_rule.field_tag',
  'Account name': 'backend_rule.field_account_name',
  'Account number': 'backend_rule.field_account_number',
  'Bank name': 'backend_rule.field_bank_name',
  'IBAN': 'backend_rule.field_iban',
  'SWIFT': 'backend_rule.field_swift',
  'Reference': 'backend_rule.field_reference',
  'pay same amount as plan and attach screenshot':
      'backend_rule.pay_same_amount_note',
  'Pay same amount as plan and attach screenshot':
      'backend_rule.pay_same_amount_note',
};
