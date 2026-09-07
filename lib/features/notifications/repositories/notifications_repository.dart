import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/notification_models.dart';

/// Single source of truth for notification data. Currently serves STATIC DEMO
/// data grouped under date sections ('Today' / 'Yesterday' / 'Earlier').
class NotificationsRepository {
  NotificationsRepository(this._api);

  // Retained for DI parity; not used while serving demo data.
  // ignore: unused_field
  final ApiClient _api;

  /// Returns a static demo feed grouped into date sections.
  Future<ApiResponse<List<NotificationGroup>>> getNotifications({
    String filter = 'all',
    int page = 1,
  }) {
    return Future.value(ApiResponse.success(_demoGroups()));
  }

  /// Demo unread count (local, no network).
  Future<ApiResponse<int>> getUnreadCount() {
    return Future.value(ApiResponse.success(2));
  }

  /// No-op mark-read (local, no network).
  Future<ApiResponse<void>> markRead(Object id) {
    return Future.value(ApiResponse.success(null));
  }

  /// No-op mark-all-read (local, no network).
  Future<ApiResponse<void>> markAllRead() {
    return Future.value(ApiResponse.success(null));
  }

  List<NotificationGroup> _demoGroups() {
    final now = DateTime.now();
    return [
      NotificationGroup(
        label: 'Today',
        items: [
          AppNotification(
            type: NotificationType.success,
            title: 'Payout approved',
            subtitle: 'Your \$1,240 payout request has been approved.',
            time: '2h',
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
          AppNotification(
            type: NotificationType.warning,
            title: 'New login detected',
            subtitle: 'A new sign-in from Chrome on macOS.',
            time: '5h',
            createdAt: now.subtract(const Duration(hours: 5)),
            read: true,
          ),
        ],
      ),
      NotificationGroup(
        label: 'Yesterday',
        items: [
          AppNotification(
            type: NotificationType.gift,
            title: 'Referral reward earned',
            subtitle: 'You earned \$50 from a friend\'s first challenge.',
            time: '1d',
            createdAt: now.subtract(const Duration(days: 1, hours: 3)),
            read: true,
          ),
        ],
      ),
      NotificationGroup(
        label: 'Earlier',
        items: [
          AppNotification(
            type: NotificationType.info,
            title: 'Challenge started',
            subtitle: 'Your Pipze 2-Step \$100K challenge is now active.',
            time: '4d',
            createdAt: now.subtract(const Duration(days: 4)),
            read: true,
          ),
        ],
      ),
    ];
  }
}
