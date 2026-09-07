import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/economic_event.dart';
import '../repositories/economic_calendar_repository.dart';

/// Drives the Economic calendar screen. Data loading (skeleton / error / empty)
/// is handled by [BaseController] via a single `DataState<List<EventDay>>`. Swap
/// the repository for the real API and nothing here or in the view changes.
class EconomicCalendarController extends BaseController<List<EventDay>> {
  EconomicCalendarController(this._repository);

  final EconomicCalendarRepository _repository;

  @override
  Future<ApiResponse<List<EventDay>>> fetch() => _repository.getEvents();

  @override
  bool isEmpty(List<EventDay> data) => data.isEmpty;
}
