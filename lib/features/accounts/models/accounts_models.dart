// Domain models for the "My accounts" (Account Center) screen. Shapes mirror
// the web portal's Inertia payload (`component: Client/Accounts/Index`), read
// from `props`: `accounts.data[]`, `counts`, `ownedTotal`, `settlingCount`,
// `planOptions` and `trial`. Everything is display-oriented so the view binds
// directly and the controller holds a single `DataState<AccountsData>`.

/// The five status tabs shown above the account list. `completed` maps to the
/// payload's `passed` count/filter (the web labels it "Completed").
enum AccountTab { active, funded, completed, breached, all }

extension AccountTabKey on AccountTab {
  /// The `counts` key / server `tab` filter value for this tab.
  String get key {
    switch (this) {
      case AccountTab.active:
        return 'active';
      case AccountTab.funded:
        return 'funded';
      case AccountTab.completed:
        return 'passed';
      case AccountTab.breached:
        return 'breached';
      case AccountTab.all:
        return 'all';
    }
  }

  /// Translation key for the tab label.
  String get labelKey => 'accounts.tab_$name';
}

/// Per-tab totals from `props.counts` (drives the tab badges).
class AccountCounts {
  const AccountCounts({
    required this.active,
    required this.funded,
    required this.passed,
    required this.breached,
    required this.all,
  });

  final int active;
  final int funded;
  final int passed;
  final int breached;
  final int all;

  int forTab(AccountTab tab) {
    switch (tab) {
      case AccountTab.active:
        return active;
      case AccountTab.funded:
        return funded;
      case AccountTab.completed:
        return passed;
      case AccountTab.breached:
        return breached;
      case AccountTab.all:
        return all;
    }
  }

  static const empty =
      AccountCounts(active: 0, funded: 0, passed: 0, breached: 0, all: 0);

  factory AccountCounts.fromJson(Map<String, dynamic> json) => AccountCounts(
        active: _int(json['active']),
        funded: _int(json['funded']),
        passed: _int(json['passed']),
        breached: _int(json['breached']),
        all: _int(json['all']),
      );
}

/// The full payload the Account Center needs in one fetch.
class AccountsData {
  const AccountsData({
    required this.ownedTotal,
    required this.provisioning,
    required this.counts,
    required this.planOptions,
    required this.trialEnabled,
    required this.accounts,
  });

  /// TOTAL OWNED stat card.
  final int ownedTotal;

  /// PROVISIONING stat card (`settlingCount`).
  final int provisioning;

  final AccountCounts counts;

  /// Plan names for the "All plans" dropdown filter.
  final List<String> planOptions;

  /// Whether to show the "Free trial" CTA pill.
  final bool trialEnabled;

  /// Every owned account row (fetched with `tab=all` so the mobile screen can
  /// filter client-side without a refetch per tab).
  final List<AccountRow> accounts;

  bool get isEmpty => accounts.isEmpty;

  /// Parses the Inertia `props` block into the screen payload.
  factory AccountsData.fromProps(Map<String, dynamic> props) {
    final countsJson = props['counts'];
    final rows = ((props['accounts'] as Map?)?['data'] as List?) ?? const [];
    final plans = ((props['planOptions'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final trial = props['trial'];
    return AccountsData(
      ownedTotal: _int(props['ownedTotal']),
      provisioning: _int(props['settlingCount']),
      counts: countsJson is Map<String, dynamic>
          ? AccountCounts.fromJson(countsJson)
          : AccountCounts.empty,
      planOptions: plans,
      trialEnabled: trial is Map<String, dynamic>
          ? (trial['enabled'] as bool? ?? false)
          : false,
      accounts: [
        for (final raw in rows)
          if (raw is Map<String, dynamic>) AccountRow.fromJson(raw),
      ],
    );
  }
}

/// Lifecycle tone of a row — drives the status pill colour.
enum AccountTone { up, down, neutral }

/// A single account card.
class AccountRow {
  const AccountRow({
    required this.id,
    required this.login,
    required this.planName,
    required this.accountSize,
    required this.phaseLabel,
    required this.statusLabel,
    required this.tone,
    required this.tab,
    required this.balance,
    required this.equity,
    required this.pnl,
    required this.pnlNegative,
    required this.floatingNote,
    required this.tradingDays,
    required this.leverage,
    required this.started,
    required this.tradeUrl,
  });

  final int id;
  final String login;
  final String planName; // e.g. 'Pipze Free Trial'
  final String accountSize; // e.g. '$5,000'
  final String phaseLabel; // e.g. 'Trial'
  final String statusLabel; // e.g. 'Active'
  final AccountTone tone;

  /// Which tab this row belongs to (for client-side filtering).
  final AccountTab tab;

  final String balance; // e.g. '$4,999.95'
  final String equity; // e.g. '$5,099.43'
  final String pnl; // e.g. '+$99.43'
  final bool pnlNegative;
  final String floatingNote; // e.g. 'incl. +$99.48 floating'
  final String tradingDays; // e.g. '3'
  final String leverage; // e.g. '1:100 FX'
  final String started; // e.g. 'Sep 2, 2026'
  final String tradeUrl;

  factory AccountRow.fromJson(Map<String, dynamic> json) {
    final profitMinor = _int(json['profit_minor']);
    final floatingMinor = _int(json['floating_minor']);
    final lev = _int(json['leverage']);
    return AccountRow(
      id: _int(json['id']),
      login: json['login']?.toString() ?? '',
      planName: (json['plan_name'] as String?) ?? 'Account',
      accountSize: _whole(_int(json['account_size_minor'])),
      phaseLabel: (json['phase_label'] as String?) ?? '',
      statusLabel: (json['status_label'] as String?) ?? '',
      tone: _toneFrom(json['status_tone'] as String?),
      tab: _tabFrom(json['status'] as String?, json['phase'] as String?),
      balance: _strip(json['balance']) ?? _money(json['balance_minor']),
      equity: _strip(json['equity']) ?? _money(json['equity_minor']),
      pnl: _signed(profitMinor),
      pnlNegative: profitMinor < 0,
      floatingNote: floatingMinor != 0
          ? 'incl. ${_signed(floatingMinor)} floating'
          : '',
      tradingDays: _int(json['trading_days']).toString(),
      leverage: lev > 0 ? '1:$lev FX' : '—',
      started: _date(json['activated_at'] ?? json['created_at']),
      tradeUrl: (json['trade_url'] as String?) ?? '',
    );
  }

  static AccountTone _toneFrom(String? tone) {
    switch (tone) {
      case 'up':
        return AccountTone.up;
      case 'down':
        return AccountTone.down;
      default:
        return AccountTone.neutral;
    }
  }

  static AccountTab _tabFrom(String? status, String? phase) {
    switch (status) {
      case 'funded':
        return AccountTab.funded;
      case 'passed':
        return AccountTab.completed;
      case 'breached':
        return AccountTab.breached;
      case 'active':
        return AccountTab.active;
    }
    if (phase == 'funded') return AccountTab.funded;
    return AccountTab.active;
  }
}

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

/// Strips a leading currency code from a preformatted amount, e.g.
/// `'USD 4,999.95'` → `'$4,999.95'`. Returns null when [v] is not a string.
String? _strip(dynamic v) {
  if (v is! String || v.isEmpty) return null;
  final parts = v.split(' ');
  if (parts.length == 2) return '\$${parts[1]}';
  return v.startsWith('\$') ? v : '\$$v';
}

/// Formats minor units (cents) as `$1,234.56`.
String _money(dynamic minor) {
  final v = _int(minor);
  final neg = v < 0;
  final abs = (v.abs() / 100);
  final whole = abs.truncate();
  final cents = ((abs - whole) * 100).round().toString().padLeft(2, '0');
  return '${neg ? '-' : ''}\$${_group(whole)}.$cents';
}

/// Signed minor units, e.g. `+$99.43` / `-$12.00`.
String _signed(int minor) {
  final body = _money(minor.abs());
  return '${minor < 0 ? '-' : '+'}$body';
}

/// Whole-dollar amount from minor units, e.g. `500000` → `$5,000`.
String _whole(int minor) => '\$${_group((minor / 100).round())}';

/// Groups thousands with commas.
String _group(int n) {
  final digits = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats an ISO date as `Sep 2, 2026` in local time.
String _date(dynamic iso) {
  if (iso is! String || iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '';
  return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
}
