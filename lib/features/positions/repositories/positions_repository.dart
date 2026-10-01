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

  /// Places a market order on the web trade host. [takeProfit] / [stopLoss] are
  /// independent — sending only one is valid and the host leaves the other
  /// level unset.
  Future<ApiResponse<bool>> placeMarketOrder({
    required String symbol,
    required double volume,
    required String type,
    required String tradingAccount,
    double? takeProfit,
    double? stopLoss,
  }) {
    return ApiEnvelope.guard<bool>(
      () => _api.postWeb<Map<String, dynamic>>(
        ApiEndpoints.placeOrder,
        data: {
          'symbol': symbol,
          'volume': volume,
          'type': type,
          'mt5_account': tradingAccount,
          // The web client sends both spellings per level; mirror it exactly.
          if (takeProfit != null) ...{
            'tp': takeProfit,
            'take_profit': takeProfit,
          },
          if (stopLoss != null) ...{'sl': stopLoss, 'stop_loss': stopLoss},
        },
      ),
      (_) => true,
      successMessage: 'positions.order_success'.tr,
    );
  }

  /// Places a pending (limit/stop) order on the web trade host. Same endpoint
  /// as [placeMarketOrder]; pending types additionally carry the trigger
  /// [price] and the optional TP/SL levels.
  Future<ApiResponse<bool>> placePendingOrder({
    required String symbol,
    required double volume,
    required String type,
    required double price,
    required String tradingAccount,
    double? limitPrice,
    double? takeProfit,
    double? stopLoss,
  }) {
    return ApiEnvelope.guard<bool>(
      () => _api.postWeb<Map<String, dynamic>>(
        ApiEndpoints.placeOrder,
        data: {
          'symbol': symbol,
          'volume': volume,
          'type': type,
          'price': price,
          'mt5_account': tradingAccount,
          // Stop-limit types rest at a second level once the stop is hit.
          'stop_limit_price': ?limitPrice,
          // The web client sends BOTH spellings for each level; the trade host
          // only honours the short key on some builds, so mirror it exactly.
          if (takeProfit != null) ...{
            'tp': takeProfit,
            'take_profit': takeProfit,
          },
          if (stopLoss != null) ...{'sl': stopLoss, 'stop_loss': stopLoss},
        },
      ),
      (_) => true,
      successMessage: 'positions.order_success'.tr,
    );
  }

  /// Closes one open position by its trade-engine position id. Pass [volume]
  /// for a PARTIAL close (lots to close); omit it for a full close.
  /// Web body: `{ position_id, mt5_account, volume? }`.
  Future<ApiResponse<bool>> closePositionByPositionId({
    required String positionId,
    required String tradingAccount,
    double? volume,
    bool showSuccessToast = true,
  }) {
    return ApiEnvelope.guard<bool>(
      () => _api.postWeb<Map<String, dynamic>>(
        ApiEndpoints.closePositionByPositionId,
        data: {
          'position_id': int.tryParse(positionId) ?? positionId,
          'mt5_account': tradingAccount,
          'volume': ?volume,
        },
      ),
      (_) => true,
      successMessage: showSuccessToast ? 'positions.close_success'.tr : null,
    );
  }

  /// Closes ALL open positions for the account. white_label body:
  /// `{ trading_account }`.
  Future<ApiResponse<bool>> closeAllPositions({
    required String tradingAccount,
  }) {
    return ApiEnvelope.guard<bool>(
      () => _api.postWeb<Map<String, dynamic>>(
        ApiEndpoints.closePositions,
        data: {'mt5_account': tradingAccount},
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
      () => _api.postWeb<Map<String, dynamic>>(
        ApiEndpoints.closePendingOrder,
        data: {
          'order_id': int.tryParse(orderId) ?? orderId,
          'mt5_account': tradingAccount,
        },
      ),
      (_) => true,
      successMessage: 'positions.cancel_success'.tr,
    );
  }

  /// Updates take-profit / stop-loss for an open position. Web POST body:
  /// `{ mt5_account, position_id, take_profit, stop_loss }` — pass `0` to clear
  /// a level. Endpoint: `/trade/update-tp-sl`.
  Future<ApiResponse<bool>> updateTPSL({
    required String tradingAccount,
    required String positionId,
    num? takeProfit,
    num? stopLoss,
  }) {
    return ApiEnvelope.guard<bool>(
      () => _api.postWeb<Map<String, dynamic>>(
        ApiEndpoints.updateTPSL,
        data: {
          'mt5_account': tradingAccount,
          'position_id': int.tryParse(positionId) ?? positionId,
          'take_profit': ?takeProfit,
          'stop_loss': ?stopLoss,
        },
      ),
      (_) => true,
      successMessage: 'positions.tpsl_success'.tr,
    );
  }

  /// Updates take-profit / stop-loss for a PENDING order. The host uses a
  /// different route and body than [updateTPSL]: `{ mt5_account, order_id,
  /// price, stop_loss, take_profit }`, where an unset level is sent as `null`
  /// (not omitted) so the engine clears it.
  Future<ApiResponse<bool>> updatePendingOrderTPSL({
    required String tradingAccount,
    required String orderId,
    required num price,
    num? takeProfit,
    num? stopLoss,
  }) {
    return ApiEnvelope.guard<bool>(
      () => _api.postWeb<Map<String, dynamic>>(
        ApiEndpoints.updatePendingOrderTPSL,
        data: {
          'mt5_account': tradingAccount,
          'order_id': int.tryParse(orderId) ?? orderId,
          'price': price,
          'stop_loss': stopLoss,
          'take_profit': takeProfit,
        },
      ),
      (_) => true,
      successMessage: 'positions.tpsl_success'.tr,
    );
  }

  /// Fetches closed-trade history. white_label GET with query
  /// `{ trading_account, page, ... }`; response `data` may be flat or nested.
  Future<ApiResponse<HistoryPage>> getTradeHistory({
    required String tradingAccount,
    int page = 1,
    int perPage = 10,
    String? from,
    String? to,
  }) {
    return ApiEnvelope.guardBody<HistoryPage>(
      () => _api.getWeb<Map<String, dynamic>>(
        ApiEndpoints.tradeHistory,
        query: {
          'mt5_account': tradingAccount,
          'page': page,
          'per_page': perPage,
          if (page > 1) 'append': true,
          'from': ?from,
          'to': ?to,
          '_t': DateTime.now().millisecondsSinceEpoch,
        },
      ),
      HistoryPage.fromBody,
    );
  }
}
