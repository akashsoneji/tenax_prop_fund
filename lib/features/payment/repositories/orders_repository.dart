import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/order_models.dart';

/// Talks to the live orders API for the manual "Complete payment" flow:
/// - `GET /orders/{id}`        → [getOrder]
/// - `POST /orders/{id}/proof` → [submitProof] (multipart)
class OrdersRepository {
  OrdersRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<OrderDetails>> getOrder(Object id) {
    return ApiEnvelope.guard<OrderDetails>(
      () => _api.get<Map<String, dynamic>>(ApiEndpoints.order(id)),
      (data) => OrderDetails.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }

  /// Uploads the payment screenshot and optional reference. On success the API
  /// returns the order with `status: under_review`.
  Future<ApiResponse<OrderDetails>> submitProof({
    required Object id,
    required File proof,
    String? reference,
  }) async {
    final form = FormData.fromMap({
      if (reference != null && reference.trim().isNotEmpty)
        'reference': reference.trim(),
    });
    form.files.add(
      MapEntry(
        'proof',
        await MultipartFile.fromFile(
          proof.path,
          filename: proof.path.split('/').last,
        ),
      ),
    );
    return ApiEnvelope.guard<OrderDetails>(
      () => _api.post<Map<String, dynamic>>(
        ApiEndpoints.orderProof(id),
        data: form,
      ),
      (data) => OrderDetails.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
      successMessage: 'Proof submitted — payment is under review.',
    );
  }
}
