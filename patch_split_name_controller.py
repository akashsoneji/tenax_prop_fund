import re

with open('lib/features/authentication/controllers/auth_controller.dart', 'r') as f:
    content = f.read()

# Replace register method signature
register_old = """  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required bool agreedToTerms,
    required String phone,
    String countryCode = 'IN',
  }) async {"""
register_new = """  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required bool agreedToTerms,
    required String phone,
    String countryCode = 'IN',
  }) async {"""
content = content.replace(register_old, register_new)

# Replace validation and split logic
split_logic_old = """    if (fullName.trim().isEmpty) {
      errorMessage.value = 'register.name_required'.tr;
      return false;
    }
    if (!email.contains('@')) {
      errorMessage.value = 'login.invalid_email'.tr;
      return false;
    }
    if (phone.trim().isEmpty) {
      errorMessage.value = 'register.phone_required'.tr;
      return false;
    }
    if (password.length < 8) {
      errorMessage.value = 'register.password_weak'.tr;
      return false;
    }
    if (password != confirmPassword) {
      errorMessage.value = 'register.password_mismatch'.tr;
      return false;
    }
    if (!agreedToTerms) {
      errorMessage.value = 'terms.agree'.tr;
      return false;
    }

    // Split the single full-name field into the first/last the API requires.
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : parts.first;

    isLoading.value = true;
    final result = await _repository.register(
      firstName: firstName,
      lastName: lastName,
      email: email,"""
split_logic_new = """    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      errorMessage.value = 'register.name_required'.tr;
      return false;
    }
    if (!email.contains('@')) {
      errorMessage.value = 'login.invalid_email'.tr;
      return false;
    }
    if (phone.trim().isEmpty) {
      errorMessage.value = 'register.phone_required'.tr;
      return false;
    }
    if (password.length < 8) {
      errorMessage.value = 'register.password_weak'.tr;
      return false;
    }
    if (password != confirmPassword) {
      errorMessage.value = 'register.password_mismatch'.tr;
      return false;
    }
    if (!agreedToTerms) {
      errorMessage.value = 'terms.agree'.tr;
      return false;
    }

    isLoading.value = true;
    final result = await _repository.register(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email,"""
content = content.replace(split_logic_old, split_logic_new)

with open('lib/features/authentication/controllers/auth_controller.dart', 'w') as f:
    f.write(content)
