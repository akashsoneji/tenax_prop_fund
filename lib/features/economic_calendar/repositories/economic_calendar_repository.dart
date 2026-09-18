import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/economic_event.dart';

/// Single source of truth for economic-calendar data. Calls
/// `GET /tools/calendar?currency=ALL` and maps the envelope's `data.events`
/// into day-grouped [EventDay]s. The controller and view are unaware of the
/// source — that is the point of this layer.
class EconomicCalendarRepository {
  EconomicCalendarRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<List<EventDay>>> getEvents({String currency = 'ALL'}) {
    return ApiEnvelope.guard<List<EventDay>>(
      () => _api.get<Map<String, dynamic>>(
        ApiEndpoints.calendar,
        query: {'currency': currency},
      ),
      (data) {
        final map = data is Map ? Map<String, dynamic>.from(data) : const {};
        final events = map['events'];
        return EventDay.groupByDate(events is List ? events : const []);
      },
    );
  }
}
