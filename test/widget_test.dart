import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:tenax_prop_flutter/app/flavor/flavor.dart';
import 'package:tenax_prop_flutter/app/flavor/flavor_config.dart';
import 'package:tenax_prop_flutter/features/settings/controllers/settings_controller.dart';
import 'package:tenax_prop_flutter/main.dart';

import 'helpers/offline_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    useOfflineGoogleFonts();
    // GetStorage and google_fonts write through path_provider; give them a temp
    // dir so tests never leave files in the repo root.
    final tmp = Directory.systemTemp.createTempSync('tenax_test');
    addTearDown(() => tmp.deleteSync(recursive: true));
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => tmp.path);

    await GetStorage.init();
    Get.reset();
    Get.put<SettingsController>(SettingsController.load(), permanent: true);
  });

  testWidgets('App builds with a flavor config', (WidgetTester tester) async {
    const config = FlavorConfig(
      flavor: Flavor.tenax,
      env: AppEnv.development,
      appName: 'Test App',
      apiBaseUrl: 'https://api.test/api/v1',
      webBaseUrl: 'https://api.test',
      wsUrl: 'wss://ws.test',
      pusherHost: 'ws.test',
      pusherAppKey: 'test-key',
      chartBaseUrl: 'https://api.test/mobile-chart',
      primaryColor: Color(0xFF2962FF),
      secondaryColor: Color(0xFF00C853),
      logoAsset: '',
      splashLogoAsset: '',
      featureFlags: {},
    );

    await tester.pumpWidget(const TenaxApp(config: config));
    await tester.pump();
    expect(find.text(config.appName), findsWidgets);

    // Let the splash timer fire and navigate so no timer stays pending.
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
