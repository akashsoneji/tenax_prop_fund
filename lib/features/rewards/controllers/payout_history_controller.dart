import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../../../core/state/data_state.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/reward_models.dart';
import '../repositories/rewards_repository.dart';

/// Status filters offered on the Payout history tab, in display order. The
/// value is sent as `?status=` to `GET /finance/payouts`.
const payoutHistoryFilters = <String>[
  'all',
  'pending',
  'approved',
  'paid',
  'rejected',
  'cancelled',
];

/// Drives the Rewards → Payout history tab (`GET /finance/payouts`).
///
/// Page 1 goes through [BaseController] (skeleton / empty / error). Later
/// pages are appended by [loadMore], which the view triggers when the user
/// scrolls near the bottom, so the list keeps growing while it stays visible.
class PayoutHistoryController extends BaseController<List<PayoutHistoryItem>> {
  PayoutHistoryController(this._repository);

  final RewardsRepository _repository;

  final filter = 'all'.obs;
  final isLoadingMore = false.obs;
  final cancellingId = RxnInt();

  final _items = <PayoutHistoryItem>[];
  PageMeta _meta = PageMeta.empty;

  bool get hasMore => _meta.hasNext;

  /// Server-side total for the active filter (not just loaded pages).
  int get total => _meta.total;

  @override
  Future<ApiResponse<List<PayoutHistoryItem>>> fetch() async {
    final res = await _repository.getPayouts(status: filter.value, page: 1);
    if (!res.success || res.data == null) {
      return ApiResponse.failure(res.message ?? 'errors.generic'.tr);
    }
    _items
      ..clear()
      ..addAll(res.data!.items);
    _meta = res.data!.meta;
    return ApiResponse.success(List.of(_items));
  }

  @override
  bool isEmpty(List<PayoutHistoryItem> data) => data.isEmpty;

  /// Switches the status filter and reloads from page 1.
  void setFilter(String status) {
    if (filter.value == status) return;
    filter.value = status;
    _meta = PageMeta.empty;
    load();
  }

  /// Appends the next page. Safe to call repeatedly from scroll events: it is
  /// a no-op while a page is in flight or once the last page is loaded.
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore || !state.isSuccess) return;
    isLoadingMore.value = true;
    final requestedFilter = filter.value;
    final res = await _repository.getPayouts(
      status: requestedFilter,
      page: _meta.currentPage + 1,
    );
    if (isClosed) return;
    isLoadingMore.value = false;
    // The user switched filter while this page was loading — drop it.
    if (requestedFilter != filter.value) return;
    if (res.success && res.data != null) {
      _items.addAll(res.data!.items);
      _meta = res.data!.meta;
      stateRx.value = DataSuccess(List.of(_items));
    }
  }

  /// Cancels a pending request, then reloads page 1 so status + totals match
  /// the server.
  Future<void> cancel(PayoutHistoryItem item) async {
    if (cancellingId.value != null) return;
    cancellingId.value = item.id;
    final res = await _repository.cancelPayout(item.id);
    if (isClosed) return;
    cancellingId.value = null;
    if (res.success) {
      AppToast.success('rewards.history_cancel_success'.tr);
      refreshData();
    } else {
      AppToast.error(res.message ?? 'rewards.cancel_failed'.tr);
    }
  }
}
