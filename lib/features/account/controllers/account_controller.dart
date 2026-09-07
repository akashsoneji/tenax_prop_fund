import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../../../core/state/data_state.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/account_models.dart';
import '../repositories/account_repository.dart';

/// The four tabs of the Account detail screen.
enum AccountDetailTab { overview, trading, platform, reset }

/// Backs the Account detail screen. The Account-overview + Trading-overview tabs
/// share one endpoint, so they load into [BaseController]'s
/// `DataState<AccountData>`. Platform & Reset are separate endpoints loaded
/// lazily the first time their tab is opened.
class AccountController extends BaseController<AccountData> {
  AccountController(this._repository);

  final AccountRepository _repository;

  /// Which account this screen is showing (passed via `Get.arguments['id']`).
  late final Object accountId =
      (Get.arguments is Map ? (Get.arguments as Map)['id'] : null) ?? 1;

  final selectedTab = AccountDetailTab.overview.obs;

  /// Whether the master/investor passwords are revealed.
  final revealPassword = false.obs;

  final platform = Rxn<DataState<PlatformData>>(const DataInitial());
  final reset = Rxn<DataState<ResetData>>(const DataInitial());

  @override
  Future<ApiResponse<AccountData>> fetch() =>
      _repository.getOverview(accountId);

  void selectTab(AccountDetailTab tab) {
    selectedTab.value = tab;
    if (tab == AccountDetailTab.platform &&
        platform.value is DataInitial) {
      _loadPlatform();
    } else if (tab == AccountDetailTab.reset && reset.value is DataInitial) {
      _loadReset();
    }
  }

  Future<void> _loadPlatform() async {
    platform.value = const DataLoading();
    final res = await _repository.getPlatform(accountId);
    if (isClosed) return;
    platform.value = res.success && res.data != null
        ? DataSuccess(res.data as PlatformData)
        : DataFailure(res.message ?? 'errors.generic'.tr);
  }

  Future<void> _loadReset() async {
    reset.value = const DataLoading();
    final res = await _repository.getReset(accountId);
    if (isClosed) return;
    reset.value = res.success && res.data != null
        ? DataSuccess(res.data as ResetData)
        : DataFailure(res.message ?? 'errors.generic'.tr);
  }

  Future<void> retryPlatform() => _loadPlatform();
  Future<void> retryReset() => _loadReset();

  void toggleReveal() => revealPassword.toggle();

  void copy(String value, String toastKey) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    AppToast.success(toastKey.tr);
  }
}
