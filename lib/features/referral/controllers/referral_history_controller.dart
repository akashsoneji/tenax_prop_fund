import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../../../core/state/data_state.dart';
import '../models/referral_models.dart';
import '../repositories/referral_repository.dart';

/// Drives the paginated referral commission history
/// (`GET /growth/referrals/commissions?page=`). First page goes through
/// [BaseController] (skeleton / empty / error); later pages are appended by
/// [loadMore] while the list stays visible.
class ReferralHistoryController extends BaseController<List<Referral>> {
  ReferralHistoryController(this._repository);

  final ReferralRepository _repository;

  /// How close to the end of the list (in rows) the next page is requested.
  static const prefetchThreshold = 3;

  final _items = <Referral>[];
  PageMeta _meta = PageMeta.empty;

  final isLoadingMore = false.obs;
  bool get hasMore => _meta.hasNext;

  /// Server-side total of all commissions (not just the loaded pages).
  int get total => _meta.total;

  @override
  Future<ApiResponse<List<Referral>>> fetch() async {
    final res = await _repository.getCommissions(page: 1);
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
  bool isEmpty(List<Referral> data) => data.isEmpty;

  /// Called by the list when a row within [prefetchThreshold] of the end is
  /// built. Guards make repeated calls from the same frame a no-op.
  void onRowBuilt(int index) {
    if (isLoadingMore.value || !hasMore) return;
    if (index < _items.length - prefetchThreshold) return;
    // Called from itemBuilder: flipping isLoadingMore synchronously would
    // mark the footer Obx dirty mid-build, so defer past this frame.
    Future.microtask(loadMore);
  }

  /// Loads the next page and appends it, keeping the list visible.
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore) return;
    isLoadingMore.value = true;
    final res = await _repository.getCommissions(page: _meta.currentPage + 1);
    if (isClosed) return;
    if (res.success && res.data != null) {
      _items.addAll(res.data!.items);
      _meta = res.data!.meta;
      stateRx.value = DataSuccess(List.of(_items));
    }
    isLoadingMore.value = false;
  }
}
