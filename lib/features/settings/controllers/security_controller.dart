import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/security_models.dart';
import '../repositories/security_repository.dart';

/// Backs the Security section of the Settings screen. Loading/error/empty is
/// handled by [BaseController] through `DataState<SecuritySettings>`; this class
/// adds the toggle state (optimistic, reverted on failure) and the busy flags
/// each action sheet binds its button to.
class SecurityController extends BaseController<SecuritySettings> {
  SecurityController(this._repository);

  final SecurityRepository _repository;

  final loginAlerts = false.obs;
  final withdrawalConfirmation = false.obs;
  final platformLock = false.obs;

  final savingPrefs = false.obs;
  final savingPassword = false.obs;
  final savingBeneficiary = false.obs;
  final enrolling = false.obs;
  final confirming2fa = false.obs;
  final disabling2fa = false.obs;
  final loadingRecoveryCodes = false.obs;

  @override
  Future<ApiResponse<SecuritySettings>> fetch() async {
    final res = await _repository.getSecurity();
    final data = res.data;
    if (data != null) _applyPrefs(data.prefs);
    return res;
  }

  void _applyPrefs(SecurityPrefs prefs) {
    loginAlerts.value = prefs.loginAlerts;
    withdrawalConfirmation.value = prefs.withdrawalConfirmation;
    platformLock.value = prefs.platformLock;
  }

  SecurityPrefs get _currentPrefs => SecurityPrefs(
        loginAlerts: loginAlerts.value,
        withdrawalConfirmation: withdrawalConfirmation.value,
        platformLock: platformLock.value,
      );

  /// Flips one toggle immediately, then persists. A failed save reverts the
  /// switch so the UI never claims a preference the server did not accept.
  Future<void> setPref({
    bool? loginAlerts,
    bool? withdrawalConfirmation,
    bool? platformLock,
  }) async {
    if (savingPrefs.value) return;
    final previous = _currentPrefs;
    final next = previous.copyWith(
      loginAlerts: loginAlerts,
      withdrawalConfirmation: withdrawalConfirmation,
      platformLock: platformLock,
    );
    _applyPrefs(next);

    savingPrefs.value = true;
    final res = await _repository.savePrefs(next);
    savingPrefs.value = false;
    if (isClosed) return;

    if (!res.success) {
      _applyPrefs(previous);
      AppToast.error(res.message ?? 'settings.security.save_failed'.tr);
      return;
    }
    AppToast.success('settings.security.prefs_saved'.tr);
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) =>
      _runAction(
        savingPassword,
        () => _repository.changePassword(
          currentPassword: currentPassword,
          password: password,
          passwordConfirmation: passwordConfirmation,
        ),
      );

  Future<bool> saveBeneficiary({
    required String fullName,
    required String relationship,
    required String email,
    required String mobile,
  }) =>
      _runAction(
        savingBeneficiary,
        () => _repository.saveBeneficiary(
          fullName: fullName,
          relationship: relationship,
          email: email,
          mobile: mobile,
        ),
      );

  Future<TwoFactorEnrolment?> startTwoFactorEnrolment() async {
    if (enrolling.value) return null;
    enrolling.value = true;
    final res = await _repository.enrolTwoFactor();
    enrolling.value = false;
    if (isClosed) return null;
    if (!res.success || res.data == null) {
      AppToast.error(res.message ?? 'settings.security.save_failed'.tr);
      return null;
    }
    return res.data;
  }

  Future<bool> confirmTwoFactor({
    required String secret,
    required String code,
  }) async {
    final ok = await _runAction(
      confirming2fa,
      () => _repository.confirmTwoFactor(secret: secret, code: code),
    );
    if (ok) await refreshData();
    return ok;
  }

  Future<bool> disableTwoFactor(String currentPassword) async {
    final ok = await _runAction(
      disabling2fa,
      () => _repository.disableTwoFactor(currentPassword),
    );
    if (ok) await refreshData();
    return ok;
  }

  Future<List<String>?> recoveryCodes(String currentPassword) async {
    if (loadingRecoveryCodes.value) return null;
    loadingRecoveryCodes.value = true;
    final res = await _repository.regenerateRecoveryCodes(currentPassword);
    loadingRecoveryCodes.value = false;
    if (isClosed) return null;
    if (!res.success || res.data == null) {
      AppToast.error(res.message ?? 'settings.security.save_failed'.tr);
      return null;
    }
    await refreshData();
    return res.data;
  }

  /// Shared shape for the sheet actions: guard against double submit, toast the
  /// server's own message either way, and report whether the sheet may close.
  Future<bool> _runAction(
    RxBool busy,
    Future<ApiResponse<String>> Function() action,
  ) async {
    if (busy.value) return false;
    busy.value = true;
    final res = await action();
    busy.value = false;
    if (isClosed) return res.success;

    final message = res.message;
    if (!res.success) {
      AppToast.error(message ?? 'settings.security.save_failed'.tr);
      return false;
    }
    if (message != null && message.isNotEmpty) AppToast.success(message);
    return true;
  }
}
