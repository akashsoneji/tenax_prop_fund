import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:tenax_prop_flutter/app/flavor/flavor_config.dart';
import 'package:tenax_prop_flutter/features/settings/controllers/settings_controller.dart';
import 'package:tenax_prop_flutter/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // GetStorage needs path_provider; stub the channel to a temp dir for tests.
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => '.');

    await GetStorage.init();
    Get.reset();
    Get.put<SettingsController>(SettingsController.load(), permanent: true);
  });

  testWidgets('App builds with a flavor config', (WidgetTester tester) async {
    final config = FlavorConfig.fromEnvironment(
      flavorName: 'client_a',
      envName: 'development',
      apiBaseUrl: 'https://api.test',
      wsUrl: 'wss://ws.test',
    );

    await tester.pumpWidget(TenaxApp(config: config));
    await tester.pump();
    expect(find.text(config.appName), findsWidgets);

    // Let the splash timer fire and navigate so no timer stays pending.
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}