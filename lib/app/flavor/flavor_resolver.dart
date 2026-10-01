import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/authentication/views/login_view_a.dart';
import 'flavor.dart';
import 'flavor_config.dart';

/// One place that turns the active flavor into a widget for any screen.
///
/// Every flavor (tenax, alibabafx_prop, pipze_funded) ships the SAME UI and the
/// same controllers; flavors differ only by config (colours, logo, name, URLs).
/// A flavor gets its own screen only when that is explicitly requested — then
/// add a `<Screen>View<Flavor>` under `features/<f>/views/flavor_overrides/`
/// (built on the same controller) and register it here via [resolve].
///
/// This keeps `if (flavor == …)` out of individual widgets: the decision lives
/// here, screen by screen.
class FlavorResolver {
  const FlavorResolver._();

  static Flavor get flavor => Get.find<FlavorConfig>().flavor;

  /// The active flavor's display name (e.g. "Tenax Prop", "Pipze Funded"). Use
  /// this anywhere the brand name appears inside user-facing copy so it follows
  /// the selected white-label flavor instead of being hardcoded.
  static String get appName => Get.find<FlavorConfig>().appName;

  /// Returns the override registered for the active flavor, or [common] when
  /// this flavor has no override for the screen.
  ///
  /// Usage in a route:
  /// ```dart
  /// page: () => FlavorResolver.resolve(
  ///   common: const DashboardView(),
  ///   overrides: {
  ///     Flavor.pipzeFunded: const DashboardViewPipze(), // only pipze differs
  ///   },
  /// ),
  /// ```
  static Widget resolve({
    required Widget common,
    Map<Flavor, Widget> overrides = const {},
  }) {
    return overrides[flavor] ?? common;
  }

  /// Same idea but lazy — use when building each variant is expensive or has
  /// side effects, so only the selected one is constructed.
  static Widget resolveBuilder({
    required Widget Function() common,
    Map<Flavor, Widget Function()> overrides = const {},
  }) {
    final builder = overrides[flavor];
    return builder != null ? builder() : common();
  }

  // ---- Concrete per-screen decisions -------------------------------------

  /// Login screen. All flavors share [LoginViewA]; add an override here only
  /// when a flavor-specific login design is requested.
  static Widget loginView() => resolve(common: const LoginViewA());
}
