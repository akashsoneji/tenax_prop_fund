/// Home dashboard snapshot from `GET /dashboard`. Mirrors the web portal's
/// dashboard payload (welcome, KPI tiles, account health, the focused account's
/// risk tiles, recent activity, quick actions, referral summary and the light
/// live-account list). Kept display-oriented so the Home tab binds directly to
/// it, with a WebSocket layer patching `live_accounts` equity in real time.
library;

import 'package:get/get.dart';

class DashboardData {
  const DashboardData({
    required this.welcome,
    required this.kpis,
    required this.health,
    required this.healthBadge,
    required this.focus,
    required this.activity,
    required this.quickActions,
    required this.referral,
    required this.accountCount,
    required this.liveAccounts,
    required this.liveUserId,
    this.trades = const [],
  });

  final DashboardWelcome welcome;
  final List<DashboardKpi> kpis;
  final List<DashboardHealth> health;
  final String healthBadge;
  final DashboardFocus? focus;
  final List<DashboardActivity> activity;
  final List<DashboardQuickAction> quickActions;
  final DashboardReferral? referral;
  final int accountCount;
  final List<DashboardAccount> liveAccounts;

  /// Recent trades across the trader's accounts, from `/dashboard` `trades[]`.
  final List<DashboardTrade> trades;

  /// The trader id used to build the per-user Pusher channel
  /// `private-trader.{liveUserId}.accounts`. From `/dashboard` `liveUserId`.
  final int liveUserId;

  bool get isEmpty => kpis.isEmpty && liveAccounts.isEmpty;


  /// Returns a copy with live fields replaced — used by the controller to
  /// splice in a WebSocket equity tick without rebuilding the whole snapshot.
  DashboardData copyWith({
    List<DashboardAccount>? liveAccounts,
    List<DashboardKpi>? kpis,
    DashboardFocus? focus,
    DashboardReferral? referral,
  }) =>
      DashboardData(
        welcome: welcome,
        kpis: kpis ?? this.kpis,
        health: health,
        healthBadge: healthBadge,
        focus: focus ?? this.focus,
        activity: activity,
        quickActions: quickActions,
        referral: referral ?? this.referral,
        accountCount: accountCount,
        liveAccounts: liveAccounts ?? this.liveAccounts,
        liveUserId: liveUserId,
        trades: trades,
      );

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final kpis = _list(json['kpis']).map(DashboardKpi.fromJson).toList();
    final liveAccounts = _list(json['liveAccounts'] ?? json['live_accounts'])
        .map(DashboardAccount.fromJson)
        .toList();

    var welcome = DashboardWelcome.fromJson(
        (json['welcome'] as Map?)?.cast<String, dynamic>() ?? const {});
    var focus = json['focus'] is Map
        ? DashboardFocus.fromJson((json['focus'] as Map).cast<String, dynamic>())
        : null;

    // The `/dashboard` endpoint currently returns only kpis + live_accounts.
    // Synthesize the hero (welcome header + focused-account card) from that
    // real data so the top of the screen is never blank.
    if (welcome.headline.isEmpty) {
      welcome = DashboardWelcome(
        headline: 'home.welcome_back'.tr,
        subtitle: liveAccounts.isEmpty
            ? ''
            : (liveAccounts.length == 1
                    ? 'home.active_account_one'
                    : 'home.active_accounts')
                .trParams({'count': '${liveAccounts.length}'}),
      );
    }
    if (focus == null && liveAccounts.isNotEmpty) {
      focus = DashboardFocus.fromAccount(liveAccounts.first);
    }

    return DashboardData(
      welcome: welcome,
      kpis: kpis,
      health: _list(json['health']).map(DashboardHealth.fromJson).toList(),
      healthBadge: json['healthBadge'] as String? ??
          json['health_badge'] as String? ??
          '',
      focus: focus,
      activity:
          _list(json['activity']).map(DashboardActivity.fromJson).toList(),
      quickActions: _list(json['quickActions'])
          .map(DashboardQuickAction.fromJson)
          .toList(),
      referral: json['referral'] is Map
          ? DashboardReferral.fromJson(
              (json['referral'] as Map).cast<String, dynamic>())
          : null,
      accountCount: (json['accountCount'] as num?)?.toInt() ??
          (json['account_count'] as num?)?.toInt() ??
          liveAccounts.length,
      liveAccounts: liveAccounts,
      liveUserId: (json['liveUserId'] as num?)?.toInt() ??
          (json['live_user_id'] as num?)?.toInt() ??
          0,
      trades: _list(json['trades']).map(DashboardTrade.fromJson).toList(),
    );
  }

  static List<Map<String, dynamic>> _list(dynamic raw) =>
      ((raw as List?) ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
}

/// The greeting header ("Welcome back, test" + stage/equity subtitle).
class DashboardWelcome {
  const DashboardWelcome({required this.headline, required this.subtitle});

  final String headline;
  final String subtitle;

  factory DashboardWelcome.fromJson(Map<String, dynamic> json) =>
      DashboardWelcome(
        headline: json['headline'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
      );
}

/// A single KPI tile (Account equity / Balance / Status / Trading days).
class DashboardKpi {
  const DashboardKpi({
    required this.label,
    required this.value,
    required this.hint,
    required this.tone,
    required this.icon,
    required this.delta,
    required this.deltaTone,
    required this.metric,
    required this.valueMinor,
  });

  final String label;
  final String value;
  final String hint;

  /// 'up' | 'down' | 'gold' | 'neutral' — drives the accent colour.
  final String tone;
  final String icon;
  final String delta;
  final String deltaTone;

  /// e.g. 'equity_minor' / 'balance_minor' — lets the WS layer patch this tile.
  final String metric;
  final int valueMinor;

  bool get isUp => tone == 'up';
  bool get isDown => tone == 'down';
  bool get isGold => tone == 'gold';

  DashboardKpi copyWith({String? value, int? valueMinor, String? delta}) =>
      DashboardKpi(
        label: label,
        value: value ?? this.value,
        hint: hint,
        tone: tone,
        icon: icon,
        delta: delta ?? this.delta,
        deltaTone: deltaTone,
        metric: metric,
        valueMinor: valueMinor ?? this.valueMinor,
      );

  factory DashboardKpi.fromJson(Map<String, dynamic> json) => DashboardKpi(
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
        hint: json['hint'] as String? ?? '',
        tone: json['tone'] as String? ?? 'neutral',
        icon: json['icon'] as String? ?? '',
        delta: json['delta'] as String? ?? '',
        deltaTone: json['delta_tone'] as String? ?? 'up',
        metric: json['metric'] as String? ?? '',
        valueMinor: (json['value_minor'] as num?)?.toInt() ?? 0,
      );
}

/// An account-health row (Consistency / Quick strike / Hyperactivity).
class DashboardHealth {
  const DashboardHealth({
    required this.name,
    required this.status,
    required this.line1,
    required this.line2,
  });

  final String name;
  final String status;
  final String line1;
  final String line2;

  bool get isWatch => status.toLowerCase() == 'watch';
  bool get isBreach => status.toLowerCase() == 'breach';

  factory DashboardHealth.fromJson(Map<String, dynamic> json) =>
      DashboardHealth(
        name: json['name'] as String? ?? '',
        status: json['status'] as String? ?? '',
        line1: json['line1'] as String? ?? '',
        line2: json['line2'] as String? ?? '',
      );
}

/// The focused trading account shown in the purple hero card.
class DashboardFocus {
  const DashboardFocus({
    required this.accountId,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeTone,
    required this.equity,
    required this.equityMinor,
    this.balance = '',
    this.balanceMinor = 0,
    required this.currency,
    required this.note,
    required this.tiles,
  });

  final int accountId;
  final String title;
  final String subtitle;
  final String badge;
  final String badgeTone;
  final String equity;
  final int equityMinor;
  final String balance;
  final int balanceMinor;
  final String currency;
  final String note;
  final List<DashboardFocusTile> tiles;

  DashboardFocus copyWith({
    String? equity,
    int? equityMinor,
    String? balance,
    int? balanceMinor,
  }) =>
      DashboardFocus(
        accountId: accountId,
        title: title,
        subtitle: subtitle,
        badge: badge,
        badgeTone: badgeTone,
        equity: equity ?? this.equity,
        equityMinor: equityMinor ?? this.equityMinor,
        balance: balance ?? this.balance,
        balanceMinor: balanceMinor ?? this.balanceMinor,
        currency: currency,
        note: note,
        tiles: tiles,
      );

  /// Builds the focused-account hero from a `live_accounts[]` row — used both
  /// for the initial synth and when the user switches accounts in the hero.
  factory DashboardFocus.fromAccount(DashboardAccount a) {
    final pnl = a.equityMinor - a.balanceMinor;
    return DashboardFocus(
      accountId: a.id,
      title: 'Account #${a.id}',
      subtitle: '${a.currency} · Live equity',
      badge: '',
      badgeTone: 'neutral',
      equity: _fmtMinor(a.equityMinor, a.currency),
      equityMinor: a.equityMinor,
      balance: _fmtMinor(a.balanceMinor, a.currency),
      balanceMinor: a.balanceMinor,
      currency: a.currency,
      note: pnl == 0
          ? ''
          : '${pnl > 0 ? '+' : '-'}${_fmtMinor(pnl.abs(), a.currency)} '
              'vs balance',
      tiles: const [],
    );
  }

  static String _fmtMinor(int minor, String currency) {
    final major = (minor / 100).toStringAsFixed(2);
    final parts = major.split('.');
    final buf = StringBuffer();
    final intPart = parts[0];
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    final symbol = currency == 'USD' ? '\$' : '';
    return '$symbol$buf.${parts[1]}';
  }

  factory DashboardFocus.fromJson(Map<String, dynamic> json) => DashboardFocus(
        accountId: (json['account_id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        badge: json['badge'] as String? ?? '',
        badgeTone: json['badge_tone'] as String? ?? 'neutral',
        equity: json['equity'] as String? ?? '',
        equityMinor: (json['equity_minor'] as num?)?.toInt() ?? 0,
        currency: json['currency'] as String? ?? 'USD',
        note: json['note'] as String? ?? '',
        tiles: ((json['tiles'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => DashboardFocusTile.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}

/// A risk tile inside the focused-account hero (Daily loss / Drawdown / …).
class DashboardFocusTile {
  const DashboardFocusTile({
    required this.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.tone,
    required this.percent,
  });

  final String key;
  final String label;
  final String value;
  final String hint;
  final String tone;

  /// 0..100 progress used for the tile's mini bar.
  final double percent;

  factory DashboardFocusTile.fromJson(Map<String, dynamic> json) =>
      DashboardFocusTile(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
        hint: json['hint'] as String? ?? '',
        tone: json['tone'] as String? ?? 'neutral',
        percent: (json['percent'] as num?)?.toDouble() ?? 0,
      );
}

/// A recent-activity row.
class DashboardActivity {
  const DashboardActivity({
    required this.tone,
    required this.title,
    required this.detail,
    required this.when,
  });

  final String tone;
  final String title;
  final String detail;
  final String when;

  factory DashboardActivity.fromJson(Map<String, dynamic> json) =>
      DashboardActivity(
        tone: json['tone'] as String? ?? 'purple',
        title: json['title'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        when: json['when'] as String? ?? '',
      );
}

/// A quick-action shortcut tile.
class DashboardQuickAction {
  const DashboardQuickAction({
    required this.href,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String href;
  final String title;
  final String subtitle;
  final String icon;

  factory DashboardQuickAction.fromJson(Map<String, dynamic> json) =>
      DashboardQuickAction(
        href: json['href'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        icon: json['icon'] as String? ?? '',
      );
}

/// The referral summary card at the bottom of the dashboard.
class DashboardReferral {
  const DashboardReferral({
    required this.code,
    required this.shareUrl,
    required this.pending,
    required this.referrals,
  });

  final String code;
  final String shareUrl;
  final String pending;
  final int referrals;

  factory DashboardReferral.fromJson(Map<String, dynamic> json) =>
      DashboardReferral(
        code: json['code'] as String? ?? '',
        shareUrl: json['share_url'] as String? ?? '',
        pending: json['pending'] as String? ?? '\$0.00',
        referrals: (json['referrals'] as num?)?.toInt() ?? 0,
      );

  /// Maps the `GET /growth/referrals` `data` object (which nests the code/url
  /// under `referral` and the counts/earnings under `stats`) into the compact
  /// dashboard card shape.
  factory DashboardReferral.fromReferralsJson(Map<String, dynamic> data) {
    final referral =
        (data['referral'] as Map?)?.cast<String, dynamic>() ?? const {};
    final stats = (data['stats'] as Map?)?.cast<String, dynamic>() ?? const {};
    return DashboardReferral(
      code: referral['code'] as String? ?? '',
      shareUrl: referral['share_url'] as String? ?? '',
      pending: stats['to_be_paid'] as String? ?? '\$0.00',
      referrals: (stats['referrals'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A live account row used by the dashboard's equity strip, patched by WS.
class DashboardAccount {
  const DashboardAccount({
    required this.id,
    required this.currency,
    required this.equityMinor,
    required this.balanceMinor,
    required this.baselineMinor,
    this.login = '',
  });

  final int id;
  final String currency;
  final int equityMinor;
  final int balanceMinor;
  final int baselineMinor;

  /// MT5 account number. Empty when the `/dashboard` payload omits it.
  final String login;

  DashboardAccount copyWith({int? equityMinor, int? balanceMinor}) =>
      DashboardAccount(
        id: id,
        currency: currency,
        equityMinor: equityMinor ?? this.equityMinor,
        balanceMinor: balanceMinor ?? this.balanceMinor,
        baselineMinor: baselineMinor,
        login: login,
      );

  factory DashboardAccount.fromJson(Map<String, dynamic> json) {
    final baseline = (json['baseline_minor'] as num?)?.toInt() ?? 0;
    // The `/dashboard` payload often carries only `baseline_minor`; equity and
    // balance arrive later over the WebSocket. Seed both from the baseline so
    // the cards show the account's real starting figure instead of $0.00 until
    // the first live tick patches them.
    final equity = (json['equity_minor'] as num?)?.toInt() ?? 0;
    final balance = (json['balance_minor'] as num?)?.toInt() ?? 0;
    return DashboardAccount(
      id: (json['id'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      equityMinor: equity != 0 ? equity : baseline,
      balanceMinor: balance != 0 ? balance : baseline,
      baselineMinor: baseline,
      login: json['login']?.toString() ?? '',
    );
  }
}

/// A recent-trade row from the dashboard's `trades[]`.
class DashboardTrade {
  const DashboardTrade({
    required this.id,
    required this.symbol,
    required this.side,
    required this.lots,
    required this.held,
    required this.net,
  });

  final int id;
  final String symbol;
  final String side;
  final String lots;
  final String held;

  /// Formatted net P/L, e.g. `+$0.58` or `−$0.02` (note: server uses the
  /// U+2212 minus sign for losses).
  final String net;

  /// True when the net P/L is negative (server prefixes `−` U+2212 or `-`).
  bool get isLoss => net.startsWith('−') || net.startsWith('-');

  /// True when this is a buy/long trade.
  bool get isBuy => side.toLowerCase() == 'buy';

  factory DashboardTrade.fromJson(Map<String, dynamic> json) => DashboardTrade(
        id: (json['id'] as num?)?.toInt() ?? 0,
        symbol: json['symbol'] as String? ?? '',
        side: json['side'] as String? ?? '',
        lots: json['lots']?.toString() ?? '',
        held: json['held'] as String? ?? '',
        net: json['net'] as String? ?? '',
      );
}
