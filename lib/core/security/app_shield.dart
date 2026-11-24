import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:freerasp/freerasp.dart' hide PackageInfo;
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/flavor/flavor_config.dart';
import '../logger/app_logger.dart';

/// Why the app refused to run. Each value has a `security.reason_<name>`
/// translation key.
enum SecurityThreat { rooted, hooked, tampered, debugger, emulator }

/// Runtime self-protection (freeRASP): detects rooted/jailbroken devices,
/// Frida-style hooking, re-signed (tampered) builds, attached debuggers and
/// emulators, and blocks the app via [SecurityBlockOverlay].
///
/// Developer options, ADB, VPN and non-Play installs are only reported, not
/// blocked: many genuine users have them on, and APK builds are still
/// distributed outside Play.
class AppShield extends GetxService {
  AppShield(this._config);

  final FlavorConfig _config;

  final Rxn<SecurityThreat> blockedBy = Rxn<SecurityThreat>();

  /// freeRASP rejects an empty hash list, so builds without the real signing
  /// hashes pass the Android SDK debug key and skip the tamper reaction.
  static const _debugCertHash = 'QmKM8ngC4qoozqszQubO75pB4IlPV5A2W91M8/UPy0k=';

  /// Test builds only (`--dart-define=ALLOW_EMULATOR=true`) so QA can run a
  /// release APK on an emulator. Never pass it for store builds.
  static const _allowEmulator = bool.fromEnvironment('ALLOW_EMULATOR');

  Future<void> start() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (_allowEmulator) {
      log.w('AppShield: disabled for emulator testing (ALLOW_EMULATOR)');
      return;
    }
    if (Platform.isIOS && _config.iosTeamId.isEmpty) {
      log.w('AppShield: IOS_TEAM_ID missing, runtime protection not started');
      return;
    }

    final packageName = (await PackageInfo.fromPlatform()).packageName;
    final enforceIntegrity = kReleaseMode && _config.signingCertHashes.isNotEmpty;

    try {
      await Talsec.instance.attachListener(
        ThreatCallback(
          onPrivilegedAccess: () => _block(SecurityThreat.rooted),
          onHooks: () => _block(SecurityThreat.hooked),
          onAppIntegrity:
              enforceIntegrity ? () => _block(SecurityThreat.tampered) : null,
          onDebug: kReleaseMode ? () => _block(SecurityThreat.debugger) : null,
          onSimulator:
              kReleaseMode ? () => _block(SecurityThreat.emulator) : null,
          onUnofficialStore: () => log.w('AppShield: installed outside store'),
        ),
      );
      await Talsec.instance.start(
        TalsecConfig(
          androidConfig: Platform.isAndroid
              ? AndroidConfig(
                  packageName: packageName,
                  certificateHashes: _config.signingCertHashes.isNotEmpty
                      ? _config.signingCertHashes
                      : const [_debugCertHash],
                )
              : null,
          iosConfig: Platform.isIOS
              ? IOSConfig(
                  appBundleIds: [packageName],
                  appTeamId: _config.iosTeamId,
                )
              : null,
          watcherMail: _config.securityWatcherMail,
          isProd: kReleaseMode,
          killOnBypass: kReleaseMode,
        ),
      );
    } catch (e, st) {
      log.e('AppShield: failed to start', error: e, stackTrace: st);
    }
  }

  void _block(SecurityThreat threat) {
    log.w('AppShield: blocked (${threat.name})');
    blockedBy.value ??= threat;
  }
}
