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
import 'package:tenax_prop_flutter/shared/widgets/app_bottom_sheet.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_brand_badge.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_button.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_card.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_coming_soon.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_icon_button.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_label.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_status_pill.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_option_card.dart';
import 'package:tenax_prop_flutter/shared/widgets/history/app_history_empty.dart';
import 'package:tenax_prop_flutter/shared/widgets/history/app_history_row.dart';
import 'package:tenax_prop_flutter/shared/widgets/history/app_load_more_button.dart';
import 'package:tenax_prop_flutter/shared/widgets/market/app_metric_strip.dart';
import 'package:tenax_prop_flutter/shared/widgets/market/app_price_tile.dart';
import 'package:tenax_prop_flutter/shared/widgets/market/app_symbol_card.dart';

import '../helpers/offline_fonts.dart';
import 'shared_widgets_gallery.dart';

/// Layout checks for the shared-widgets gallery: nothing overflows, nothing
/// is clipped off the page, and every widget renders at a sane size — on a
/// narrow phone (320 wide) as well as the design width.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    useOfflineGoogleFonts();
    final tmp = Directory.systemTemp.createTempSync('gf');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => tmp.path,
    );
  });

  for (final width in [320.0, 375.0]) {
    testWidgets('shared widgets lay out cleanly at ${width.toInt()}px', (tester) async {
      Get.put<FlavorConfig>(FlavorConfig(
        flavor: Flavor.tenax,
        env: AppEnv.development,
        appName: 'Test',
        apiBaseUrl: 'https://api.test/api/v1',
        webBaseUrl: 'https://api.test',
        wsUrl: 'wss://ws.test',
        pusherHost: 'ws.test',
        pusherAppKey: 'k',
        chartBaseUrl: 'https://api.test/mobile-chart',
        primaryColor: const Color(0xFF5F259E),
        secondaryColor: const Color(0xFF00C2A8),
        logoAsset: '',
        splashLogoAsset: '',
        featureFlags: const {},
      ));
      addTearDown(Get.reset);
      tester.view.physicalSize = Size(width, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          theme: AppTheme.lightFromFlavor(Get.find<FlavorConfig>()),
          home: const SharedWidgetsGallery(),
        ),
      ));
      await tester.runAsync(() => Future.wait(gf.pendingFontFutures.toList()));
      await tester.pump(const Duration(seconds: 1));

      // RenderFlex overflow and any other build/layout error surface here.
      expect(tester.takeException(), isNull);

      final page = tester.getRect(find.byType(SharedWidgetsGallery));
      for (final type in [
        AppBrandBadge, AppButton, AppSymbolCard, AppSymbolQuote, AppPriceTile,
        AppMetricStrip, AppOptionCard, AppHistoryRow, AppLoadMoreButton,
        AppHistoryEmpty, AppBottomSheet, AppSheetGrabber, AppComingSoon,
        AppStatusPill, AppIconButton, AppCard, AppLabel,
      ]) {
        final finder = find.byType(type);
        expect(finder, findsWidgets, reason: '$type should render');
        for (final element in finder.evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget).first);
          expect(rect.width, greaterThan(0), reason: '$type has zero width');
          expect(rect.height, greaterThan(0), reason: '$type has zero height');
          expect(rect.left, greaterThanOrEqualTo(page.left - 0.5), reason: '$type spills left');
          expect(rect.right, lessThanOrEqualTo(page.right + 0.5), reason: '$type spills right');
        }
      }

      // Full-width widgets really fill the content width (16.w padding each side).
      final content = page.width - 2 * 16 * (width / 375);
      for (final type in [AppSymbolCard, AppOptionCard]) {
        expect(tester.getSize(find.byType(type)).width, closeTo(content, 1), reason: '$type width');
      }
      // Sell and Buy tiles split the row evenly.
      final tiles = find.byType(AppPriceTile);
      expect(tester.getSize(tiles.at(0)).width, closeTo(tester.getSize(tiles.at(1)).width, 0.5));
    });
  }
}
