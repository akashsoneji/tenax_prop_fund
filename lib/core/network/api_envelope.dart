import 'package:dio/dio.dart';

import '../../shared/widgets/app_toast.dart';
import 'api_response.dart';

/// Pagination info from the `meta` block of a list response.
class PageMeta {
  const PageMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.totalPages,
    required this.hasNext,
  });

  final int currentPage;
  final int perPage;
  final int total;
  final int totalPages;
  final bool hasNext;

  static const empty = PageMeta(
    currentPage: 1,
    perPage: 0,
    total: 0,
    totalPages: 1,
    hasNext: false,
  );

  factory PageMeta.fromJson(Map<String, dynamic> json) => PageMeta(
        currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
        perPage: (json['per_page'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
        hasNext: json['has_next'] as bool? ?? false,
      );
}

/// Parses the standard API envelope `{ success, message, data, errors, meta }`
/// (see docs/api_standard.json) into an [ApiResponse]. Every repository funnels
/// its Dio call through here so error handling and shape parsing live in ONE
/// place instead of being re-implemented per feature.
class ApiEnvelope {
  /// Runs [request] (a Dio call) and maps the JSON envelope's `data` through
  /// [parse]. Any Dio/parse failure becomes an [ApiResponse.failure] with a
  /// user-facing message — callers never see a raw exception.
  /// Runs [request], maps `data` through [parse], and — on ANY failure —
  /// surfaces a uniform error toast so no screen has to remember to do it.
  /// Set [showErrorToast] to false for silent/background calls (e.g. polling
  /// an unread badge) where a toast would be noise. A success toast is opt-in
  /// via [successMessage] (used for mutations like save/submit/cancel).
  static Future<ApiResponse<T>> guard<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data) parse, {
    bool showErrorToast = true,
    String? successMessage,
  }) async {
    try {
      final res = await request();
      final body = res.data;
      if (body is! Map<String, dynamic>) {
        return _fail('Unexpected server response.', showErrorToast);
      }
      // Mobile API uses `success`; the web trade API uses `status`. Accept both.
      final success =
          (body['success'] as bool?) ?? (body['status'] as bool?) ?? false;
      final message = body['message'] as String?;
      if (!success) {
        return _fail(message ?? 'Something went wrong.', showErrorToast);
      }
      if (successMessage != null && successMessage.isNotEmpty) {
        AppToast.success(successMessage);
      }
      return ApiResponse.success(parse(body['data']));
    } on DioException catch (e) {
      return _fail(_dioMessage(e), showErrorToast);
    } catch (_) {
      return _fail('Something went wrong. Please try again.', showErrorToast);
    }
  }

  static ApiResponse<T> _fail<T>(String message, bool showToast) {
    if (showToast) AppToast.error(message);
    return ApiResponse.failure(message);
  }

  /// Extracts the `meta` pagination block, if present.
  static PageMeta metaOf(Response<dynamic> res) {
    final body = res.data;
    if (body is Map<String, dynamic> && body['meta'] is Map<String, dynamic>) {
      return PageMeta.fromJson(body['meta'] as Map<String, dynamic>);
    }
    return PageMeta.empty;
  }

  static String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    switch (e.response?.statusCode) {
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'Requested resource not found.';
      case 422:
        return 'Please fix the highlighted fields.';
      case 500:
        return 'Something went wrong. Please try again later.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
