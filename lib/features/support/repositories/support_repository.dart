import '../../../core/network/api_response.dart';
import '../models/support_models.dart';

/// Single source of truth for Support data. Today it returns demo data after a
/// short delay to simulate the network; when the API lands, replace the body of
/// [getSupport] with an `ApiClient` call + `fromJson`. The controller and view
/// do not change when that swap happens — that is the point of this layer.
class SupportRepository {
  Future<ApiResponse<SupportData>> getSupport() async {
    try {
      // Simulated network latency so the shimmer is visible during development.
      await Future<void>.delayed(const Duration(milliseconds: 900));

      const data = SupportData(tickets: _demoTickets);
      return ApiResponse.success(data);
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  // -------------------------------------------------------------------------
  // Demo data (moved out of the controller). Delete when the API is wired.
  // -------------------------------------------------------------------------
  static const List<SupportTicket> _demoTickets = [
    SupportTicket(
      title: 'Quick strike percentage que...',
      subtitle: 'Does the quick strike percentage...',
      status: TicketStatus.open,
    ),
    SupportTicket(
      title: 'Invoice copy for INV-100',
      subtitle: '#PZ-4602 · Billing · Jul 10',
      status: TicketStatus.closed,
    ),
  ];
}
