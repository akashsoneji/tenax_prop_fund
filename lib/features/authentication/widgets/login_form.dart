import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../controllers/auth_controller.dart';
import '../widgets/animated_field.dart';
import '../widgets/biometric_button.dart';

/// Reusable login form. Both flavor layouts embed this same widget — the
/// business inputs and the controller call are identical; only the surrounding
/// layout differs per flavor.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _shake = ShakeController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Public trigger for the parent-owned CTA.
  void submit() {
    Get.find<AuthController>().login(
      email: _email.text.trim(),
      password: _password.text,
    );
  }

  /// Modern rounded, filled input with a brand-tinted focus ring.
  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffix,
  }) {
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      enabledBorder: border(scheme.outline.withValues(alpha: 0.18), 1),
      focusedBorder: border(scheme.primary, 1.6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedField(
          index: 0,
          child: TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: _fieldDecoration(
              context,
              label: 'login.email'.tr,
              hint: 'login.email_hint'.tr,
              icon: Icons.alternate_email_rounded,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        AnimatedField(
          index: 1,
          child: TextField(
            controller: _password,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            decoration: _fieldDecoration(
              context,
              label: 'login.password'.tr,
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        AnimatedField(
          index: 2,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
              child: Text('login.forgot_password'.tr),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Obx(() {
          final msg = controller.errorMessage.value;
          if (msg != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _shake.shake();
              HapticFeedback.lightImpact();
            });
          }
          return ShakeWidget(
            controller: _shake,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              child: msg == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Text(
                        msg,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          );
        }),
        SizedBox(height: 8.h),
        Obx(
          () => AppGradientButton(
            label: 'login.login_button'.tr,
            loading: controller.isLoading.value,
            onPressed: submit,
          ),
        ),
        SizedBox(height: 16.h),
        _OrContinue(),
        SizedBox(height: 14.h),
        Center(
          child: BiometricButton(
            savedEmail: _email.text.trim().isEmpty ? null : _email.text.trim(),
            onAuthenticated: (email) {
              controller.login(email: email, password: '');
            },
          ),
        ),
        SizedBox(height: 12.h),
        TextButton(
          onPressed: () => Get.toNamed(AppRoutes.register),
          child: Text(
            '${'login.no_account'.tr} ${'login.register_link'.tr}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _OrContinue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35);
    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 0.6)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            'login.or_continue'.tr,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              fontSize: 12.sp,
            ),
          ),
        ),
        Expanded(child: Divider(color: color, thickness: 0.6)),
      ],
    );
  }
}
