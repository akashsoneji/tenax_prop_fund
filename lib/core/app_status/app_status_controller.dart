import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logger/app_logger.dart';
import 'app_status_model.dart';
import 'app_status_service.dart';
import 'app_version_service.dart';
import 'force_update_dialog.dart' as force_update;

/// Owns the runtime state derived from `/mobile-app-details` — maintenance
/// mode flag and the force-update dialog. Mirrors the white_label controller
/// so behaviour is identical across the two apps.
class AppStatusController extends GetxController {
  AppStatusController(this._service);

  final AppStatusService _service;

  // Observables consumed by [AppStatusOverlay] and the dialog.
  final RxBool isMaintenanceMode = false.obs;
  final RxBool isUpdateRequired = false.obs;
  final RxBool isForceUpdate = false.obs;
  final RxBool isChecking = false.obs;
  final RxString latestVersion = ''.obs;
  final Rx<AppStatusModel?> statusData = Rx<AppStatusModel?>(null);

  bool _dialogShown = false;
  bool get dialogShown => _dialogShown;
  void resetDialogFlag() => _dialogShown = false;

  static const String _skipKey = 'app_update_skip_timestamp';
  static const Duration _skipDuration = Duration(hours: 6);

  GetStorage get _box => Get.find<GetStorage>();

  /// Merges the incoming payload into the observable state and shows the
  /// maintenance screen or update dialog when required.
  Future<void> handleStatusUpdate(AppStatusModel status) async {
    try {
      isChecking.value = true;
      latestVersion.value = status.appVersion;
      statusData.value = status;

      // later_date promotes a soft update to a force update once the deadline
      // passes. Keeps the "grace period" behaviour identical to the CRM app.
      var computedForce = status.isForceUpdate;
      final later = status.laterDate?.trim();
      if (!computedForce && later != null && later.isNotEmpty) {
        try {
          final deadline = DateTime.parse(later);
          if (DateTime.now().isAfter(deadline)) computedForce = true;
        } catch (e) {
          log.e('AppStatusController: bad later_date "$later": $e');
        }
      }
      isForceUpdate.value = computedForce;

      // Maintenance mode takes priority — the overlay covers the whole app,
      // so no update dialog is needed on top of it.
      if (status.isUnderMaintenance) {
        isMaintenanceMode.value = true;
        isUpdateRequired.value = true;
        return;
      }
      isMaintenanceMode.value = false;

      final needsUpdate = await _service.isUpdateRequired(status.appVersion);
      isUpdateRequired.value = needsUpdate;
      if (!needsUpdate) {
        if (_dialogShown && (Get.isDialogOpen ?? false)) hideForceUpdateDialog();
        return;
      }

      // Soft updates respect the 6-hour skip window.
      if (!computedForce && !await _shouldShowDialog()) {
        log.d('AppStatusController: update skipped within 6h window');
        return;
      }

      if (!_dialogShown || !(Get.isDialogOpen ?? false)) {
        _dialogShown = false;
        showForceUpdateDialog(computedForce);
      }
    } catch (e, st) {
      log.e('AppStatusController: handleStatusUpdate failed',
          error: e, stackTrace: st);
    } finally {
      isChecking.value = false;
    }
  }

  void showForceUpdateDialog(bool force) {
    if (_dialogShown && (Get.isDialogOpen ?? false)) return;
    _dialogShown = true;
    Get.dialog(
      PopScope(
        canPop: !force,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && force) _dialogShown = false;
        },
        child: force_update.ForceUpdateDialog(isForceUpdate: force),
      ),
      barrierDismissible: false,
    );
  }

  void hideForceUpdateDialog() {
    if (!_dialogShown) return;
    if (Get.isDialogOpen ?? false) Get.back(closeOverlays: true);
    _dialogShown = false;
  }

  Future<bool> _shouldShowDialog() async {
    final ts = _box.read<int>(_skipKey);
    if (ts == null) return true;
    final skippedAt = DateTime.fromMillisecondsSinceEpoch(ts);
    if (DateTime.now().difference(skippedAt) >= _skipDuration) {
      await _box.remove(_skipKey);
      return true;
    }
    return false;
  }

  Future<void> skipUpdateFor6Hours() async {
    await _box.write(_skipKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Retry entry-point used by the maintenance screen button.
  Future<void> checkStatus() => _service.checkAppStatus();

  /// Opens the platform store (or backend-provided URL) for the update.
  Future<void> openAppStore() async {
    try {
      final pkg = await AppVersionService.instance.getPackageName();
      String url;
      if (Platform.isAndroid) {
        final override = statusData.value?.updateUrlAndroid;
        url = (override != null && override.isNotEmpty)
            ? override
            : 'https://play.google.com/store/apps/details?id=$pkg';
      } else if (Platform.isIOS) {
        final override = statusData.value?.updateUrlIos;
        url = (override != null && override.isNotEmpty)
            ? override
            : 'https://apps.apple.com/app/id$pkg';
      } else {
        return;
      }
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e, st) {
      log.e('AppStatusController: openAppStore failed', error: e, stackTrace: st);
    }
  }

  @override
  void onClose() {
    hideForceUpdateDialog();
    super.onClose();
  }
}
