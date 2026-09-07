import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/offer_models.dart';
import '../repositories/offers_repository.dart';

/// Drives the "My offers" screen. Data loading (skeleton / error / empty) is
/// handled by [BaseController] via a single `DataState<OffersData>`; this class
/// only wires the repository. Swap the repository for the real API and nothing
/// here or in the view changes.
class OffersController extends BaseController<OffersData> {
  OffersController(this._repository);

  final OffersRepository _repository;

  @override
  Future<ApiResponse<OffersData>> fetch() => _repository.getOffers();

  @override
  bool isEmpty(OffersData data) => data.isEmpty;
}
