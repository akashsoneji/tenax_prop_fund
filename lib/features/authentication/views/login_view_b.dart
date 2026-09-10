import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../widgets/auth_scaffold.dart';
import '../widgets/glass_card.dart';
import '../widgets/login_form.dart';

/// Layout B: side-by-side marketing panel (left) + glass form card (right).
/// On narrow phones it collapses to a vertical stack so the marketing panel
/// sits above the form. Reuses the SAME LoginForm widget — zero business
/// duplication.
class LoginViewB extends StatelessWidget {
  const LoginViewB({super.key});

  @override
  Widget build(BuildContext context) {
    return MarketingScaffold(
      heroTitle: 'login.hero_title'.tr,
      heroSubtitle: 'app.tagline'.tr,
      child: GlassCard(
        radius: 28.r,
        padding: EdgeInsets.all(24.w),
        child: const LoginForm(),
      ),
    );
  }
}