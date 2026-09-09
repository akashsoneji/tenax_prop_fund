import 'package:get/get_utils/get_utils.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/positions_models.dart';

/// REST layer for trade actions. Wraps [ApiClient] through [ApiEnvelope.guard]
/// so the controller never touches Dio. Request bodies + paths are ported from
/// the white_label app (`trading_repository_impl.dart`) — only the endpoint
/// constants differ (see [ApiEndpoints], which carries a TODO about the tenax
/// `user/` prefix / base).
class PositionsRepository {
  PositionsRepository(this._api);

  final ApiClient _api;

  /// Closes one open position by its trade-engine position id.
  /// white_label body: `{ position_id, trading_account }`.
  Future<ApiResponse<bool>> closePositionByPositionId({
    required String positionId,
    required String tradingAccount,
  }) {
    return ApiEnvelope.guard<bool>(
      () => _api.post<Map<String, dynamic>>(
        ApiEndpoints.closePositionByPositionId,
        data: {
          'position_id': positionId,
          'trading_account': tradingAccount,
        },
      ),
      (_) => true,
      successMessage: 'positions.close_success'.tr,
    );
  }

  /// Closes ALL open positions for the account. white_label body:
  /// `{ trading_account }`.
  Future<ApiResponse<bool>> closeAllPositions({
    required String tradingAccount,
  }) {
    return ApiEnvelope.guard<bool>(
      () => _api.post<Map<String, dynamic>>(
        ApiEndpoints.closePositions,
        data: {'trading_account': tradingAccount},
      ),
      (_) => true,
      successMessage: 'positions.close_all_success'.tr,
    );
  }

  /// Cancels a pending order. white_label body: `{ order_id, trading_account }`.
  Future<ApiResponse<bool>> cancelPendingOrder({
    required String orderId,
    required String tradingAccount,
  }) {
    return ApiEnvelope.guard<bool>(
      () => _api.post<Map<String, dynamic>>(
        ApiEndpoints.closePendingOrder,
        data: {
          'order_id': orderId,
          'trading_account': tradingAccount,
        },
      ),
      (_) => true,
      successMessage: 'positions.cancel_success'.tr,
    );
  }

  /// Fetches closed-trade history. white_label GET with query
  /// `{ trading_account, page, ... }`; response `data` may be flat or nested.
  Future<ApiResponse<List<HistoryEntry>>> getTradeHistory({
    required String tradingAccount,
    int page = 1,
  }) {
    return ApiEnvelope.guard<List<HistoryEntry>>(
      () => _api.get<Map<String, dynamic>>(
        ApiEndpoints.tradeHistory,
        query: {
          'trading_account': tradingAccount,
          'page': page,
        },
      ),
      parseHistory,
    );
  }
}
