import 'package:get/get_utils/get_utils.dart' show Trans;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/notification_models.dart';

/// One page of the notifications feed: the flat, newest-first rows plus the
/// pagination meta so the controller knows whether more pages exist.
class NotificationsPage {
  const NotificationsPage({required this.items, required this.meta});

  final List<AppNotification> items;
  final PageMeta meta;
}

/// Single source of truth for notification data. Talks to the live
/// `/notifications` REST endpoints (standard `{success, message, data, meta}`
/// envelope). The controller/view never change when the data source does.
class NotificationsRepository {
  NotificationsRepository(this._api);

  final ApiClient _api;

  /// Paged feed. `data` is a flat, newest-first array; `meta` carries paging.
  Future<ApiResponse<NotificationsPage>> getNotifications({int page = 1}) {
    return ApiEnvelope.guardBody<NotificationsPage>(
      () => _api.get<Map<String, dynamic>>(
        ApiEndpoints.notifications,
        query: {'page': page},
      ),
      (body) {
        final list = (body['data'] as List?) ?? const [];
        final items = list
            .whereType<Map<String, dynamic>>()
            .map(AppNotification.fromJson)
            .toList();
        final meta = body['meta'] is Map<String, dynamic>
            ? PageMeta.fromJson(body['meta'] as Map<String, dynamic>)
            : PageMeta.empty;
        return NotificationsPage(items: items, meta: meta);
      },
    );
  }

  /// Unread badge count (`data.count`). Silent — no error toast on a background
  /// badge poll.
  Future<ApiResponse<int>> getUnreadCount() {
    return ApiEnvelope.guard<int>(
      () => _api.get<Map<String, dynamic>>(
        ApiEndpoints.notificationsUnreadCount,
      ),
      (data) => (data is Map && data['count'] is num)
          ? (data['count'] as num).toInt()
          : 0,
      showErrorToast: false,
    );
  }

  /// Marks a single notification read. `data.count` is the new unread total.
  Future<ApiResponse<int>> markRead(Object id) {
    return ApiEnvelope.guard<int>(
      () => _api.post<Map<String, dynamic>>(
        ApiEndpoints.notificationRead(id),
      ),
      (data) => (data is Map && data['count'] is num)
          ? (data['count'] as num).toInt()
          : 0,
      showErrorToast: false,
    );
  }

  /// Marks every notification read.
  Future<ApiResponse<void>> markAllRead() {
    return ApiEnvelope.guard<void>(
      () => _api.post<Map<String, dynamic>>(
        ApiEndpoints.notificationsReadAll,
      ),
      (_) {},
    );
  }

  /// Notification channel preferences (catalog + current toggles).
  Future<ApiResponse<NotificationPreferences>> getPreferences() {
    return ApiEnvelope.guard<NotificationPreferences>(
      () => _api.get<Map<String, dynamic>>(
        ApiEndpoints.notificationPreferences,
      ),
      (data) => NotificationPreferences.fromJson(
        data is Map<String, dynamic> ? data : const {},
      ),
    );
  }

  /// Persists the full preferences map.
  Future<ApiResponse<void>> savePreferences(NotificationPreferences prefs) {
    return ApiEnvelope.guard<void>(
      () => _api.put<Map<String, dynamic>>(
        ApiEndpoints.notificationPreferences,
        data: {'preferences': prefs.toPreferencesMap()},
      ),
      (_) {},
      successMessage: 'notifications.prefs_saved'.tr,
    );
  }
}
