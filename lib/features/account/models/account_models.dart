// Domain models for the Account detail screen (mobile take on the web
// `Client/Accounts/Overview|Platform|Reset` pages). Three Inertia endpoints
// back four tabs:
//  - Account overview + Trading overview → /app/accounts/overview?account=&tab=
//  - Platform & credentials              → /app/accounts/platform?account=
//  - Reset account                       → /app/accounts/reset?account=
// Everything is display-oriented so the view binds directly.

/// Status tone of the account (drives the pill colour).
enum AccountTone { up, down, neutral }

AccountTone _toneFrom(String? tone) {
  switch (tone) {
    case 'up':
      return AccountTone.up;
    case 'down':
    case 'warn':
      return AccountTone.down;
    default:
      return AccountTone.neutral;
  }
}

/// The Account-overview payload (also carries the Trading-overview data, since
/// both come from the same endpoint with a different `tab`).
class AccountData {
  const AccountData({
    required this.header,
    required this.credentials,
    required this.cycle,
    required this.stats,
    required this.objectives,
    required this.health,
    required this.addonReason,
    required this.tradeUrl,
    required this.options,
    required this.trades,
    required this.insights,
  });

  final AccountHeader header;
  final AccountCredentials credentials;
  final AccountCycle cycle;
  final List<AccountStat> stats;
  final List<AccountObjective> objectives;
  final List<AccountHealth> health;

  /// Add-ons availability note (empty when purchasable).
  final String addonReason;
  final String tradeUrl;

  /// Other accounts for the switcher dropdown.
  final List<AccountOption> options;

  /// Trading-overview tab.
  final List<AccountTrade> trades;
  final AccountInsights insights;

  bool get isEmpty => false;

  factory AccountData.fromProps(Map<String, dynamic> props) {
    final account = _map(props['account']);
    final stats = _map(account['stats']);
    final overview = _map(props['overview']);
    final cycle = _map(overview['cycle']);
    final stat4 = _map(overview['stat4']);
    final credentials = _map(props['credentials']);
    final tradesData = (_map(props['trades'])['data'] as List?) ?? const [];
    final profitMinor = (stat4['profit_minor'] as num?)?.toInt() ??
        (stats['profit_minor'] as num?)?.toInt() ??
        0;
    final floatingMinor = (stat4['floating_minor'] as num?)?.toInt() ?? 0;

    return AccountData(
      header: AccountHeader(
        login: account['login']?.toString() ?? '',
        statusLabel: account['status_label'] as String? ?? '',
        tone: _toneFrom(account['status_tone'] as String?),
        planLabel: overview['plan_label'] as String? ??
            account['plan_name'] as String? ??
            '',
        phaseLabel: overview['phase_label'] as String? ?? '',
        initialBalance: overview['initial_balance'] as String? ?? '',
        leverage: (overview['leverage'] as num?)?.toInt() ??
            (account['leverage'] as num?)?.toInt() ??
            0,
        drawdownType: overview['drawdown_type'] as String? ?? '',
        accountType: overview['account_type'] as String? ??
            account['account_type'] as String? ??
            '',
      ),
      credentials: AccountCredentials.fromJson(credentials),
      cycle: AccountCycle.fromJson(cycle),
      stats: [
        AccountStat(
          label: 'account.balance',
          value: _strip(stats['balance']) ?? '',
          tone: AccountTone.neutral,
          icon: AccountStatIcon.dollar,
        ),
        AccountStat(
          label: 'account.profit_loss',
          value: _signedMinor(profitMinor),
          tone: profitMinor < 0 ? AccountTone.down : AccountTone.up,
          icon: AccountStatIcon.chart,
        ),
        AccountStat(
          label: 'account.floating_pl',
          value: _signedMinor(floatingMinor),
          tone: floatingMinor < 0 ? AccountTone.down : AccountTone.up,
          icon: AccountStatIcon.activity,
        ),
        AccountStat(
          label: 'account.trading_days',
          value: '${stat4['trading_days'] ?? stats['trading_days'] ?? 0}',
          tone: AccountTone.neutral,
          icon: AccountStatIcon.calendar,
        ),
      ],
      objectives: [
        for (final c in (overview['objective_cards'] as List?) ?? const [])
          if (c is Map<String, dynamic>) AccountObjective.fromJson(c),
      ],
      health: [
        for (final h in (overview['health'] as List?) ?? const [])
          if (h is Map<String, dynamic>) AccountHealth.fromJson(h),
      ],
      addonReason: _map(props['addonShop'])['reason'] as String? ?? '',
      tradeUrl: props['tradeUrl'] as String? ?? '',
      options: [
        for (final o in (props['accountOptions'] as List?) ?? const [])
          if (o is Map<String, dynamic>) AccountOption.fromJson(o),
      ],
      trades: [
        for (final t in tradesData)
          if (t is Map<String, dynamic>) AccountTrade.fromJson(t),
      ],
      insights: AccountInsights.fromJson(_map(props['insights'])),
    );
  }
}

/// Header facts checklist + status.
class AccountHeader {
  const AccountHeader({
    required this.login,
    required this.statusLabel,
    required this.tone,
    required this.planLabel,
    required this.phaseLabel,
    required this.initialBalance,
    required this.leverage,
    required this.drawdownType,
    required this.accountType,
  });

  final String login;
  final String statusLabel;
  final AccountTone tone;
  final String planLabel;
  final String phaseLabel;
  final String initialBalance;
  final int leverage;
  final String drawdownType;
  final String accountType;

  String get leverageLabel => leverage > 0 ? '1:$leverage' : '—';
}

/// Login / server / passwords (passwords arrive masked).
class AccountCredentials {
  const AccountCredentials({
    required this.login,
    required this.server,
    required this.password,
    required this.investorPassword,
    required this.platform,
    required this.accountType,
  });

  final String login;
  final String server;
  final String password;
  final String investorPassword;
  final String platform;
  final String accountType;

  factory AccountCredentials.fromJson(Map<String, dynamic> json) =>
      AccountCredentials(
        login: json['login']?.toString() ?? '',
        server: json['server'] as String? ?? '',
        password: json['password'] as String? ?? '',
        investorPassword: json['investor_password'] as String? ?? '',
        platform: json['platform'] as String? ?? 'Pipze Self-Hosted Engine',
        accountType: json['account_type'] as String? ?? '',
      );
}

/// Cycle details (phase started / days elapsed / time limit / next reward).
class AccountCycle {
  const AccountCycle({
    required this.phaseStarted,
    required this.daysElapsed,
    required this.timeLimit,
    required this.nextReward,
  });

  final String phaseStarted;
  final int daysElapsed;
  final String timeLimit;
  final String nextReward;

  factory AccountCycle.fromJson(Map<String, dynamic> json) => AccountCycle(
        phaseStarted: _date(json['phase_started']),
        daysElapsed: (json['days_elapsed'] as num?)?.toInt() ?? 0,
        timeLimit: json['time_limit'] as String? ?? '—',
        nextReward: json['next_reward'] as String? ?? '—',
      );
}

enum AccountStatIcon { dollar, chart, activity, calendar }

/// A KPI stat card in the overview strip.
class AccountStat {
  const AccountStat({
    required this.label,
    required this.value,
    required this.tone,
    required this.icon,
  });

  final String label; // translation key
  final String value;
  final AccountTone tone;
  final AccountStatIcon icon;
}

/// One trading objective card (label + status + detail lines).
class AccountObjective {
  const AccountObjective({
    required this.label,
    required this.status,
    required this.lines,
  });

  final String label;
  final String status; // Ongoing / Passed / Failed
  final List<String> lines;

  bool get passed => status.toLowerCase() == 'passed';

  factory AccountObjective.fromJson(Map<String, dynamic> json) =>
      AccountObjective(
        label: json['label'] as String? ?? '',
        status: json['status'] as String? ?? '',
        lines: [
          for (final l in (json['lines'] as List?) ?? const [])
            if (l is String) l,
        ],
      );
}

/// An account-health row (Consistency / Quick strike / Hyperactivity).
class AccountHealth {
  const AccountHealth({
    required this.name,
    required this.status,
    required this.note,
  });

  final String name;
  final String status; // Watch / Pass
  final String note;

  bool get watch => status.toLowerCase() == 'watch';

  factory AccountHealth.fromJson(Map<String, dynamic> json) => AccountHealth(
        name: json['name'] as String? ?? '',
        status: json['status'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );
}

/// An account in the switcher dropdown.
class AccountOption {
  const AccountOption({
    required this.id,
    required this.login,
    required this.label,
  });

  final int id;
  final String login;
  final String label;

  factory AccountOption.fromJson(Map<String, dynamic> json) => AccountOption(
        id: (json['id'] as num?)?.toInt() ?? 0,
        login: json['login']?.toString() ?? '',
        label: json['label'] as String? ?? '',
      );
}

/// One closed trade row (Trading overview tab).
class AccountTrade {
  const AccountTrade({
    required this.symbol,
    required this.side,
    required this.volume,
    required this.openPrice,
    required this.closePrice,
    required this.profit,
    required this.profitNegative,
    required this.closedAt,
  });

  final String symbol;
  final String side; // buy / sell
  final String volume;
  final String openPrice;
  final String closePrice;
  final String profit;
  final bool profitNegative;
  final String closedAt;

  bool get isBuy => side.toLowerCase() == 'buy';

  factory AccountTrade.fromJson(Map<String, dynamic> json) {
    final profitMinor = (json['profit_minor'] as num?)?.toInt() ?? 0;
    return AccountTrade(
      symbol: json['symbol'] as String? ?? '',
      side: json['side'] as String? ?? '',
      volume: json['volume']?.toString() ?? '',
      openPrice: json['open_price']?.toString() ?? '',
      closePrice: json['close_price']?.toString() ?? '',
      profit: _strip(json['profit']) ?? _signedMinor(profitMinor),
      profitNegative: profitMinor < 0,
      closedAt: _dateTime(json['closed_at']),
    );
  }
}

/// Trading insights (metric tiles + win/loss counts).
class AccountInsights {
  const AccountInsights({required this.metrics, required this.won, required this.lost});

  final List<AccountMetric> metrics;
  final int won;
  final int lost;

  factory AccountInsights.fromJson(Map<String, dynamic> json) {
    final winloss = (_map(json['graphs'])['winloss'] as List?) ?? const [];
    int pick(String label) {
      for (final w in winloss) {
        if (w is Map && (w['label'] as String?) == label) {
          return (w['value'] as num?)?.toInt() ?? 0;
        }
      }
      return 0;
    }

    return AccountInsights(
      metrics: [
        for (final m in (json['mets'] as List?) ?? const [])
          if (m is Map<String, dynamic>) AccountMetric.fromJson(m),
      ],
      won: pick('Won'),
      lost: pick('Lost'),
    );
  }
}

/// A single insight metric tile.
class AccountMetric {
  const AccountMetric({required this.label, required this.value, required this.tone});

  final String label;
  final String value;
  final AccountTone tone;

  factory AccountMetric.fromJson(Map<String, dynamic> json) => AccountMetric(
        label: json['label'] as String? ?? '',
        value: json['value']?.toString() ?? '',
        tone: _toneFrom(json['tone'] as String?),
      );
}

// ---------------------------------------------------------------------------
// Platform tab
// ---------------------------------------------------------------------------
class PlatformData {
  const PlatformData({
    required this.credentials,
    required this.statusLabel,
    required this.tone,
    required this.downloads,
    required this.webTerminal,
    required this.locked,
  });

  final AccountCredentials credentials;
  final String statusLabel;
  final AccountTone tone;
  final List<PlatformDownload> downloads;
  final String webTerminal;
  final bool locked;

  factory PlatformData.fromProps(Map<String, dynamic> props) {
    final account = _map(props['account']);
    return PlatformData(
      credentials: AccountCredentials.fromJson(_map(props['credentials'])),
      statusLabel: account['status_label'] as String? ?? '',
      tone: _toneFrom(account['status_tone'] as String?),
      downloads: [
        for (final d in (props['downloads'] as List?) ?? const [])
          if (d is Map<String, dynamic>) PlatformDownload.fromJson(d),
      ],
      webTerminal: props['webTerminal'] as String? ?? '',
      locked: props['platformLocked'] as bool? ?? false,
    );
  }
}

class PlatformDownload {
  const PlatformDownload({
    required this.label,
    required this.note,
    required this.href,
  });

  final String label;
  final String note;
  final String href;

  factory PlatformDownload.fromJson(Map<String, dynamic> json) =>
      PlatformDownload(
        label: json['label'] as String? ?? '',
        note: json['note'] as String? ?? '',
        href: json['href'] as String? ?? '',
      );
}

// ---------------------------------------------------------------------------
// Reset tab
// ---------------------------------------------------------------------------
class ResetData {
  const ResetData({
    required this.login,
    required this.initialBalance,
    required this.percentLabel,
    required this.originalFee,
    required this.resetPrice,
    required this.validUntil,
    required this.message,
    required this.eligible,
    required this.quotable,
  });

  final String login;
  final String initialBalance;
  final String percentLabel; // e.g. '50% price'
  final String originalFee;
  final String resetPrice;
  final String validUntil;
  final String message;
  final bool eligible;
  final bool quotable;

  factory ResetData.fromProps(Map<String, dynamic> props) {
    final account = _map(props['account']);
    final quote = _map(props['quote']);
    final percent = (quote['percent'] as num?)?.toInt() ?? 0;
    return ResetData(
      login: account['login']?.toString() ?? '',
      initialBalance: _whole(
          (account['account_size_minor'] as num?)?.toInt() ?? 0),
      percentLabel: percent > 0 ? '$percent% price' : '',
      originalFee: _strip(quote['original']) ?? '\$0',
      resetPrice: _strip(quote['amount']) ?? '\$0',
      validUntil: quote['valid_until_label'] as String? ?? '',
      message: quote['message'] as String? ?? '',
      eligible: quote['eligible'] as bool? ?? false,
      quotable: quote['quotable'] as bool? ?? false,
    );
  }
}

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------
Map<String, dynamic> _map(dynamic v) =>
    v is Map<String, dynamic> ? v : const {};

/// Strips a leading currency code from a preformatted amount, e.g.
/// `'USD 4,999.95'` → `'$4,999.95'`.
String? _strip(dynamic v) {
  if (v is! String || v.isEmpty) return null;
  final parts = v.split(' ');
  if (parts.length == 2) {
    final neg = parts[1].startsWith('-');
    final body = neg ? parts[1].substring(1) : parts[1];
    return '${neg ? '-' : ''}\$$body';
  }
  return v.startsWith('\$') ? v : '\$$v';
}

/// Signed minor units, e.g. `+$99.43` / `-$12.00`.
String _signedMinor(int minor) {
  final abs = (minor.abs() / 100).toStringAsFixed(2);
  final grouped = _groupDecimal(abs);
  return '${minor < 0 ? '-' : '+'}\$$grouped';
}

/// Whole-dollar amount from minor units, e.g. `500000` → `$5,000`.
String _whole(int minor) {
  final digits = (minor / 100).round().toString();
  return '\$${_group(digits)}';
}

String _group(String digits) {
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}

String _groupDecimal(String amount) {
  final parts = amount.split('.');
  return '${_group(parts[0])}.${parts.length > 1 ? parts[1] : '00'}';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _date(dynamic iso) {
  if (iso is! String || iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '';
  return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

String _dateTime(dynamic iso) {
  if (iso is! String || iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '';
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '${_months[dt.month - 1]} ${dt.day} · $h:$m';
}
