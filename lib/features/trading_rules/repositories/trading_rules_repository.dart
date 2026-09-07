import '../../../core/network/api_response.dart';
import '../models/rules_models.dart';

/// Single source of truth for Trading Rules data. Today it returns demo data
/// after a short delay to simulate the network; when the API lands, replace the
/// body of [getRules] with an `ApiClient` call + `fromJson`. The controller and
/// view do not change when that swap happens — that is the point of this layer.
class TradingRulesRepository {
  Future<ApiResponse<TradingRulesData>> getRules() async {
    try {
      // Simulated network latency so the shimmer is visible during development.
      await Future<void>.delayed(const Duration(milliseconds: 900));

      const data = TradingRulesData(
        closingRules: _closingRules,
        closingTip: _closingTip,
        canDoRows: _canDoRows,
        delayRows: _delayRows,
        planRows: _planRows,
      );
      return ApiResponse.success(data);
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

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
