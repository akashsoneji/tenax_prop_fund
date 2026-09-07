import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/reward_models.dart';
import '../repositories/rewards_repository.dart';

/// Drives the Rewards screen + the Request-a-payout bottom sheet. Data loading
/// (skeleton / error / empty) is handled by [BaseController] via a single
/// `DataState<RewardsData>`; this class only adds the screen's UI state (the
/// sheet fields) and the derived getters. Swap the repository for the real API
/// and nothing here or in the view changes.
class RewardsController extends BaseController<RewardsData> {
  RewardsController(this._repository);

  final RewardsRepository _repository;

  // Sheet state (UI-only).
  final isSheetOpen = false.obs;
  final selectedAccountId = '100311'.obs;
  final selectedMethod = 'Bank Transfer'.obs;
  final amountController = ''.obs;

  @override
  Future<ApiResponse<RewardsData>> fetch() => _repository.getRewards();

  @override
  bool isEmpty(RewardsData data) => data.isEmpty;

  /// Number of failing requirements — drives the blocking-issues banner.
  int blockingCount(RewardsData data) =>
      data.requirements.where((r) => r.status == RequirementStatus.fail).length;

  /// Returns the currently selected account snapshot for the sheet header.
  RewardAccount? selectedAccount(RewardsData data) =>
      data.accounts.firstWhereOrNull((a) => a.id == selectedAccountId.value);

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  void openPayoutSheet() => isSheetOpen.value = true;
  void closePayoutSheet() => isSheetOpen.value = false;

  void selectAccount(String id) => selectedAccountId.value = id;
  void selectMethod(String method) => selectedMethod.value = method;
  void setAmount(String value) => amountController.value = value;

  /// Submits the payout request. Returns a [PayoutSubmitResult] so the view
  /// can show either a success toast or an inline error.
  PayoutSubmitResult submitRequest(RewardsData data) {
    final raw = amountController.value.trim();
    final parsed = double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (parsed == null || parsed <= 0) {
      return const PayoutSubmitResult.failure('Enter a valid amount.');
    }
    if (blockingCount(data) > 0) {
      return const PayoutSubmitResult.failure(
        'Complete KYC and add a payout method first.',
      );
    }
    // In a real impl, this would hit the API. We simulate a success path.
    return const PayoutSubmitResult.success();
  }
}

class PayoutSubmitResult {
  const PayoutSubmitResult.success() : isSuccess = true, message = null;
  const PayoutSubmitResult.failure(this.message) : isSuccess = false;

  final bool isSuccess;
  final String? message;
}
