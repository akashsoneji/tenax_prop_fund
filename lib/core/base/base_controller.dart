import 'package:get/get.dart';

import '../network/api_response.dart';
import '../state/data_state.dart';

/// Base class for every feature controller that loads async data.
///
/// It owns a single reactive [DataState] and a [runGuarded] helper that drives
/// the loading -> success/empty/failure transitions in one place, so no screen
/// re-implements try/catch/loading toggles. All state writes are guarded by
/// [isClosed] so a late async completion after the view is gone can never throw.
abstract class BaseController<T> extends GetxController {
  /// The current screen state. Views observe this through `DataStateBuilder`.
  final Rxn<DataState<T>> _state = Rxn<DataState<T>>(const DataInitial());

  DataState<T> get state => _state.value ?? const DataInitial();
  Rxn<DataState<T>> get stateRx => _state;

  /// Override to provide the data fetch. Return an [ApiResponse] from the
  /// repository. Returning a `null`/empty payload flips the screen to empty.
  Future<ApiResponse<T>> fetch();

  /// Whether [data] should be treated as "empty" (drives the empty state).
  /// Override for lists/maps; default treats null as empty.
  bool isEmpty(T data) => data == null;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// First load (or retry): shows the skeleton, then resolves.
  Future<void> load() async {
    _set(const DataLoading());
    await _run();
  }

  /// Pull-to-refresh: does NOT drop to the skeleton if we already have data,
  /// so the list stays visible while refreshing.
  Future<void> refreshData() async {
    if (!state.isSuccess) _set(const DataLoading());
    await _run();
  }

  /// "Screen appeared again" refresh (tab re-select, route return, app resume).
  ///
  /// Delegates to [refreshData], so already-rendered data stays on screen and
  /// only the changed values update — no skeleton flash. Overlapping triggers
  /// (e.g. tab switch + route return in the same frame) collapse into one call.
  Future<void> refreshSilently() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      await refreshData();
    } finally {
      _refreshing = false;
    }
  }

  bool _refreshing = false;

  Future<void> _run() async {
    try {
      final res = await fetch();
      if (isClosed) return;
      if (!res.success || res.data == null) {
        _set(DataFailure(res.message ?? 'errors.generic'.tr));
        return;
      }
      final data = res.data as T;
      _set(isEmpty(data) ? const DataEmpty() : DataSuccess(data));
    } catch (e) {
      if (isClosed) return;
      _set(DataFailure(e.toString()));
    }
  }

  void _set(DataState<T> next) {
    if (isClosed) return;
    _state.value = next;
  }
}
