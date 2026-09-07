import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/flavor/flavor_config.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/brand_badge.dart';
import '../widgets/glass_card.dart';
import '../widgets/login_form.dart';

/// Layout A: animated mesh gradient hero + frosted-glass form card.
/// The primary "Sign in" CTA lives INSIDE the form (original position) —
/// not pinned to a bottom bar.
class LoginViewA extends StatelessWidget {
  const LoginViewA({super.key});

  @override
  Widget build(BuildContext context) {
    final config = Get.find<FlavorConfig>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthScaffold(
      heroTitle: 'login.welcome_back'.tr,
      heroSubtitle: config.appName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Center(child: const BrandBadge()),
          const SizedBox(height: 18),
          Text(
            config.appName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'app.tagline'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 22),
          const GlassCard(child: LoginForm()),
        ],
      ),
    );
  }
}
