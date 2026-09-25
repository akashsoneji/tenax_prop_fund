import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/method_type.dart';
import '../models/payout_method.dart';
import '../repositories/payout_methods_repository.dart';

/// Drives the Payout methods list plus the add/edit sheet (method types,
/// create, update, delete). Every mutation reloads the list on success.
class PayoutMethodsController extends BaseController<List<PayoutMethod>> {
  PayoutMethodsController(this._repository);

  final PayoutMethodsRepository _repository;
  final isSubmitting = false.obs;

  final methodTypes = <MethodType>[].obs;
  final isLoadingMethodTypes = false.obs;

  @override
  Future<ApiResponse<List<PayoutMethod>>> fetch() =>
      _repository.getPayoutMethods();

  @override
  bool isEmpty(List<PayoutMethod> data) => data.isEmpty;

  /// Loads the rails once; later calls reuse the cached list.
  Future<void> loadMethodTypes() async {
    if (methodTypes.isNotEmpty || isLoadingMethodTypes.value) return;
    isLoadingMethodTypes.value = true;
    try {
      final result = await _repository.getMethodTypes();
      if (result.success && result.data != null) {
        methodTypes.assignAll(result.data!);
      }
    } finally {
      isLoadingMethodTypes.value = false;
    }
  }

  Future<ApiResponse<void>> createMethod({
    required String type,
    required String label,
    required String currency,
    required Map<String, dynamic> details,
  }) {
    return _mutate(() => _repository.createPayoutMethod(
          type: type,
          label: label,
          currency: currency,
          details: details,
        ));
  }

  Future<ApiResponse<void>> updateMethod({
    required String id,
    required String type,
    required String label,
    required String currency,
    required Map<String, dynamic> details,
  }) {
    return _mutate(() => _repository.updatePayoutMethod(
          id: id,
          type: type,
          label: label,
          currency: currency,
          details: details,
        ));
  }

  Future<ApiResponse<void>> deleteMethod(String id) {
    return _mutate(() => _repository.deletePayoutMethod(id));
  }

  Future<ApiResponse<void>> _mutate(
    Future<ApiResponse<void>> Function() request,
  ) async {
    if (isSubmitting.value) {
      return ApiResponse.failure('Request already submitting.');
    }
    isSubmitting.value = true;
    try {
      final result = await request();
      if (result.success) await load();
      return result;
    } finally {
      isSubmitting.value = false;
    }
  }
}
