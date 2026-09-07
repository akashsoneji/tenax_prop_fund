import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/accounts_models.dart';

/// Single source of truth for Account Center data. The mobile app has no
/// dedicated REST endpoint for the account list, so it reuses the web portal's
/// Inertia route `GET {webBaseUrl}/app/accounts` (with `tab=all` so every owned
/// account comes back in one page and the screen can filter client-side). The
/// controller and view never change when the data source does — that is the
/// point of this layer.
class AccountsRepository {
  AccountsRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<AccountsData>> getAccounts() async {
    try {
      final props = await _api.getInertiaProps(
        '${_api.webBaseUrl}/app/accounts?tab=all&per_page=100',
      );
      return ApiResponse.success(AccountsData.fromProps(props));
    } on DioException catch (e) {
      final message = _messageFor(e);
      AppToast.error(message);
      return ApiResponse.failure(message);
    } catch (_) {
      const message = 'Could not load your accounts. Please try again.';
      AppToast.error(message);
      return ApiResponse.failure(message);
    }
  }

  String _messageFor(DioException e) {
    switch (e.response?.statusCode) {
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'You do not have permission to view these accounts.';
      case 404:
        return 'Accounts are not available right now.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Could not load your accounts. Please try again.';
  }
}
