import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/bindings/initial_binding.dart';
import 'app/flavor/flavor_config.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'core/localization/app_translations.dart';
import 'features/chart/services/chart_preload_service.dart';
import 'features/home/controllers/home_controller.dart';
import 'features/settings/controllers/settings_controller.dart';
import 'shared/theme/app_theme.dart';


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

  // Values come from --dart-define-from-file=config/flavors/<flavor>.json.
  final config = FlavorConfig.fromEnvironment();

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
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
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

          // Returning to the Home shell from any pushed screen refreshes the
          // dashboard silently — the already-rendered data stays on screen and
          // only changed values update (no skeleton, no blank frame).
          routingCallback: (routing) {
            if (routing?.current != AppRoutes.home) return;
            if (!Get.isRegistered<HomeController>()) return;
            Get.find<HomeController>().refreshSilently();
          },

          // Keep the system bar ICON brightness in sync with the active theme so
          // the 3-button / gesture nav bar stays readable in both light and dark.
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            // Clamp the OS font-scale to a narrow band so the layout looks the
            // same across devices. Without this, a phone with a larger system
            // font size enlarges every label, wrapping titles to two lines and
            // pushing content off-screen. 0.9–1.1 keeps accessibility scaling
            // but prevents breakage.
            final mq = MediaQuery.of(context);
              final clamped = mq.textScaler.clamp(
                minScaleFactor: 0.82,
                maxScaleFactor: 0.90,
              );
            return MediaQuery(
              data: mq.copyWith(textScaler: clamped),
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                  statusBarBrightness:
                      isDark ? Brightness.dark : Brightness.light,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarContrastEnforced: false,
                  systemNavigationBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }
}
