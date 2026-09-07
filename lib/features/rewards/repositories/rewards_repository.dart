import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/reward_models.dart';

/// Single source of truth for rewards data. Returns static demo data so the
/// Rewards screen renders without a network call. The controller and view are
/// unchanged.
class RewardsRepository {
  RewardsRepository(this._api);

  // ignore: unused_field
  final ApiClient _api;

  Future<ApiResponse<RewardsData>> getRewards() {
    return Future.value(ApiResponse.success(_demoRewards));
  }

  static const RewardsData _demoRewards = RewardsData(
    withdrawable: MoneySnapshot(amountUsd: '\$1,250', tone: StatTone.green),
    pending: MoneySnapshot(amountUsd: '\$320', tone: StatTone.amber),
    paidOut: MoneySnapshot(amountUsd: '\$4,875', tone: StatTone.purple),
    yourShare: ShareSnapshot(percent: 80),
    requirements: [
      PayoutRequirement(
        label: 'KYC verified',
        value: 'Verified',
        status: RequirementStatus.pass,
      ),
      PayoutRequirement(
        label: 'Payout method saved',
        value: 'Saved',
        status: RequirementStatus.pass,
      ),
      PayoutRequirement(
        label: 'Minimum payout',
        value: '\$50',
        status: RequirementStatus.pass,
      ),
    ],
    accounts: [
      RewardAccount(
        id: '1',
        label: '#2000000 · funded',
        status: AccountStatus.funded,
      ),
      RewardAccount(
        id: '2',
        label: '#2000042 · evaluation',
        status: AccountStatus.evaluation,
      ),
    ],
    payoutMethods: ['Bank Transfer', 'Crypto (USDT)'],
  );
}
