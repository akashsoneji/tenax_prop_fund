import re

with open('lib/features/authentication/views/register_view.dart', 'r') as f:
    content = f.read()

# Replace _name controller with _firstName and _lastName
content = content.replace("final _name = TextEditingController();", "final _firstName = TextEditingController();\n  final _lastName = TextEditingController();")
content = content.replace("_name.dispose();", "_firstName.dispose();\n    _lastName.dispose();")

# Replace submit function to pass firstName and lastName separately
submit_old = """final ok = await controller.register(
      fullName: _name.text,
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      password: _password.text,
      confirmPassword: _confirm.text,
      agreedToTerms: _agreed,
      countryCode: _selectedCountryIso.toUpperCase(),
    );"""
submit_new = """final ok = await controller.register(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      password: _password.text,
      confirmPassword: _confirm.text,
      agreedToTerms: _agreed,
      countryCode: _selectedCountryIso.toUpperCase(),
    );"""
content = content.replace(submit_old, submit_new)

# Replace the Full Name field with Row containing First Name and Last Name
full_name_field = """AnimatedField(
                index: 0,
                child: _field(
                  controller: _name,
                  label: 'register.full_name'.tr,
                  icon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  autofill: const [AutofillHints.name],
                  validator: (val) => val == null || val.trim().isEmpty ? 'register.name_required'.tr : null,
                ),
              ),"""

first_last_name_fields = """AnimatedField(
                index: 0,
                child: Row(
                  children: [
                    Expanded(
                      child: _field(
                        controller: _firstName,
                        label: 'First name', // Hardcoded as per image or 'register.first_name'.tr
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        autofill: const [AutofillHints.givenName],
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _field(
                        controller: _lastName,
                        label: 'Last name',
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        autofill: const [AutofillHints.familyName],
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
              ),"""
content = content.replace(full_name_field, first_last_name_fields)

with open('lib/features/authentication/views/register_view.dart', 'w') as f:
    f.write(content)
