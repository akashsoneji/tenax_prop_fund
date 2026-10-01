// Visual regression guard: renders the shared design system with the REAL
// app theme (AppTheme.lightFromFlavor / darkFromFlavor), the REAL Be Vietnam
// Pro font files and Material icons, at the ScreenUtil design size, then
// compares pixel-for-pixel against PNGs in test/goldens/.
//
// Record a baseline:  flutter test test/goldens --update-goldens
// Check for drift:    flutter test test/goldens
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as gf;

import 'package:tenax_prop_flutter/app/flavor/flavor.dart';
import 'package:tenax_prop_flutter/app/flavor/flavor_config.dart';
import 'package:tenax_prop_flutter/core/localization/app_translations.dart';
import 'package:tenax_prop_flutter/shared/theme/app_theme.dart';

import '../helpers/offline_fonts.dart';
import 'design_gallery.dart';
import 'shared_widgets_gallery.dart';

/// Test fonts default to the Ahem box font. Load real Material icons + Roboto
/// from the Flutter SDK cache so icon glyphs and fallback text are real.
Future<void> _loadSdkFonts() async {
  final sdkRoot = Platform.environment['FLUTTER_ROOT']!;
  final fontsPath = '$sdkRoot/bin/cache/artifacts/material_fonts';

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final name in files) {
      final bytes = File('$fontsPath/$name').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    }
    await loader.load();
  }

  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
  await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);
}

Color _hex(Object? value) => Color(int.parse('FF$value', radix: 16));

/// Builds the flavor's palette from its real `config/flavors/<name>.json`, so
/// the goldens follow the shipped brand colours instead of a copy in the test.
FlavorConfig _configFor(String name) {
  final json = jsonDecode(File('config/flavors/$name.json').readAsStringSync()) as Map<String, dynamic>;
  final darkPrimary = json['DARK_PRIMARY_COLOR'];
  return FlavorConfig(
    flavor: Flavor.fromName(name),
    env: AppEnv.development,
    appName: 'Golden',
    apiBaseUrl: 'https://api.test/api/v1',
    webBaseUrl: 'https://api.test',
    wsUrl: 'wss://ws.test',
    pusherHost: 'ws.test',
    pusherAppKey: 'test-key',
    chartBaseUrl: 'https://api.test/mobile-chart',
    primaryColor: _hex(json['PRIMARY_COLOR']),
    darkPrimaryColor: darkPrimary == null ? null : _hex(darkPrimary),
    secondaryColor: _hex(json['SECONDARY_COLOR']),
    logoAsset: '',
    splashLogoAsset: '',
    featureFlags: const {},
  );
}

Future<void> _pumpGallery(
  WidgetTester tester,
  ThemeData theme, {
  Widget page = const DesignGallery(),
  double height = 1500,
}) async {
  tester.view.physicalSize = Size(375, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        translations: AppTranslations(),
        locale: const Locale('en'),
        theme: theme,
        home: page,
      ),
    ),
  );
  // Let google_fonts finish loading every weight, then repaint with it.
  await tester.runAsync(() => Future.wait(gf.pendingFontFutures.toList()));
  await tester.pump();
  // Entrance animations (AppOptionCard) must finish before the snapshot.
  await tester.pump(const Duration(seconds: 1));
}

/// The flavors that ship. tenax keeps the original baseline file names.
const _flavors = ['tenax', 'alibabafx_prop', 'pipze_funded'];

String _baseline(String flavor, String mode) =>
    flavor == 'tenax' ? 'baseline/gallery_$mode.png' : 'baseline/${flavor}_gallery_$mode.png';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    useOfflineGoogleFonts();
    // google_fonts saves fetched files via path_provider; give it a temp dir.
    final tmp = Directory.systemTemp.createTempSync('gf');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => tmp.path,
    );
    await _loadSdkFonts();
  });

  for (final flavor in _flavors) {
    final brand = _configFor(flavor);

    for (final mode in ['light', 'dark']) {
      ThemeData theme() =>
          mode == 'light' ? AppTheme.lightFromFlavor(brand) : AppTheme.darkFromFlavor(brand);

      testWidgets('design system — $flavor $mode', (tester) async {
        await _pumpGallery(tester, theme());
        await expectLater(find.byType(DesignGallery), matchesGoldenFile(_baseline(flavor, mode)));
      });

      testWidgets('shared widgets — $flavor $mode', (tester) async {
        Get.put<FlavorConfig>(brand);
        addTearDown(Get.reset);
        await _pumpGallery(tester, theme(), page: const SharedWidgetsGallery(), height: 2000);
        await expectLater(
          find.byType(SharedWidgetsGallery),
          matchesGoldenFile('baseline/shared_${flavor}_$mode.png'),
        );
      });
    }
  }
}
