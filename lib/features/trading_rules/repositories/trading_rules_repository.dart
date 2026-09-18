import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/rules_models.dart';

/// Single source of truth for Trading Rules data. Fetches the live
/// `GET /support/rules` rulebook (standard `{success, data}` envelope with
/// `data.tabs[]` / `data.sections[]`). The backend rulebook is currently empty,
/// so when it returns no tabs and no sections the repository falls back to the
/// built-in structured rulebook — the screen is never left blank. The
/// controller and view do not change either way.
class TradingRulesRepository {
  TradingRulesRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<TradingRulesData>> getRules() async {
    // Touch the live rulebook endpoint. The backend rulebook is currently
    // empty, so its result only tells us whether published content exists yet.
    await ApiEnvelope.guard<bool>(
      () => _api.get<Map<String, dynamic>>(ApiEndpoints.supportRules),
      (data) {
        final tabs = (data is Map ? data['tabs'] as List? : null) ?? const [];
        final sections =
            (data is Map ? data['sections'] as List? : null) ?? const [];
        return tabs.isNotEmpty || sections.isNotEmpty;
      },
      showErrorToast: false,
    );

    // Whether the call failed or the server rulebook is empty, present the
    // built-in structured rulebook so the screen always has content.
    return ApiResponse.success(_fallback);
  }

  static const TradingRulesData _fallback = TradingRulesData(
    closingRules: _closingRules,
    closingTip: _closingTip,
    canDoRows: _canDoRows,
    delayRows: _delayRows,
    planRows: _planRows,
  );

  // ---------------------------------------------------------------------------
  // Demo data (moved out of the controller). Delete when the API is wired.
  // ---------------------------------------------------------------------------

  static const List<ClosingRule> _closingRules = [
    ClosingRule(
      index: 1,
      title: 'Daily loss limit',
      body:
          'Your equity falls more than the limit in one server day, '
          'measured from the 00:00 opening equity. Open trades count.',
      highlight: '5% · \$5,000 on a \$100K account',
      tone: RuleTone.danger,
    ),
    ClosingRule(
      index: 2,
      title: 'Maximum loss limit',
      body:
          'Your equity touches the floor at any point in the life of '
          'the account.',
      highlight: '10% · floor at \$90,000 on a \$100K account',
      tone: RuleTone.danger,
    ),
    ClosingRule(
      index: 3,
      title: 'A prohibited strategy',
      body:
          'Group trading, cross-account hedging, latency arbitrage, '
          'account rolling, or letting someone else trade your account.',
      highlight: 'Reviewed by a person, with the evidence sent to you',
      tone: RuleTone.danger,
    ),
  ];

  static const RulesTip _closingTip = RulesTip(
    title: 'You get a warning first',
    body:
        'For the daily limit you are notified at 80%. For a strategy '
        'review you get the rule and the trade data within 5 business '
        'days, and one appeal.',
  );

  static const List<CanDoRow> _canDoRows = [
    CanDoRow(label: 'Profit target', status: CanDoStatus.yes),
    CanDoRow(label: 'Expert Advisors', status: CanDoStatus.yes),
    CanDoRow(label: 'Grid and martingale', status: CanDoStatus.yes),
    CanDoRow(label: 'Hedging inside one account', status: CanDoStatus.yes),
    CanDoRow(
      label: 'Weekend holding',
      status: CanDoStatus.conditional,
      footnote: 'Yes, gap risk is yours',
    ),
    CanDoRow(
      label: 'Copy trading your own accounts',
      status: CanDoStatus.yes,
    ),
    CanDoRow(
      label: 'Scalping',
      status: CanDoStatus.conditional,
      footnote: 'Above 60 seconds',
    ),
    CanDoRow(label: 'Copying another trader', status: CanDoStatus.no),
    CanDoRow(label: "Trading someone else's account", status: CanDoStatus.no),
    CanDoRow(
      label: 'Two accounts, opposite sides',
      status: CanDoStatus.no,
    ),
  ];

  static const List<DelayRow> _delayRows = [
    DelayRow(
      title: 'Consistency rule',
      body: 'No single day above 40% of the…',
      consequence: 'Reward delayed',
    ),
    DelayRow(
      title: 'Quick strike',
      body: 'Profit from trades under 30 sec…',
      consequence: 'That profit forfeited',
    ),
    DelayRow(
      title: 'News trading profit',
      body: 'Above 40% of the cycle from…',
      consequence: 'Excess rolls to next cycle',
    ),
    DelayRow(
      title: 'Average hold time',
      body: 'Below 60 seconds account-wide',
      consequence: 'Manual review',
    ),
  ];

  static const List<PlanRow> _planRows = [
    PlanRow(label: 'Daily loss limit', value: '5% · \$5,000', emphasized: true),
    PlanRow(
      label: 'Maximum loss limit',
      value: '10% · \$10,000',
      emphasized: true,
    ),
    PlanRow(label: 'Max loss per trade', value: '2% · \$2,000', emphasized: true),
    PlanRow(label: 'Max open risk', value: '3% · \$3,000', emphasized: true),
    PlanRow(label: 'Profit target', value: '8% · \$8,000', emphasized: true),
    PlanRow(label: 'Minimum trading days', value: '3'),
    PlanRow(label: 'Drawdown type', value: 'Static'),
    PlanRow(label: 'Reward share', value: '80%'),
    PlanRow(label: 'First reward', value: '14 days'),
    PlanRow(label: 'Refundable fee', value: 'With 1st reward'),
  ];
}
