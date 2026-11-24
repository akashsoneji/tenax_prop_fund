import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_status/app_status_service.dart';
import '../../../shared/theme/app_text.dart';

/// "By continuing you agree to our Terms & Conditions and Privacy Policy" line
/// shown under the login and register forms. Both URLs come from
/// `GET /mobile-app-details`; a link whose URL is missing is not shown.
class LegalLinks extends StatefulWidget {
  const LegalLinks({super.key});

  @override
  State<LegalLinks> createState() => _LegalLinksState();
}

class _LegalLinksState extends State<LegalLinks> {
  final _service = Get.find<AppStatusService>();
  final _termsTap = TapGestureRecognizer();
  final _privacyTap = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    // Splash normally loads the status; refetch only if that call failed.
    if (_service.status.value == null) _service.checkAppStatus();
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseStyle = AppText.base(
      fontSize: 12.sp,
      color: scheme.onSurface.withValues(alpha: 0.6),
    );
    final linkStyle = AppText.base(
      fontSize: 12.sp,
      color: scheme.primary,
      fontWeight: FontWeight.w600,
    );

    return Obx(() {
      final status = _service.status.value;
      final termsUrl = status?.termsAndConditionsUrl?.trim() ?? '';
      final privacyUrl = status?.privacyPolicyUrl?.trim() ?? '';
      final hasTerms = termsUrl.isNotEmpty;
      final hasPrivacy = privacyUrl.isNotEmpty;
      if (!hasTerms && !hasPrivacy) return const SizedBox.shrink();

      _termsTap.onTap = () => _open(termsUrl);
      _privacyTap.onTap = () => _open(privacyUrl);

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Text.rich(
          TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: '${'legal.agree_prefix'.tr} '),
              if (hasTerms)
                TextSpan(
                  text: 'legal.terms'.tr,
                  style: linkStyle,
                  recognizer: _termsTap,
                ),
              if (hasTerms && hasPrivacy)
                TextSpan(text: ' ${'legal.and'.tr} '),
              if (hasPrivacy)
                TextSpan(
                  text: 'legal.privacy'.tr,
                  style: linkStyle,
                  recognizer: _privacyTap,
                ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      );
    });
  }
}
