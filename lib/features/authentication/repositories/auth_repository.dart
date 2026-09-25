import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_interceptor.dart';
import '../../../core/network/api_response.dart';
import '../models/login_outcome.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Coordinates data sources for auth. Hides the network/storage details from
/// the controller and returns a uniform [ApiResponse].
class AuthRepository {
  AuthRepository(this._service, this._storage);

  final AuthService _service;
  final FlutterSecureStorage _storage;

  static const _userKey = 'auth_user';

  /// Signs in. When the account has two-factor enabled the response carries a
  /// challenge instead of a token, so NOTHING is persisted — the session is only
  /// stored once the code is verified (see [persistSession]).
  Future<ApiResponse<LoginOutcome>> login({
    required String email,
    required String password,
  }) async {
    try {
      final outcome = await _service.login(email: email, password: password);
      final user = outcome.user;
      if (user != null) await persistSession(user);
      return ApiResponse.success(outcome);
    } catch (e) {
      return ApiResponse.failure('Login failed. Please try again.');
    }
  }

  /// Completes a two-factor login. On success the session is persisted here —
  /// this is the first point at which a 2FA login actually has a token.
  Future<ApiResponse<UserModel>> verifyTwoFactor({
    required String challengeToken,
    required String code,
  }) async {
    try {
      final user = await _service.confirmTwoFactor(
        challengeToken: challengeToken,
        code: code,
      );
      await persistSession(user);
      return ApiResponse.success(user);
    } catch (e) {
      return ApiResponse.failure(_messageFrom(e));
    }
  }

  /// Writes [user] + its token to secure storage and primes the network layer.
  /// Shared by login and by the two-factor verification step, which is the point
  /// at which a 2FA login actually receives its token.
  Future<void> persistSession(UserModel user) async {
    await _storage.write(key: ApiInterceptor.tokenKey, value: user.token);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    ApiInterceptor.updateCachedToken(user.token);
    ApiInterceptor.resetUnauthorizedGuard();
  }

  Future<ApiResponse<UserModel>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String countryCode,
    required String phone,
  }) async {
    try {
      final user = await _service.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        countryCode: countryCode,
        phone: phone,
      );
      await _storage.write(key: ApiInterceptor.tokenKey, value: user.token);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
      ApiInterceptor.updateCachedToken(user.token);
      ApiInterceptor.resetUnauthorizedGuard();
      return ApiResponse.success(user);
    } catch (e) {
      return ApiResponse.failure(_messageFrom(e));
    }
  }

  Future<ApiResponse<void>> forgotPassword({required String email}) async {
    try {
      await _service.forgotPassword(email: email);
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.failure(_messageFrom(e));
    }
  }

  Future<ApiResponse<UserModel>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final user = await _service.verifyEmail(email: email, code: code);
      await _storage.write(key: ApiInterceptor.tokenKey, value: user.token);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
      ApiInterceptor.updateCachedToken(user.token);
      return ApiResponse.success(user);
    } catch (e) {
      return ApiResponse.failure(_messageFrom(e));
    }
  }

  Future<ApiResponse<void>> resendOtp({required String email}) async {
    try {
      await _service.resendOtp(email: email);
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.failure(_messageFrom(e));
    }
  }

  /// True when a token was persisted from a previous session.
  Future<bool> hasSession() async {
    final token = await _storage.read(key: ApiInterceptor.tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Restores the persisted user (if any) so the app can rehydrate state on
  /// startup without hitting the network.
  Future<UserModel?> currentUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Revokes the server token then clears every piece of persisted session
  /// data. Local cleanup runs even if the network call fails.
  Future<void> logout() async {
    try {
      await _service.logout();
    } catch (_) {
      // Ignore — we always clear the local session below.
    }
    await clearSession();
  }

  /// Wipes the local session WITHOUT calling `/auth/logout` — used when the
  /// server has already rejected the token (401), where the revoke call would
  /// only fail again.
  Future<void> clearSession() async {
    await _storage.delete(key: ApiInterceptor.tokenKey);
    await _storage.delete(key: _userKey);
    ApiInterceptor.updateCachedToken(null);
  }

  /// Turns a thrown error into a user-facing message, surfacing the server's
  /// first validation error (422) or message when present.
  String _messageFrom(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final errors = data['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
        final msg = data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
