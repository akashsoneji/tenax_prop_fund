import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/security_models.dart';

/// All network access for the Settings → Security module.
class SecurityRepository {
  SecurityRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<SecuritySettings>> getSecurity() => ApiEnvelope.guard(
        () => _api.get<dynamic>(ApiEndpoints.settingsSecurity),
        (data) => SecuritySettings.fromJson(
          data is Map<String, dynamic> ? data : const {},
        ),
      );

  Future<ApiResponse<void>> savePrefs(SecurityPrefs prefs) =>
      ApiEnvelope.guard<void>(
        () => _api.put<dynamic>(
          ApiEndpoints.settingsSecurity,
          data: prefs.toJson(),
        ),
        (_) {},
      );

  Future<ApiResponse<String>> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) =>
      _guardMessage(
        () => _api.post<dynamic>(
          ApiEndpoints.settingsPassword,
          data: {
            'current_password': currentPassword,
            'password': password,
            'password_confirmation': passwordConfirmation,
          },
        ),
      );

  Future<ApiResponse<Beneficiary>> getBeneficiary() => ApiEnvelope.guard(
        () => _api.get<dynamic>(ApiEndpoints.settingsBeneficiary),
        (data) => Beneficiary.fromJson(
          data is Map<String, dynamic> ? data : const {},
        ),
      );

  Future<ApiResponse<String>> saveBeneficiary({
    required String fullName,
    required String relationship,
    required String email,
    required String mobile,
  }) =>
      _guardMessage(
        () => _api.put<dynamic>(
          ApiEndpoints.settingsBeneficiary,
          data: {
            'full_name': fullName,
            'relationship': relationship,
            'email': email,
            'mobile': mobile,
          },
        ),
      );

  Future<ApiResponse<TwoFactorEnrolment>> enrolTwoFactor() =>
      ApiEnvelope.guard(
        () => _api.post<dynamic>(ApiEndpoints.twoFactorEnrol),
        (data) => TwoFactorEnrolment.fromJson(
          data is Map<String, dynamic> ? data : const {},
        ),
      );

  /// Confirms enrolment. A wrong code comes back as a 422 whose body has no
  /// `success` key — only `{message, errors: {code: [...]}}` — so the field
  /// error is unwrapped here instead of surfacing as a generic failure.
  Future<ApiResponse<String>> confirmTwoFactor({
    required String secret,
    required String code,
  }) =>
      _guardMessage(
        () => _api.post<dynamic>(
          ApiEndpoints.twoFactorConfirm,
          data: {'secret': secret, 'code': code},
        ),
      );

  Future<ApiResponse<List<String>>> regenerateRecoveryCodes(
    String currentPassword,
  ) async {
    try {
      final res = await _api.post<dynamic>(
        ApiEndpoints.twoFactorRecoveryCodes,
        data: {'current_password': currentPassword},
      );
      final body = res.data;
      if (body is! Map<String, dynamic>) {
        return ApiResponse.failure('Unexpected server response.');
      }
      if (body['success'] != true) {
        return ApiResponse.failure(_messageOf(body));
      }
      return ApiResponse.success(_codesOf(body['data']));
    } on DioException catch (e) {
      return ApiResponse.failure(_errorFrom(e));
    }
  }

  Future<ApiResponse<String>> disableTwoFactor(String currentPassword) =>
      _guardMessage(
        () => _api.delete<dynamic>(
          ApiEndpoints.twoFactorDisable,
          data: {'current_password': currentPassword},
        ),
      );

  /// Runs a mutation whose payload is always `null` and whose only useful
  /// result is the server's user-facing `message`. Validation failures (422)
  /// are unwrapped to the first field error so the sheet can show it inline.
  Future<ApiResponse<String>> _guardMessage(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final res = await request();
      final body = res.data;
      if (body is! Map<String, dynamic>) {
        return ApiResponse.failure('Unexpected server response.');
      }
      if (body['success'] != true) {
        return ApiResponse.failure(_messageOf(body));
      }
      return ApiResponse.success(body['message']?.toString() ?? '');
    } on DioException catch (e) {
      return ApiResponse.failure(_errorFrom(e));
    }
  }

  static String _errorFrom(DioException e) {
    final body = e.response?.data;
    if (body is Map<String, dynamic>) return _messageOf(body);
    return 'Something went wrong. Please try again.';
  }

  /// Prefers the first field-level validation error over the generic message,
  /// because the server's top-level text is often less specific than
  /// `errors.code[0]` / `errors.password[0]`.
  static String _messageOf(Map<String, dynamic> body) {
    final errors = body['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value is String && value.isNotEmpty) return value;
      }
    }
    return body['message']?.toString() ?? 'Something went wrong.';
  }

  static List<String> _codesOf(dynamic data) {
    if (data is List) return data.map((e) => e.toString()).toList();
    if (data is Map<String, dynamic>) {
      final codes = data['recovery_codes'] ?? data['codes'];
      if (codes is List) return codes.map((e) => e.toString()).toList();
    }
    return const <String>[];
  }
}
