import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/reward_models.dart';
import '../repositories/rewards_repository.dart';

/// Drives the Rewards screen + the Request-a-payout bottom sheet.
class RewardsController extends BaseController<RewardsData> {
  RewardsController(this._repository);

  final RewardsRepository _repository;

  // Sheet state (UI-only).
  final isSheetOpen = false.obs;
  final selectedAccountId = RxnString();
  final selectedMethod = RxnString();
  final amountController = ''.obs;
  final isSubmitting = false.obs;

  @override
  Future<ApiResponse<RewardsData>> fetch() async {
    final response = await _repository.getRewards();
    final data = response.data;
    if (data != null) {
      if (data.payoutMethods.isNotEmpty) {
        selectedMethod.value ??= data.payoutMethods.first.id;
      }
    }
    return response;
  }

  @override
  bool isEmpty(RewardsData data) => data.isEmpty;

  int blockingCount(RewardsData data) =>
      data.requirements.where((r) => r.status == RequirementStatus.fail).length;

  RewardAccount? selectedAccount(RewardsData data) =>
      data.accounts.firstWhereOrNull((a) => a.id == selectedAccountId.value);

  void openPayoutSheet() => isSheetOpen.value = true;
  void closePayoutSheet() => isSheetOpen.value = false;

  /// `null` = "None" (the request is not tied to a trading account).
  void selectAccount(String? id) => selectedAccountId.value = id;
  void selectMethod(String method) => selectedMethod.value = method;
  void setAmount(String value) => amountController.value = value;

  Future<PayoutSubmitResult> submitRequest(
    RewardsData data, {
    String? notes,
    String? password,
  }) async {
    final raw = amountController.value.trim();
    final parsed = double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), ''));
    final methodId = selectedMethod.value;
    if (parsed == null || parsed <= 0) {
      return PayoutSubmitResult.invalid('rewards.err_amount_invalid'.tr);
    }
    final amountMinor = (parsed * 100).round();
    if (amountMinor < data.minPayoutMinor) {
      return PayoutSubmitResult.invalid(
        'rewards.err_amount_min'.trParams({'min': data.minPayout}),
      );
    }
    if (amountMinor > data.availableMinor) {
      return PayoutSubmitResult.invalid(
        'rewards.err_amount_max'
            .trParams({'max': data.withdrawable.amountUsd}),
      );
    }
    if (methodId == null) {
      return PayoutSubmitResult.invalid('rewards.err_method_required'.tr);
    }
    if (isSubmitting.value) {
      return const PayoutSubmitResult.invalid(null);
    }

    isSubmitting.value = true;
    try {
      final response = await _repository.requestPayout(
        amount: parsed,
        currency: 'USD',
        payoutMethodId: methodId,
        // Optional on the web form — "None" leaves it off the request.
        tradingAccountId: selectedAccountId.value,
        notes: notes?.trim(),
        currentPassword: password,
      );
      if (response.success) load();
      return response.success
          ? const PayoutSubmitResult.success()
          : PayoutSubmitResult.failure(response.message);
    } finally {
      isSubmitting.value = false;
    }
  }
}

class PayoutSubmitResult {
  const PayoutSubmitResult.success()
      : isSuccess = true,
        isLocalValidation = false,
        message = null;

  /// The server rejected the request (its message is already toasted by
  /// ApiEnvelope.guard).
  const PayoutSubmitResult.failure(this.message)
      : isSuccess = false,
        isLocalValidation = false;

  /// Rejected before any request was sent — the user can fix the form.
  const PayoutSubmitResult.invalid(this.message)
      : isSuccess = false,
        isLocalValidation = true;

  final bool isSuccess;
  final bool isLocalValidation;
  final String? message;
}

// ---------------------------------------------------------------------------
// Payout history state (mutable — Rx.update mutates fields directly)
// ---------------------------------------------------------------------------

class PayoutHistoryState {
  PayoutHistoryState({
    required this.items,
    required this.filter,
    required this.page,
    required this.totalPages,
    required this.hasNext,
    this.error,
  });

  List<PayoutHistoryItem> items;
  String filter;
  int page;
  int totalPages;
  bool hasNext;
  String? error;
}

// ---------------------------------------------------------------------------
// "Add method" form state (mutable)
// ---------------------------------------------------------------------------

class MethodFormState {
  MethodFormState({
    this.selectedTypeValue,
    this.selectedType,
    this.details = const <String, String>{},
    this.label = '',
    this.network = '',
    this.accountAddress = '',
    this.memo = '',
    this.upiId = '',
    this.accountHolder = '',
    this.bankName = '',
    this.accountName = '',
    this.accountNumber = '',
    this.swiftIfsc = '',
  });

  String? selectedTypeValue;
  PayoutMethodType? selectedType;
  Map<String, String> details;
  String label;
  String network;
  String accountAddress;
  String memo;
  String upiId;
  String accountHolder;
  String bankName;
  String accountName;
  String accountNumber;
  String swiftIfsc;
}

// ---------------------------------------------------------------------------
// Extended controller for method CRUD, history, cancel
// ---------------------------------------------------------------------------

class ExtendedRewardsController extends GetxController {
  ExtendedRewardsController(this._repository);

  final RewardsRepository _repository;

  // method types
  final methodTypes = <PayoutMethodType>[].obs;
  final methodTypesLoading = false.obs;
  final methodTypesError = RxnString();

  // add/edit form
  final formState = MethodFormState().obs;
  final isMethodSubmitting = false.obs;
  final editingMethodId = RxnInt();

  // cancel confirm
  final cancelConfirmId = RxnInt();
  final cancelPassword = ''.obs;

  // history
  final history = Rxn<PayoutHistoryState>();

  @override
  void onInit() {
    super.onInit();
    history.value = PayoutHistoryState(
      items: <PayoutHistoryItem>[],
      filter: 'all',
      page: 1,
      totalPages: 1,
      hasNext: false,
    );
    loadMethodTypes();
  }

  Future<void> loadMethodTypes() async {
    methodTypesLoading.value = true;
    methodTypesError.value = null;
    try {
      final result = await _repository.getMethodTypes();
      if (result.success && result.data != null) {
        methodTypes.assignAll(result.data!.methodTypes);
        if (methodTypes.isNotEmpty) {
          final first = methodTypes.first;
          formState.update((val) {
            if (val != null) {
              val.selectedTypeValue = first.value;
              val.selectedType = first;
            }
          });
        }
      } else {
        methodTypesError.value =
            result.message ?? 'errors.load_failed'.tr;
      }
    } finally {
      methodTypesLoading.value = false;
    }
  }

  void selectMethodType(String? value) {
    final type = methodTypes.firstWhereOrNull((t) => t.value == value);
    formState.update((val) {
      if (val != null) {
        val.selectedTypeValue = value;
        val.selectedType = type;
      }
    });
  }

  void resetForm() {
    editingMethodId.value = null;
    formState.value = MethodFormState();
    if (methodTypes.isNotEmpty) {
      final first = methodTypes.first;
      formState.update((val) {
        if (val != null) {
          val.selectedTypeValue = first.value;
          val.selectedType = first;
        }
      });
    }
  }

  Map<String, dynamic> buildDetails(MethodFormState form) {
    final type = form.selectedTypeValue;
    final details = <String, dynamic>{};
    if (type == 'bank') {
      if (form.bankName.isNotEmpty) details['bank_name'] = form.bankName;
      if (form.accountName.isNotEmpty) {
        details['account_name'] = form.accountName;
      }
      if (form.accountNumber.isNotEmpty) {
        details['account_number'] = form.accountNumber;
      }
      if (form.swiftIfsc.isNotEmpty) details['swift_ifsc'] = form.swiftIfsc;
    } else if (type == 'usdt' || type == 'crypto') {
      if (form.network.isNotEmpty) details['network'] = form.network;
      if (form.accountAddress.isNotEmpty) {
        details['address'] = form.accountAddress;
      }
      if (form.memo.isNotEmpty) details['memo'] = form.memo;
    } else if (type == 'upi') {
      if (form.upiId.isNotEmpty) details['upi_id'] = form.upiId;
      if (form.accountHolder.isNotEmpty) {
        details['account_holder'] = form.accountHolder;
      }
    }
    if (details.isEmpty && form.details.isNotEmpty) {
      details.addAll(form.details);
    }
    return details;
  }

  Future<ApiResponse<void>> submitMethod() async {
    if (isMethodSubmitting.value) {
      return ApiResponse.failure('errors.request_in_progress'.tr);
    }
    isMethodSubmitting.value = true;
    try {
      final details = buildDetails(formState.value);
      if (editingMethodId.value != null) {
        final result = await _repository.updateMethod(
          methodId: editingMethodId.value!,
          label:
              formState.value.label.isEmpty ? null : formState.value.label,
          details: details.isEmpty ? null : details,
        );
        if (result.success) resetForm();
        return result;
      } else {
        final result = await _repository.createMethod(
          type: formState.value.selectedTypeValue ?? 'bank',
          label: formState.value.label.isEmpty
              ? 'Payout method'
              : formState.value.label,
          currency: 'USD',
          details: details,
        );
        if (result.success) resetForm();
        return result;
      }
    } finally {
      isMethodSubmitting.value = false;
    }
  }

  void startEditMethod(RewardPayoutMethod method) {
    editingMethodId.value = int.tryParse(method.id);
    formState.update((val) {
      if (val != null) {
        val.label = method.label;
      }
    });
  }

  Future<ApiResponse<void>> deleteMethod(String methodId) async {
    final id = int.tryParse(methodId);
    if (id == null) return ApiResponse.failure('errors.invalid_method'.tr);
    return await _repository.deleteMethod(id);
  }

  Future<void> loadHistory({String status = 'all', int page = 1}) async {
    final result = await _repository.getRewards(status: status, page: page);
    if (result.success && result.data != null) {
      final h = history.value;
      history.value = PayoutHistoryState(
        items: h?.items ?? <PayoutHistoryItem>[],
        filter: status,
        page: page,
        totalPages: h?.totalPages ?? 1,
        hasNext: h?.hasNext ?? false,
      );
    } else {
      final h = history.value;
      history.value = PayoutHistoryState(
        items: h?.items ?? <PayoutHistoryItem>[],
        filter: status,
        page: page,
        totalPages: h?.totalPages ?? 1,
        hasNext: h?.hasNext ?? false,
        error: result.message ?? 'positions.history_error'.tr,
      );
    }
  }

  void setHistoryFilter(String status) {
    history.value = PayoutHistoryState(
      items: <PayoutHistoryItem>[],
      filter: status,
      page: 1,
      totalPages: 1,
      hasNext: false,
    );
    loadHistory(status: status, page: 1);
  }

  Future<void> loadNextHistoryPage() async {
    final current = history.value;
    if (current == null) return;
    if (!current.hasNext || current.page >= current.totalPages) return;
    await loadHistory(status: current.filter, page: current.page + 1);
  }

  Future<ApiResponse<void>> cancelPayout(int payoutId, {String? password}) async {
    return await _repository.cancelPayout(payoutId);
  }

  void confirmCancel(int payoutId) {
    cancelConfirmId.value = payoutId;
    cancelPassword.value = '';
  }

  void dismissCancel() {
    cancelConfirmId.value = null;
    cancelPassword.value = '';
  }
}
