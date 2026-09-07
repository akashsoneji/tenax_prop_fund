import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/referral_models.dart';

/// Single source of truth for referral data. The mobile app has no dedicated
/// REST endpoint, so it reuses the web portal's Inertia route
/// `GET {webBaseUrl}/app/growth/refer` and maps `props` through
/// [ReferralData.fromProps]. The controller and view do not change when the
/// data source does — that is the point of this layer.
class ReferralRepository {
  ReferralRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<ReferralData>> getReferral() async {
    try {
      final props =
          await _api.getInertiaProps('${_api.webBaseUrl}/app/growth/refer');
      return ApiResponse.success(ReferralData.fromProps(props));
    } on DioException catch (e) {
      final message = _messageFor(e);
      AppToast.error(message);
      return ApiResponse.failure(message);
    } catch (_) {
      const message = 'Could not load your referrals. Please try again.';
      AppToast.error(message);
      return ApiResponse.failure(message);
    }
  }

  String _messageFor(DioException e) {
    switch (e.response?.statusCode) {
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'You do not have permission to view referrals.';
      case 404:
        return 'Referrals are not available right now.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Could not load your referrals. Please try again.';
  }
}
