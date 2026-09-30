import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/authentication/views/login_view_a.dart';
import '../../features/authentication/views/login_view_b.dart';
import 'flavor.dart';
import 'flavor_config.dart';

/// One place that turns the active flavor into a widget for any screen.
///
/// The mental model the app follows:
///   • `tenax` (Tenax Prop) is the BASE. Every screen has a default design here.
///   • Any other flavor reuses that default UNLESS it registers an override for
///     that specific screen.
///
/// So a screen can be:
///   1. Fully common  -> just build the widget directly, don't call the resolver.
///   2. Common with a few flavor variants -> call [resolve] with `overrides`.
///
/// This keeps `if (flavor == clientB)` out of individual widgets: the decision
/// lives here, screen by screen.
class FlavorResolver {
  const FlavorResolver._();

  static Flavor get flavor => Get.find<FlavorConfig>().flavor;

  /// The active flavor's display name (e.g. "Tenax Prop", "Client A"). Use this
  /// anywhere the brand name appears inside user-facing copy so it follows the
  /// selected white-label flavor instead of being hardcoded.
  static String get appName => Get.find<FlavorConfig>().appName;

  /// Flavors that ship the full Tenax Prop design (Accounts bottom tab,
  /// settings button in the Home header). They differ only by config —
  /// logo, URLs, app name.
  static const Set<Flavor> _tenaxDesignFlavors = {
    Flavor.tenax,
    Flavor.alibabafxProp,
  };

  static bool get usesTenaxDesign => _tenaxDesignFlavors.contains(flavor);

  /// Returns the override registered for the active flavor, or [common] when
  /// this flavor has no override for the screen. `common` is the Tenax Prop
  /// (base) design that every flavor falls back to.
  ///
  /// Usage in a route:
  /// ```dart
  /// page: () => FlavorResolver.resolve(
  ///   common: const DashboardView(),          // Tenax Prop + anyone without override
  ///   overrides: {
  ///     Flavor.clientB: const DashboardViewB(), // only client_b differs
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

  /// Login screen. Tenax Prop + client_a + client_c share LoginViewA;
  /// client_b uses its own layout. Content/controller are identical.
  static Widget loginView() => resolve(
        common: const LoginViewA(),
        overrides: const {
          Flavor.clientB: LoginViewB(),
        },
      );
}
