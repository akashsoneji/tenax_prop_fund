import '../../../core/network/api_response.dart';
import '../models/economic_event.dart';

/// Single source of truth for economic-calendar data. Today it returns demo
/// data after a short delay to simulate the network; when the API lands, replace
/// the body of [getEvents] with an `ApiClient` call + `fromJson`. The controller
/// and view do not change when that swap happens — that is the point of this
/// layer.
class EconomicCalendarRepository {
  Future<ApiResponse<List<EventDay>>> getEvents() async {
    try {
      // Simulated network latency so the shimmer is visible during development.
      await Future<void>.delayed(const Duration(milliseconds: 900));
      return ApiResponse.success(_demoDays);
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  // -------------------------------------------------------------------------
  // Demo data (moved out of the controller). Delete when the API is wired.
  // -------------------------------------------------------------------------
  static const List<EventDay> _demoDays = [
    EventDay('Today', [
      EconomicEvent(
        currency: 'USD',
        title: 'Non-Farm Payrolls',
        detail: '13:30 server time · forecast 185K · previous 206K',
        impact: EventImpact.high,
      ),
      EconomicEvent(
        currency: 'USD',
        title: 'ISM Services PMI',
        detail: '15:00 server time · forecast 51.2 · previous 50.8',
        impact: EventImpact.high,
      ),
      EconomicEvent(
        currency: 'EUR',
        title: 'Retail Sales m/m',
        detail: '09:00 server time · forecast 0.2% · previous 0.1%',
        impact: EventImpact.medium,
      ),
    ]),
    EventDay('Tomorrow', [
      EconomicEvent(
        currency: 'GBP',
        title: 'BoE Rate Decision',
        detail: '12:00 server time · forecast 5.00% · previous 5.25%',
        impact: EventImpact.high,
      ),
      EconomicEvent(
        currency: 'USD',
        title: 'Unemployment Claims',
        detail: '13:30 server time · forecast 232K · previous 229K',
        impact: EventImpact.medium,
      ),
    ]),
    EventDay('Thu 7 Aug', [
      EconomicEvent(
        currency: 'AUD',
        title: 'RBA Statement',
        detail: '07:30 server time · forecast – · previous –',
        impact: EventImpact.high,
      ),
    ]),
  ];
}
