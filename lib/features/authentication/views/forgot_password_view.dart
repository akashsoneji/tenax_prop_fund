import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/widgets/app_toast.dart';
import '../controllers/auth_controller.dart';
import '../widgets/animated_field.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/glass_card.dart';
import '../../../shared/widgets/app_gradient_button.dart';

/// Forgot password: hero illustration of an inbox, animated entry, post-send
/// success state with a confetti burst and resend countdown.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    final passed = Get.arguments;
    if (passed is String && passed.isNotEmpty) {
      _email.text = passed;
    }
  }
  int _resendIn = 0;
  Timer? _ticker;
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(milliseconds: 700),
  );

  @override
  void dispose() {
    _email.dispose();
    _ticker?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendIn = 60;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _resendIn -= 1;
        if (_resendIn <= 0) t.cancel();
      });
    });
  }

  Future<void> _submit() async {
    final controller = Get.find<AuthController>();
    final ok = await controller.requestPasswordReset(
      email: _email.text.trim(),
    );
    if (!ok || !mounted) return;

    setState(() => _sent = true);
    _confetti.play();
    _startResendTimer();

    AppToast.success(
      'forgot_password.reset_link_sent'.tr,
      title: 'forgot_password.check_inbox'.tr,
    );
    Get.offAllNamed(AppRoutes.login);
  }

  /// Inline SVG-styled fallback so we don't ship a binary Lottie asset the
  /// repo doesn't have. Falls back to a Material icon when even the network
  /// asset is missing in production.
  Widget get _illustration => Container(
        width: 160.w,
        height: 160.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.08),
        ),
        child: LottieBuilder.network(
          'https://assets10.lottiefiles.com/packages/lf20_obhph3sh.json',
          width: 120.w,
          height: 120.h,
          errorBuilder: (_, _, _) => Icon(
            Icons.mark_email_unread_rounded,
            size: 72.w,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        AuthScaffold(
          heroTitle: _sent ? 'forgot_password.check_inbox'.tr : 'forgot_password.title'.tr,
          heroSubtitle: 'forgot_password.subtitle'.tr,
          showTicker: false,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: _illustration),
                SizedBox(height: 16.h),
                AnimatedField(
                  index: 0,
                  child: TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: 'forgot_password.email'.tr,
                      hintText: 'login.email_hint'.tr,
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      filled: true,
                      fillColor:
                          scheme.surfaceContainerHighest.withValues(alpha: 0.85),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 18.h),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(
                            color: scheme.outline.withValues(alpha: 0.18)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide:
                            BorderSide(color: scheme.primary, width: 1.6.w),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                if (_sent)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Text(
                      'forgot_password.spam_tip'.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                Obx(() {
                  final msg = controller.errorMessage.value;
                  return AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: msg == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Text(
                              msg,
                              style: TextStyle(
                                color: scheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  );
                }),
                SizedBox(height: 16.h),
                Obx(
                  () => AppGradientButton(
                    label: _sent
                        ? 'common.resend'.tr
                        : 'forgot_password.send_code'.tr,
                    loading: controller.isLoading.value,
                    onPressed: _sent && _resendIn > 0 ? null : _submit,
                  ),
                ),
                if (_sent) ...[
                  SizedBox(height: 12.h),
                  Center(
                    child: TextButton(
                      onPressed: null,
                      child: Text(
                        '${'common.resend'.tr} ${'otp.resend_in'.tr} ${_resendIn}s',
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Confetti from top-center.
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 24,
            emissionFrequency: 0.05,
            gravity: 0.25,
            colors: [scheme.primary, scheme.secondary, scheme.tertiary],
          ),
        ),
      ],
    );
  }
}