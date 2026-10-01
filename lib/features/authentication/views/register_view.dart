import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/logger/app_logger.dart';
import '../controllers/auth_controller.dart';
import '../widgets/animated_field.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/glass_card.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../widgets/otp_dialog.dart';
import '../widgets/password_strength_meter.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// Single-screen registration organised into two clear sections — Identity and
/// Security. Uses the shared AuthController; on success prompts the OTP dialog
/// and routes to the dashboard.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _agreed = false;
  bool _obscure = true;

  String _selectedCountryCode = '+91';
  String _selectedCountryFlag = '🇮🇳';
  IsoCode? _selectedIsoCode = IsoCode.IN;
  String _selectedCountryIso = 'IN';

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _isPhoneValid() {
    final digits = _phone.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return false;
    final iso = _selectedIsoCode;
    if (iso == null) return digits.length >= 6 && digits.length <= 15;
    try {
      final number = PhoneNumber.parse(digits, destinationCountry: iso);
      if (number.isValid(type: PhoneNumberType.mobile) || number.isValid()) {
        return true;
      }
    } catch (e) {
      log.w('phone parse failed, using length fallback: $e');
    }
    return digits.length >= 7 && digits.length <= 15;
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() {
          _selectedCountryCode = "+${country.phoneCode}";
          _selectedCountryFlag = country.flagEmoji;
          _selectedCountryIso = country.countryCode;
          for (final iso in IsoCode.values) {
            if (iso.name == country.countryCode.toUpperCase()) {
              _selectedIsoCode = iso;
              break;
            }
          }
        });
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      Get.snackbar(
        'terms.agree'.tr,
        'terms.agree_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final controller = Get.find<AuthController>();
    final ok = await controller.register(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      password: _password.text,
      agreedToTerms: _agreed,
      countryCode: _selectedCountryIso.toUpperCase(),
    );
    if (!ok || !mounted) return;

    final email = _email.text.trim();
    final code = await OtpDialog.show(
      target: email,
      onVerify: (code) => controller.verifyOtp(email: email, code: code),
      onResend: () => controller.resendOtp(email: email),
    );
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel(
                text: 'register.section_identity'.tr,
                icon: Icons.badge_outlined,
              ),
              Gap.vMd,
              AnimatedField(
                index: 1,
                child: _field(
                  controller: _firstName,
                  label: 'register.first_name'.tr,
                  icon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  autofill: const [AutofillHints.givenName],
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'register.required'.tr
                      : null,
                ),
              ),
              14.verticalSpace,
              AnimatedField(
                index: 2,
                child: _field(
                  controller: _lastName,
                  label: 'register.last_name'.tr,
                  icon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  autofill: const [AutofillHints.familyName],
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'register.required'.tr
                      : null,
                ),
              ),
              14.verticalSpace,
              AnimatedField(
                index: 3,
                child: _field(
                  controller: _email,
                  label: 'register.email'.tr,
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  autofill: const [AutofillHints.email],
                  validator: (val) => val == null || !val.contains('@')
                      ? 'login.invalid_email'.tr
                      : null,
                ),
              ),
              14.verticalSpace,
              AnimatedField(
                index: 4,
                child: _field(
                  controller: _phone,
                  label: 'register.phone'.tr,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  autofill: const [AutofillHints.telephoneNumber],
                  prefix: InkWell(
                    onTap: _showCountryPicker,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_selectedCountryFlag $_selectedCountryCode',
                            style: AppText.base(
                              fontSize: 16.sp,
                              color: scheme.onSurface,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: scheme.onSurface),
                        ],
                      ),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'register.phone_required'.tr;
                    }
                    if (!_isPhoneValid()) {
                      return 'create_account_validation_phone'.tr;
                    }
                    return null;
                  },
                ),
              ),
              Gap.vXl,
              _SectionLabel(
                text: 'register.section_security'.tr,
                icon: Icons.shield_outlined,
              ),
              Gap.vMd,
              AnimatedField(
                index: 5,
                child: _field(
                  controller: _password,
                  label: 'register.password'.tr,
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  autofill: const [AutofillHints.newPassword],
                  validator: (val) => val == null || val.length < 8
                      ? 'register.password_weak'.tr
                      : null,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              Gap.vMd,
              PasswordStrengthMeter(password: _password.text),
              Gap.vSm,
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
                    style: AppText.base(fontSize: 13.sp),
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
                            style: AppText.base(
                              color: scheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                );
              }),
              Gap.vSm,
              Obx(
                () => AppGradientButton(
                  label: 'register.register_button'.tr,
                  loading: controller.isLoading.value,
                  onPressed: _submit,
                ),
              ),
              Gap.vSm,
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.login),
                child: Text(
                  '${'register.have_account'.tr} ${'register.login_link'.tr}',
                  style: AppText.base(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
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
    Widget? prefix,
    Widget? suffix,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<String>? autofill,
    String? Function(String?)? validator,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.r),
      borderSide: BorderSide(color: color, width: width),
    );
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      textCapitalization: textCapitalization,
      autofillHints: autofill,
      validator: validator,
      style: AppText.base(fontSize: 15.sp, color: scheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefix ?? Icon(icon, color: scheme.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark
            ? scheme.onSurface.withValues(alpha: 0.06)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.85),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        enabledBorder: border(
          scheme.outline.withValues(alpha: isDark ? 0.30 : 0.18),
          1,
        ),
        focusedBorder: border(scheme.primary, 1.6),
        errorBorder: border(scheme.error, 1.6),
        focusedErrorBorder: border(scheme.error, 1.6),
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
        Gap.hSm,
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
