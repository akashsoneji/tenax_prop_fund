import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/account_models.dart';

/// Single source of truth for the Account detail screen.
///  - Overview → live REST `GET /accounts/{id}` (standard `{success,data}`
///    envelope), parsed by [AccountData.fromJson].
///  - Platform & Reset still reuse the web portal's Inertia routes
///    (`GET {web}/app/accounts/platform|reset?account={id}`) until a dedicated
///    REST endpoint exists.
class AccountRepository {
  AccountRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<AccountData>> getOverview(Object accountId) {
    return ApiEnvelope.guard<AccountData>(
      () => _api.get<Map<String, dynamic>>(
        ApiEndpoints.accountDetail(accountId),
      ),
      (data) => AccountData.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }

  Future<ApiResponse<PlatformData>> getPlatform(Object accountId) =>
      _guard(() async {
        final props = await _api.getInertiaProps(
          '${_api.webBaseUrl}/app/accounts/platform?account=$accountId',
        );
        return PlatformData.fromProps(props);
      });

  Future<ApiResponse<ResetData>> getReset(Object accountId) => _guard(() async {
        final props = await _api.getInertiaProps(
          '${_api.webBaseUrl}/app/accounts/reset?account=$accountId',
        );
        return ResetData.fromProps(props);
      });

  Future<ApiResponse<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return ApiResponse.success(await run());
    } on DioException catch (e) {
      final message = _messageFor(e);
      AppToast.error(message);
      return ApiResponse.failure(message);
    } catch (_) {
      const message = 'Could not load this account. Please try again.';
      AppToast.error(message);
      return ApiResponse.failure(message);
    }
  }

  String _messageFor(DioException e) {
    switch (e.response?.statusCode) {
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'You do not have permission to view this account.';
      case 404:
        return 'Account not found.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Could not load this account. Please try again.';
  }
}
