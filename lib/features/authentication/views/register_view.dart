import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/animated_field.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/glass_card.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../widgets/otp_dialog.dart';
import '../widgets/password_strength_meter.dart';

/// Single-screen registration organised into two clear sections — Identity and
/// Security. Uses the shared AuthController; on success prompts the OTP dialog
/// and routes to the dashboard.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agreed = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = Get.find<AuthController>();
    final ok = await controller.register(
      fullName: _name.text,
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      password: _password.text,
      confirmPassword: _confirm.text,
      agreedToTerms: _agreed,
    );
    if (!ok || !mounted) return;

    final code = await OtpDialog.show(target: _email.text.trim());
    if (code != null && mounted) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final scheme = Theme.of(context).colorScheme;

    return AuthScaffold(
      showTicker: false,
      heroTitle: 'register.title'.tr,
      heroSubtitle: 'register.subtitle'.tr,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionLabel(text: 'register.section_identity'.tr, icon: Icons.badge_outlined),
            SizedBox(height: 12.h),
            AnimatedField(
              index: 0,
              child: _field(
                controller: _name,
                label: 'register.full_name'.tr,
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                autofill: const [AutofillHints.name],
              ),
            ),
            SizedBox(height: 14.h),
            AnimatedField(
              index: 1,
              child: _field(
                controller: _email,
                label: 'register.email'.tr,
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                autofill: const [AutofillHints.email],
              ),
            ),
            SizedBox(height: 14.h),
            AnimatedField(
              index: 2,
              child: _field(
                controller: _phone,
                label: 'register.phone'.tr,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                autofill: const [AutofillHints.telephoneNumber],
              ),
            ),
            SizedBox(height: 24.h),
            _SectionLabel(text: 'register.section_security'.tr, icon: Icons.shield_outlined),
            SizedBox(height: 12.h),
            AnimatedField(
              index: 2,
              child: _field(
                controller: _password,
                label: 'register.password'.tr,
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                autofill: const [AutofillHints.newPassword],
                suffix: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            PasswordStrengthMeter(password: _password.text),
            SizedBox(height: 14.h),
            // Confirm appears only once a password has been started.
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: _password.text.isEmpty
                  ? const SizedBox.shrink()
                  : _field(
                      controller: _confirm,
                      label: 'register.confirm_password'.tr,
                      icon: Icons.lock_person_outlined,
                      obscure: true,
                    ),
            ),
            SizedBox(height: 8.h),
            Material(
              type: MaterialType.transparency,
              child: CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  '${'register.agree_prefix'.tr} ${'register.terms_link'.tr}',
                  style: TextStyle(fontSize: 13.sp),
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
                        padding: EdgeInsets.only(bottom: 8.h),
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
            SizedBox(height: 8.h),
            Obx(
              () => AppGradientButton(
                label: 'register.register_button'.tr,
                loading: controller.isLoading.value,
                onPressed: _submit,
              ),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.login),
              child: Text(
                '${'register.have_account'.tr} ${'register.login_link'.tr}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<String>? autofill,
  }) {
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: color, width: width),
        );
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      textCapitalization: textCapitalization,
      autofillHints: autofill,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        enabledBorder: border(scheme.outline.withValues(alpha: 0.18), 1),
        focusedBorder: border(scheme.primary, 1.6),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18.w, color: scheme.primary),
        SizedBox(width: 8.w),
        Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
        ),
      ],
    );
  }
}