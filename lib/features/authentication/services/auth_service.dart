import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/platform/platform_info.dart';
import '../models/login_outcome.dart';
import '../models/user_model.dart';

/// Talks to the REST auth endpoints. Only services touch the network client.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  /// Calls `POST /auth/login`.
  ///
  /// Two shapes come back with `200 success: true`:
  /// - normal — `data` carries `access_token` + `user`, folded into a
  ///   [UserModel];
  /// - 2FA enabled — `data` carries `two_factor_required: true` plus a
  ///   `challenge_token`, and NO user/token yet.
  ///
  /// Throws on any non-2xx / non-success response (the repository maps it to a
  /// friendly [ApiResponse.failure]).
  Future<LoginOutcome> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
        'device_name': PlatformInfo.deviceName,
      },
    );
    final data = res.data?['data'];
    if (data is Map<String, dynamic> && data['two_factor_required'] == true) {
      final challenge = data['challenge_token']?.toString() ?? '';
      if (challenge.isEmpty) {
        throw const FormatException('two_factor_required without a token');
      }
      return LoginOutcome.twoFactor(challenge);
    }
    return LoginOutcome.authenticated(_userFromEnvelope(res.data));
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
  /// On success the envelope carries a fresh `access_token` + `user` (now with
  /// `email_verified: true`), folded into the returned [UserModel]. Throws on
  /// any non-2xx / non-success response.
  Future<UserModel> verifyEmail({
    required String email,
    required String code,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.verifyEmail,
      data: {'email': email, 'code': code},
    );
    return _userFromEnvelope(res.data);
  }

  /// Completes a two-factor login: `POST /auth/two-factor` with
  /// `{code}`, authenticated with the `challenge_token` from [login] (the real
  /// session token does not exist yet, so it is sent as the bearer explicitly).
  ///
  /// When the envelope carries `access_token` + `user` that is the new session;
  /// otherwise the challenge token is now a full token and the profile is
  /// fetched to build the user.
  Future<UserModel> confirmTwoFactor({
    required String challengeToken,
    required String code,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.twoFactorLoginVerify,
      data: {'code': code, 'device_name': PlatformInfo.deviceName},
      headers: {'Authorization': 'Bearer $challengeToken'},
    );
    final data = res.data?['data'];
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final token = map['access_token'] as String? ?? challengeToken;
    final user = map['user'];
    if (user is Map<String, dynamic>) {
      return UserModel.fromJson(user).copyWith(token: token);
    }
    return _profile(token);
  }

  /// Reads `GET /profile` with an explicit bearer — used right after a
  /// two-factor confirm whose response did not include the user object.
  Future<UserModel> _profile(String token) async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.profile,
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = res.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Malformed profile response');
    }
    final user = data['user'] is Map<String, dynamic> ? data['user'] : data;
    return UserModel.fromJson(user as Map<String, dynamic>)
        .copyWith(token: token);
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
