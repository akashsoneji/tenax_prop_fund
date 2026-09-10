import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/kyc_profile.dart';
import '../models/kyc_status.dart';

/// Single source of truth for the Profile & KYC feature. Talks to the live
/// TenaxProp Mobile API:
/// - `GET /profile`  → [getProfile]
/// - `PUT /profile`  → [updateProfile]
/// - `GET /kyc`      → [getKycStatus]
/// - `POST /kyc/documents` (multipart) → [uploadDocuments]
///
/// The controller and view consume `ApiResponse<...>` and never change when the
/// data source does — that is the point of this layer.
class KycRepository {
  KycRepository(this._api);

  final ApiClient _api;

  /// Loads the profile and, in parallel, the KYC status so the verification
  /// checklist reflects the real per-document state. A failed status call is
  /// non-fatal — the profile still renders with pending steps.
  Future<ApiResponse<KycProfile>> getProfile() async {
    final results = await Future.wait([
      ApiEnvelope.guard<Map<String, dynamic>>(
        () => _api.get<Map<String, dynamic>>(ApiEndpoints.profile),
        (data) => data is Map<String, dynamic> ? data : const {},
      ),
      getKycStatus(),
    ]);

    final profileRes = results[0] as ApiResponse<Map<String, dynamic>>;
    final kycRes = results[1] as ApiResponse<KycStatus>;
    if (!profileRes.success || profileRes.data == null) {
      return ApiResponse.failure(profileRes.message ?? 'errors.generic'.tr);
    }
    return ApiResponse.success(
      KycProfile.fromJson(profileRes.data!, kyc: kycRes.data),
    );
  }

  Future<ApiResponse<KycStatus>> getKycStatus() {
    return ApiEnvelope.guard<KycStatus>(
      () => _api.get<Map<String, dynamic>>(ApiEndpoints.kyc),
      (data) => KycStatus.fromJson(data),
      showErrorToast: false,
    );
  }

  Future<ApiResponse<KycProfile>> updateProfile(Map<String, dynamic> body) {
    return ApiEnvelope.guard<KycProfile>(
      () => _api.put<Map<String, dynamic>>(ApiEndpoints.profile, data: body),
      (data) => KycProfile.fromJson(
        data is Map<String, dynamic> ? data : body,
      ),
      successMessage: 'edit_profile.saved_body'.tr,
    );
  }

  /// Uploads one document type (front + optional back) to the PROPCRM API,
  /// which expects `document_type`, `front` and `back` multipart fields per
  /// call. Returns the refreshed [KycStatus].
  Future<ApiResponse<KycStatus>> uploadDocument({
    required String documentType,
    required File front,
    File? back,
  }) async {
    final form = FormData.fromMap({'document_type': documentType});
    form.files.add(
      MapEntry(
        'front',
        await MultipartFile.fromFile(
          front.path,
          filename: front.path.split('/').last,
        ),
      ),
    );
    if (back != null) {
      form.files.add(
        MapEntry(
          'back',
          await MultipartFile.fromFile(
            back.path,
            filename: back.path.split('/').last,
          ),
        ),
      );
    }

    return ApiEnvelope.guard<KycStatus>(
      () => _api.post<Map<String, dynamic>>(
        ApiEndpoints.kycDocuments,
        data: form,
      ),
      (data) => KycStatus.fromJson(data),
      successMessage: 'kyc.docs_uploaded'.tr,
    );
  }
}
