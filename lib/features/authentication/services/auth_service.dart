import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

/// Talks to the REST auth endpoints. Only services touch the network client.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  /// Calls `POST /auth/login`. On success the envelope's `data` carries
  /// `access_token` + `user`; we fold the token into the returned [UserModel].
  /// Throws on any non-2xx / non-success response (the repository maps it to a
  /// friendly [ApiResponse.failure]).
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
        'device_name': 'flutter-app',
      },
    );
    return _userFromEnvelope(res.data);
  }

  /// Calls `POST /auth/register`. On success the envelope mirrors login
  /// (returns `access_token` + `user`), so the user is auto-authenticated
  /// though `email_verified` is false until they confirm their email.
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String countryCode,
    required String phone,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'country_code': countryCode,
        'phone': phone,
      },
    );
    return _userFromEnvelope(res.data);
  }

  /// Calls `POST /auth/forgot-password`. Always succeeds server-side (it never
  /// reveals whether the email exists), so we only surface transport errors.
  Future<void> forgotPassword({required String email}) async {
    await _api.post<Map<String, dynamic>>(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  /// Calls `POST /auth/verify-email` with `{email, code}` to confirm the OTP.
  /// Throws on any non-2xx / non-success response.
  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    await _api.post<Map<String, dynamic>>(
      ApiEndpoints.verifyEmail,
      data: {'email': email, 'code': code},
    );
  }

  /// Calls `POST /auth/resend-otp` with `{email}` to re-send the OTP code.
  Future<void> resendOtp({required String email}) async {
    await _api.post<Map<String, dynamic>>(
      ApiEndpoints.resendOtp,
      data: {'email': email},
    );
  }

  /// Calls `POST /auth/logout` to revoke the server-side token. The local
  /// session is cleared by the repository regardless of the outcome.
  Future<void> logout() async {
    await _api.post<Map<String, dynamic>>(ApiEndpoints.logout);
  }

  UserModel _userFromEnvelope(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is! Map<String, dynamic> || data['user'] is! Map<String, dynamic>) {
      throw const FormatException('Malformed auth response');
    }
    final token = data['access_token'] as String? ?? '';
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    return user.copyWith(token: token);
  }
}
