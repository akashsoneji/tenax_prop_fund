import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../../../core/state/data_state.dart';
import '../models/notification_models.dart';
import '../repositories/notifications_repository.dart';

/// Drives the Notifications screen. Data loading (skeleton / error / empty) is
/// handled by [BaseController] via a single `DataState<List<NotificationGroup>>`;
/// this class adds the screen's UI state (the unread badge, pagination and the
/// preferences sheet), all backed by the live `/notifications` API.
class NotificationsController extends BaseController<List<NotificationGroup>> {
  NotificationsController(this._repository);

  final NotificationsRepository _repository;

  final hasUnread = false.obs;
  final unreadCount = 0.obs;

  /// Flat, newest-first backing list; the view renders it grouped by date.
  final _items = <AppNotification>[];
  PageMeta _meta = PageMeta.empty;

  final isLoadingMore = false.obs;
  bool get hasMore => _meta.hasNext;

  // Preferences sheet state.
  final prefsState = Rxn<NotificationPreferences>();
  final prefsLoading = false.obs;
  final prefsSaving = false.obs;

  @override
  Future<ApiResponse<List<NotificationGroup>>> fetch() async {
    final res = await _repository.getNotifications(page: 1);
    if (!res.success || res.data == null) {
      return ApiResponse.failure(res.message ?? 'errors.generic'.tr);
    }
    _items
      ..clear()
      ..addAll(res.data!.items);
    _meta = res.data!.meta;
    return ApiResponse.success(NotificationGroup.group(_items));
  }

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
      _setUnread(res.data!);
    }
  }

  void _setUnread(int count) {
    unreadCount.value = count;
    hasUnread.value = count > 0;
  }

  void _publishGroups() {
    if (isClosed) return;
    stateRx.value = DataSuccess(NotificationGroup.group(List.of(_items)));
  }

  /// Loads the next page and appends it, keeping the list visible.
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore) return;
    isLoadingMore.value = true;
    final res = await _repository.getNotifications(page: _meta.currentPage + 1);
    if (isClosed) return;
    if (res.success && res.data != null) {
      _items.addAll(res.data!.items);
      _meta = res.data!.meta;
      _publishGroups();
    }
    isLoadingMore.value = false;
  }

  /// Marks a single row read (optimistic) and syncs the unread badge.
  Future<void> markRead(AppNotification n) async {
    if (n.read) return;
    final index = _items.indexWhere((e) => e.id == n.id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(read: true);
      _publishGroups();
    }
    final res = await _repository.markRead(n.id);
    if (isClosed) return;
    if (res.success && res.data != null) {
      _setUnread(res.data!);
    }
  }

  Future<void> markAllRead() async {
    final res = await _repository.markAllRead();
    if (isClosed) return;
    if (res.success) {
      for (var i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(read: true);
      }
      _setUnread(0);
      _publishGroups();
    }
  }

  // -------------------------------------------------------------------------
  // Preferences
  // -------------------------------------------------------------------------
  Future<void> loadPreferences() async {
    prefsLoading.value = true;
    final res = await _repository.getPreferences();
    if (isClosed) return;
    if (res.success && res.data != null) {
      prefsState.value = res.data;
    }
    prefsLoading.value = false;
  }

  void togglePref(String key, {bool? database, bool? broadcast, bool? mail}) {
    final current = prefsState.value;
    if (current == null) return;
    final updated = current.items
        .map(
          (i) => i.key == key
              ? i.copyWith(database: database, broadcast: broadcast, mail: mail)
              : i,
        )
        .toList();
    prefsState.value = NotificationPreferences(items: updated);
  }

  Future<void> savePreferences() async {
    final current = prefsState.value;
    if (current == null) return;
    prefsSaving.value = true;
    await _repository.savePreferences(current);
    if (isClosed) return;
    prefsSaving.value = false;
  }
}
