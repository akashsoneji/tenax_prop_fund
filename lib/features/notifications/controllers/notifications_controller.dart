import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/notification_models.dart';
import '../repositories/notifications_repository.dart';

/// Drives the Notifications screen. Data loading (skeleton / error / empty) is
/// handled by [BaseController] via a single `DataState<List<NotificationGroup>>`;
/// this class adds the screen's UI state (the unread flag + count) and the
/// mark-read actions, all backed by the live API.
class NotificationsController extends BaseController<List<NotificationGroup>> {
  NotificationsController(this._repository);

  final NotificationsRepository _repository;

  final hasUnread = false.obs;
  final unreadCount = 0.obs;

  @override
  Future<ApiResponse<List<NotificationGroup>>> fetch() =>
      _repository.getNotifications();

  @override
  bool isEmpty(List<NotificationGroup> data) => data.isEmpty;

  @override
  void onInit() {
    super.onInit();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final res = await _repository.getUnreadCount();
    if (isClosed) return;
    if (res.success && res.data != null) {
      unreadCount.value = res.data!;
      hasUnread.value = res.data! > 0;
    }
  }

  Future<void> markAllRead() async {
    final res = await _repository.markAllRead();
    if (isClosed) return;
    if (res.success) {
      hasUnread.value = false;
      unreadCount.value = 0;
      await load();
    }
  }
}
