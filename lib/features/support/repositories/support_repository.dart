import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/support_models.dart';

/// Single source of truth for Support data. Talks to the live `/support/*` REST
/// endpoints (standard `{success, message, data, meta}` envelope). The topics
/// and open tickets are fetched together so the screen holds one `DataState`.
class SupportRepository {
  SupportRepository(this._api);

  final ApiClient _api;

  /// Loads the ticket topics and the open tickets in parallel for the screen.
  Future<ApiResponse<SupportData>> getSupport() async {
    final topicsRes = await _getTopics();
    final ticketsRes = await getTickets();

    if (!ticketsRes.success || ticketsRes.data == null) {
      return ApiResponse.failure(
        ticketsRes.message ?? 'Could not load tickets.',
      );
    }
    return ApiResponse.success(
      SupportData(
        topics: topicsRes.data ?? const [],
        tickets: ticketsRes.data!,
      ),
    );
  }

  Future<ApiResponse<List<SupportTopic>>> _getTopics() {
    return ApiEnvelope.guard<List<SupportTopic>>(
      () => _api.get<Map<String, dynamic>>(ApiEndpoints.supportTopics),
      (data) {
        final list =
            (data is Map ? data['topics'] as List? : null) ?? const [];
        return list
            .whereType<Map<String, dynamic>>()
            .map(SupportTopic.fromJson)
            .toList();
      },
      showErrorToast: false,
    );
  }

  /// Tickets for a tab (open | closed | all). `data` is a flat list.
  Future<ApiResponse<List<SupportTicket>>> getTickets({String tab = 'open'}) {
    return ApiEnvelope.guardBody<List<SupportTicket>>(
      () => _api.get<Map<String, dynamic>>(
        ApiEndpoints.supportTickets,
        query: {'tab': tab},
      ),
      (body) {
        final list = (body['data'] as List?) ?? const [];
        return list
            .whereType<Map<String, dynamic>>()
            .map(SupportTicket.fromJson)
            .toList();
      },
    );
  }

  /// Full ticket with its message thread.
  Future<ApiResponse<SupportTicket>> getTicket(Object id) {
    return ApiEnvelope.guard<SupportTicket>(
      () => _api.get<Map<String, dynamic>>(
        ApiEndpoints.supportTicketDetail(id),
      ),
      (data) => SupportTicket.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }

  /// Opens a new ticket. Returns the created ticket (with its first message).
  Future<ApiResponse<SupportTicket>> createTicket({
    required String topic,
    required String subject,
    required String message,
    String accountLogin = '',
  }) {
    return ApiEnvelope.guard<SupportTicket>(
      () => _api.post<Map<String, dynamic>>(
        ApiEndpoints.supportTickets,
        data: {
          'topic': topic,
          'subject': subject,
          'message': message,
          'account_login': accountLogin,
        },
      ),
      (data) => SupportTicket.fromJson(
        (data is Map && data['ticket'] is Map)
            ? data['ticket'] as Map<String, dynamic>
            : (data is Map<String, dynamic> ? data : const {}),
      ),
      successMessage: 'Ticket submitted. We reply within 24 hours.',
    );
  }

  /// Posts a reply on an existing ticket. Returns the updated ticket.
  Future<ApiResponse<SupportTicket>> replyTicket({
    required Object id,
    required String message,
  }) {
    return ApiEnvelope.guard<SupportTicket>(
      () => _api.post<Map<String, dynamic>>(
        ApiEndpoints.supportTicketReply(id),
        data: {'message': message},
      ),
      (data) => SupportTicket.fromJson(
        (data is Map && data['ticket'] is Map)
            ? data['ticket'] as Map<String, dynamic>
            : (data is Map<String, dynamic> ? data : const {}),
      ),
      successMessage: 'Reply sent.',
    );
  }
}
