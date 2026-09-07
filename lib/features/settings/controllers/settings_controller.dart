import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// User-facing settings (theme mode + locale). Persisted via GetStorage so the
/// choice survives app restarts. App-wide singletons read these on startup.
class SettingsController extends GetxController {
  static const _themeKey = 'theme_mode';
  static const _localeKey = 'locale_code';

  // Read once at construction; callers should use [Get.find<SettingsController>()].
  final ThemeMode themeMode;
  final Locale locale;

  SettingsController._({required this.themeMode, required this.locale});

  factory SettingsController.load() {
    final box = GetStorage();
    final modeName = box.read<String>(_themeKey) ?? 'system';
    final langCode = box.read<String>(_localeKey) ?? 'en';

    return SettingsController._(
      themeMode: _modeFromName(modeName),
      locale: Locale(langCode),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final box = GetStorage();
    await box.write(_themeKey, _nameFromMode(mode));
    Get.changeThemeMode(mode);
    Get.forceAppUpdate();
  }

  Future<void> setLocale(Locale next) async {
    final box = GetStorage();
    await box.write(_localeKey, next.languageCode);
    Get.updateLocale(next);
    Get.forceAppUpdate();
  }

  static ThemeMode _modeFromName(String name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _nameFromMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
