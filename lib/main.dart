import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/bindings/initial_binding.dart';
import 'app/flavor/flavor_config.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'core/localization/app_translations.dart';
import 'features/chart/services/chart_preload_service.dart';
import 'features/settings/controllers/settings_controller.dart';
import 'shared/theme/app_theme.dart';

// Injected at build time via --dart-define (see .vscode/launch.json).
const _flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'tenax');
const _envName = String.fromEnvironment('ENV', defaultValue: 'development');
// Empty by default so each flavor's own host (see FlavorConfig) is used; a
// non-empty --dart-define overrides it for staging/QA builds.
const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
const _wsUrl = String.fromEnvironment('WS_URL');
const _chartBaseUrl = String.fromEnvironment('CHART_BASE_URL');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Draw behind the Android system bars so the 3-button / gesture nav bar area
  // is painted by the app (SafeArea then insets content). The bars themselves
  // stay transparent; icon brightness is handled per-theme via AnnotatedRegion.
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  final config = FlavorConfig.fromEnvironment(
    flavorName: _flavorName,
    envName: _envName,
    apiBaseUrl: _apiBaseUrl,
    wsUrl: _wsUrl,
    chartBaseUrl: _chartBaseUrl,
  );

  // Settings must exist before the first build (GetMaterialApp reads theme +
  // locale from it). The rest of the app-wide singletons are registered by
  // InitialBinding when the first route loads.
  Get.put<SettingsController>(SettingsController.load(), permanent: true);

  // Register the chart preload service synchronously so it is available app-
  // wide, but do NOT start the headless webview yet — HeadlessInAppWebView.run()
  // needs the Flutter engine + platform views to be up, which only happens
  // after runApp(). Starting it before runApp silently defers the warm-up until
  // the app is on screen, defeating the whole point.
  final chartPreload = Get.put<ChartPreloadService>(
    ChartPreloadService(config),
    permanent: true,
  );

  runApp(TenaxApp(config: config));

  // Kick off the background chart warm-up the moment the first frame is up —
  // the earliest point the engine can actually run a headless webview.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    chartPreload.init();
  });
}

class TenaxApp extends StatelessWidget {
  const TenaxApp({super.key, required this.config});

  final FlavorConfig config;

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return GetMaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,

      // Theme — light + dark variants driven by flavor; mode from settings.
      theme: AppTheme.lightFromFlavor(config),
      darkTheme: AppTheme.darkFromFlavor(config),
      themeMode: settings.themeMode,

      // Localization.
      translations: AppTranslations(),
      locale: settings.locale,
      fallbackLocale: const Locale('en'),

      initialBinding: InitialBinding(config),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,

      // Keep the system bar ICON brightness in sync with the active theme so
      // the 3-button / gesture nav bar stays readable in both light and dark.
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}