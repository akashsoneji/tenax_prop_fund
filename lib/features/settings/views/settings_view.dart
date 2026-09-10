import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/platform/platform_info.dart';
import '../controllers/settings_controller.dart';

/// Lets the user pick app theme + language. Changes are persisted via
/// SettingsController and take effect immediately (Get rebuilds GetMaterialApp).
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr)),
      body: ListView(
        children: [
          ListTile(
            title: Text('settings.theme'.tr),
            subtitle: Text(_themeLabel(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickTheme(context, settings),
          ),
          Divider(height: 1.h),
          ListTile(
            title: Text('settings.language'.tr),
            subtitle: Text(_langLabel(settings.locale.languageCode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickLang(context, settings),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'settings.theme_light'.tr;
      case ThemeMode.dark:
        return 'settings.theme_dark'.tr;
      case ThemeMode.system:
        return 'settings.theme_system'.tr;
    }
  }

  String _langLabel(String code) {
    switch (code) {
      case 'hi':
        return 'settings.language_hi'.tr;
      case 'en':
      default:
        return 'settings.language_en'.tr;
    }
  }

  Future<void> _pickTheme(BuildContext context, SettingsController s) async {
    if (PlatformInfo.isIOS) {
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: Text('settings.theme'.tr),
          actions: [
            for (final m in ThemeMode.values)
              CupertinoActionSheetAction(
                onPressed: () {
                  s.setThemeMode(m);
                  Navigator.pop(context);
                },
                child: Text(_themeLabel(m)),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            isDestructiveAction: true,
            child: Text('common.cancel'.tr),
          ),
        ),
      );
    } else {
      final selected = await showDialog<ThemeMode>(
        context: context,
        builder: (_) => SimpleDialog(
          title: Text('settings.theme'.tr),
          children: [
            for (final m in ThemeMode.values)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, m),
                child: Text(_themeLabel(m)),
              ),
          ],
        ),
      );
      if (selected != null) s.setThemeMode(selected);
    }
  }

  Future<void> _pickLang(BuildContext context, SettingsController s) async {
    final langs = const [Locale('en'), Locale('hi')];
    if (PlatformInfo.isIOS) {
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: Text('settings.language'.tr),
          actions: [
            for (final l in langs)
              CupertinoActionSheetAction(
                onPressed: () {
                  s.setLocale(l);
                  Navigator.pop(context);
                },
                child: Text(_langLabel(l.languageCode)),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            isDestructiveAction: true,
            child: Text('common.cancel'.tr),
          ),
        ),
      );
    } else {
      final selected = await showDialog<Locale>(
        context: context,
        builder: (_) => SimpleDialog(
          title: Text('settings.language'.tr),
          children: [
            for (final l in langs)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, l),
                child: Text(_langLabel(l.languageCode)),
              ),
          ],
        ),
      );
      if (selected != null) s.setLocale(selected);
    }
  }
}