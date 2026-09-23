import re

with open('lib/features/authentication/views/register_view.dart', 'r') as f:
    content = f.read()

# Add imports
imports_to_add = """import 'package:country_picker/country_picker.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:phone_numbers_parser/metadata.dart';
"""
content = content.replace("import 'package:get/get.dart';", "import 'package:get/get.dart';\n" + imports_to_add)

# Add state variables
state_vars = """
  final _formKey = GlobalKey<FormState>();
  String _selectedCountryCode = '+91';
  String _selectedCountryFlag = '🇮🇳 +91';
  IsoCode? _selectedIsoCode = IsoCode.IN;
  String _selectedCountryIso = 'IN';
"""
content = content.replace("bool _obscure = true;", "bool _obscure = true;\n" + state_vars)

# Add _submit modifications
submit_func = """  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      Get.snackbar('terms.agree'.tr, 'terms.agree_error'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final controller = Get.find<AuthController>();
    final ok = await controller.register(
      fullName: _name.text,
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      password: _password.text,
      confirmPassword: _confirm.text,
      agreedToTerms: _agreed,
      countryCode: _selectedCountryIso.toUpperCase(),
    );
    if (!ok || !mounted) return;

    final code = await OtpDialog.show(target: _email.text.trim());
    if (code != null && mounted) {
      Get.offAllNamed(AppRoutes.home);
    }
  }"""
content = re.sub(r'Future<void> _submit\(\) async \{[\s\S]*?Get\.offAllNamed\(AppRoutes\.home\);\n    \}\n  \}', submit_func, content)


# Add validation helpers and UI methods
validation_helpers = """
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
    } catch (_) {}
    return digits.length >= 7 && digits.length <= 15;
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() {
          _selectedCountryCode = "+${country.phoneCode}";
          _selectedCountryFlag = "${country.flagEmoji} +${country.phoneCode}";
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
"""
content = content.replace("Widget build(BuildContext context) {", validation_helpers + "\n  @override\n  Widget build(BuildContext context) {")

# Wrap GlassCard children in Form
content = content.replace("child: Column(", "child: Form(\n          key: _formKey,\n          child: Column(")

# Update text fields to be Form fields
# First replace `_field` method signature to accept validator
content = content.replace(
"""Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<String>? autofill,
  }) {""",
"""Widget _field({
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
  }) {""")

content = content.replace(
"""return TextField(
      controller: controller,
      keyboardType: keyboardType,""",
"""return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,""")

content = content.replace(
"""prefixIcon: Icon(icon),""",
"""prefixIcon: prefix ?? Icon(icon),""")


# Replace AnimatedField usages with validators
name_field_old = """_field(
                controller: _name,
                label: 'register.full_name'.tr,
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                autofill: const [AutofillHints.name],
              )"""
name_field_new = """_field(
                controller: _name,
                label: 'register.full_name'.tr,
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                autofill: const [AutofillHints.name],
                validator: (val) => val == null || val.trim().isEmpty ? 'register.name_required'.tr : null,
              )"""
content = content.replace(name_field_old, name_field_new)

email_field_old = """_field(
                controller: _email,
                label: 'register.email'.tr,
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                autofill: const [AutofillHints.email],
              )"""
email_field_new = """_field(
                controller: _email,
                label: 'register.email'.tr,
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                autofill: const [AutofillHints.email],
                validator: (val) => val == null || !val.contains('@') ? 'login.invalid_email'.tr : null,
              )"""
content = content.replace(email_field_old, email_field_new)

phone_field_old = """_field(
                controller: _phone,
                label: 'register.phone'.tr,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                autofill: const [AutofillHints.telephoneNumber],
              )"""
phone_field_new = """_field(
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
                        Text(_selectedCountryFlag, style: TextStyle(fontSize: 16.sp)),
                        Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'register.phone_required'.tr;
                  if (!_isPhoneValid()) return 'create_account_validation_phone'.tr;
                  return null;
                },
              )"""
content = content.replace(phone_field_old, phone_field_new)

password_field_old = """_field(
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
              )"""
password_field_new = """_field(
                controller: _password,
                label: 'register.password'.tr,
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                autofill: const [AutofillHints.newPassword],
                validator: (val) => val == null || val.length < 8 ? 'register.password_weak'.tr : null,
                suffix: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              )"""
content = content.replace(password_field_old, password_field_new)

confirm_field_old = """_field(
                      controller: _confirm,
                      label: 'register.confirm_password'.tr,
                      icon: Icons.lock_person_outlined,
                      obscure: true,
                    )"""
confirm_field_new = """_field(
                      controller: _confirm,
                      label: 'register.confirm_password'.tr,
                      icon: Icons.lock_person_outlined,
                      obscure: true,
                      validator: (val) => val != _password.text ? 'register.password_mismatch'.tr : null,
                    )"""
content = content.replace(confirm_field_old, confirm_field_new)

# Add one more parenthesis for closing Form
content = content.replace("          ],", "          ],\n        ),")

with open('lib/features/authentication/views/register_view.dart', 'w') as f:
    f.write(content)
