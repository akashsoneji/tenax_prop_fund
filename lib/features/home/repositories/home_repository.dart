import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/dashboard_models.dart';

/// Single source of truth for the Home dashboard. Calls the live
/// `GET /api/v1/dashboard` endpoint (standard `{success, message, data}`
/// envelope) — a single call that carries the KPI + live-account snapshot,
/// account health and recent activity. This is the app's one live `/api/v1`
/// screen; every other portal screen uses Inertia `/app/...` or static demo
/// data.
class HomeRepository {
  HomeRepository(this._api);

  final ApiClient _api;

  /// The most recent dashboard `data`, cached so the referral card and unread
  /// badge can be derived from the same fetch without a second network call.
  Map<String, dynamic> _lastData = const {};

  Future<ApiResponse<DashboardData>> getDashboard() {
    return ApiEnvelope.guard<DashboardData>(
      () => _api.get<Map<String, dynamic>>(ApiEndpoints.dashboard),
      (data) {
        _lastData = (data as Map?)?.cast<String, dynamic>() ?? const {};
        return DashboardData.fromJson(_lastData);
      },
    );
  }

  /// The referral summary shown on the Home "Refer & earn" card. Fetched from
  /// the live `GET /growth/referrals` endpoint (standard envelope; `data` nests
  /// `referral` + `stats`). Returns null when the call fails so the card hides.
  Future<DashboardReferral?> getReferralCard() async {
    final res = await ApiEnvelope.guard<DashboardReferral>(
      () => _api.get<Map<String, dynamic>>(ApiEndpoints.referrals),
      (data) => DashboardReferral.fromReferralsJson(
        (data as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
    return res.success ? res.data : null;
  }

  /// Unread notification count for the hero bell badge, read from the dashboard
  /// payload's `notificationBadge.unread_count`.
  int getUnreadCount() {
    final badge =
        (_lastData['notificationBadge'] as Map?)?.cast<String, dynamic>();
    return (badge?['unread_count'] as num?)?.toInt() ?? 0;
  }
}
