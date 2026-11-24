import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../logger/app_logger.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'app_status_controller.dart';
import 'app_status_model.dart';
import 'app_version_service.dart';

/// Fetches the mobile app status (maintenance flag + latest version + update
/// URLs) and forwards the parsed model to [AppStatusController].
class AppStatusService extends GetxService {
  /// Last successfully loaded status; screens read the legal URLs from it.
  final Rxn<AppStatusModel> status = Rxn<AppStatusModel>();

  /// Hits `GET /mobile-app-details`, parses the standard `{success, data}`
  /// envelope and pushes the result into the controller. Returns null on any
  /// failure — the controller is intentionally not touched in that case so a
  /// transient error never hides an already-shown update dialog.
  Future<AppStatusModel?> checkAppStatus() async {
    try {
      await AppVersionService.instance.initialize();

      final res = await Get.find<ApiClient>().get<dynamic>(
        ApiEndpoints.mobileAppDetails,
      );

      final payload = _extractPayload(res.data);
      if (payload == null) {
        log.e('AppStatusService: could not parse mobile-app-details payload');
        return null;
      }

      final loaded = AppStatusModel.fromJson(payload);
      log.d('AppStatusService: loaded $loaded');
      status.value = loaded;

      if (Get.isRegistered<AppStatusController>()) {
        await Get.find<AppStatusController>().handleStatusUpdate(loaded);
      }
      return loaded;
    } on DioException catch (e) {
      log.e('AppStatusService: dio error ${e.message}');
      return null;
    } catch (e, st) {
      log.e('AppStatusService: unexpected error', error: e, stackTrace: st);
      return null;
    }
  }

  /// Envelope has `{success, message, data:{...}}`; be defensive and accept
  /// a flat body too so mocks/dev fixtures work without a wrapper.
  Map<String, dynamic>? _extractPayload(dynamic raw) {
    Map<String, dynamic>? asMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    final top = asMap(raw);
    if (top == null) return null;
    if (top.containsKey('app_version')) return top;
    final inner = asMap(top['data']);
    if (inner != null) return inner;
    return null;
  }

  /// True when the backend version is strictly higher than the installed one.
  Future<bool> isUpdateRequired(String apiVersion) async {
    try {
      final installed = await AppVersionService.instance.getVersion();
      return _compare(installed, apiVersion) < 0;
    } catch (e) {
      log.e('AppStatusService: version compare failed: $e');
      return false;
    }
  }

  int _compare(String a, String b) {
    List<int> parts(String v) {
      final cleaned = v.trim().replaceFirst(RegExp(r'^[vV]'), '');
      return cleaned.split('.').map((raw) {
        final m = RegExp(r'^\d+').firstMatch(raw.trim());
        return int.tryParse(m?.group(0) ?? '') ?? 0;
      }).toList();
    }

    final ap = parts(a);
    final bp = parts(b);
    while (ap.length < bp.length) {
      ap.add(0);
    }
    while (bp.length < ap.length) {
      bp.add(0);
    }
    for (var i = 0; i < ap.length; i++) {
      final d = ap[i] - bp[i];
      if (d != 0) return d;
    }
    return 0;
  }
}
