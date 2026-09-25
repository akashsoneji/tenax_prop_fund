import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../payout_methods/models/payout_method.dart';
import '../models/referral_models.dart';
import '../repositories/referral_repository.dart';

/// Drives the "Refer & earn" screen. Data loading (skeleton / error / empty) is
/// handled by [BaseController] via a single `DataState<ReferralData>`; this
/// class adds the copy-code / share actions and the withdraw-earnings flow
/// (payout methods + `POST /growth/referrals/withdraw`).
class ReferralController extends BaseController<ReferralData> {
  ReferralController(this._repository);

  final ReferralRepository _repository;

  // Withdraw sheet state.
  final payoutMethods = <PayoutMethod>[].obs;
  final methodsLoading = false.obs;
  final selectedMethodId = RxnString();
  final isWithdrawing = false.obs;

  @override
  Future<ApiResponse<ReferralData>> fetch() => _repository.getReferral();

  @override
  bool isEmpty(ReferralData data) => data.isEmpty;

  /// The loaded referral payload, or null while loading / on error.
  ReferralData? get _data => state.valueOrNull;

  void copyCode() {
    final code = _data?.referralCode ?? '';
    if (code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    AppToast.success('referral.code_copied'.trParams({'arg': code}));
  }

  void shareLink() {
    final url = _data?.shareUrl ?? '';
    if (url.isEmpty) return;
    Clipboard.setData(ClipboardData(text: url));
    AppToast.success('referral.link_copied'.tr);
  }

  /// Loads the saved payout methods for the withdraw sheet and keeps the
  /// current selection if it still exists, else preselects the first one.
  Future<void> loadPayoutMethods() async {
    methodsLoading.value = true;
    final res = await _repository.getPayoutMethods();
    if (isClosed) return;
    methodsLoading.value = false;
    if (!res.success || res.data == null) return;
    payoutMethods.assignAll(res.data!);
    final selectionStillValid = payoutMethods.any(
      (m) => m.id == selectedMethodId.value,
    );
    if (!selectionStillValid) {
      selectedMethodId.value = payoutMethods.isEmpty
          ? null
          : payoutMethods.first.id;
    }
  }

  void selectMethod(String id) => selectedMethodId.value = id;

  /// Validates and submits a withdrawal. Returns true when the server accepted
  /// it (the sheet then closes); the hero stats refresh in the background.
  Future<bool> withdraw(String rawAmount) async {
    if (isWithdrawing.value) return false;
    final amount = double.tryParse(rawAmount.trim());
    if (amount == null || amount <= 0) {
      AppToast.error('referral.enter_valid_amount'.tr);
      return false;
    }
    final methodId = selectedMethodId.value;
    if (methodId == null) {
      AppToast.error('referral.select_method'.tr);
      return false;
    }

    isWithdrawing.value = true;
    final res = await _repository.withdraw(
      amount: amount,
      payoutMethodId: methodId,
    );
    if (isClosed) return false;
    isWithdrawing.value = false;
    // Failures already surfaced as a toast by ApiEnvelope.
    if (!res.success) return false;

    final message = res.data ?? '';
    AppToast.success(
      message.isNotEmpty ? message : 'referral.withdraw_requested_body'.tr,
      title: 'referral.withdraw_requested'.tr,
    );
    refreshSilently();
    return true;
  }
}
