import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/payout_method.dart';
import '../repositories/payout_methods_repository.dart';

/// Drives the Payout methods screen. Data loading (skeleton / error / empty) is
/// handled by [BaseController] via a single `DataState<List<PayoutMethod>>`;
/// swap the repository for the real API and nothing here or in the view changes.
class PayoutMethodsController extends BaseController<List<PayoutMethod>> {
  PayoutMethodsController(this._repository);

  final PayoutMethodsRepository _repository;

  @override
  Future<ApiResponse<List<PayoutMethod>>> fetch() =>
      _repository.getPayoutMethods();

  @override
  bool isEmpty(List<PayoutMethod> data) => data.isEmpty;
}
