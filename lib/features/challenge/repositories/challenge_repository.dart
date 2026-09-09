import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/challenge_models.dart';

/// Single source of truth for Choose-a-challenge data. Returns a static demo
/// catalogue — no network call. The controller and view do not change — that
/// is the point of this layer. [_api] is kept for constructor compatibility.
class ChallengeRepository {
  ChallengeRepository(this._api);

  // ignore: unused_field
  final ApiClient _api;

  Future<ApiResponse<ChallengeData>> getPlans({String currency = 'USD'}) =>
      Future.value(ApiResponse.success(_demoData));

  static const ChallengeData _demoData = ChallengeData(
    plans: [
      ChallengePlan(
        size: '\$5K',
        price: '\$49',
        original: '\$59',
        discountLabel: '17% OFF',
      ),
      ChallengePlan(
        size: '\$10K',
        price: '\$89',
        original: '\$99',
        discountLabel: '10% OFF',
      ),
      ChallengePlan(
        size: '\$25K',
        price: '\$189',
        original: '',
        discountLabel: '',
      ),
      ChallengePlan(
        size: '\$50K',
        price: '\$289',
        original: '\$339',
        discountLabel: '15% OFF',
      ),
      ChallengePlan(
        size: '\$100K',
        price: '\$489',
        original: '',
        discountLabel: '',
      ),
      ChallengePlan(
        size: '\$200K',
        price: '\$889',
        original: '\$999',
        discountLabel: '11% OFF',
      ),
    ],
    challengeRules: [
      ChallengeRule('Profit target', '8%'),
      ChallengeRule('Max daily loss', '5%'),
      ChallengeRule('Max overall loss', '10%'),
      ChallengeRule('Min trading days', '5 days'),
    ],
    fundedRules: [
      ChallengeRule('Profit split', 'Up to 90%'),
      ChallengeRule('Max daily loss', '5%'),
      ChallengeRule('Max overall loss', '10%'),
      ChallengeRule('Payout cycle', '14 days'),
    ],
    trialRules: [
      ChallengeRule('Profit target', 'None'),
      ChallengeRule('Duration', '7 days'),
      ChallengeRule('Max daily loss', '5%'),
      ChallengeRule('Max overall loss', '10%'),
    ],
  );
}
