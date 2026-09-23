import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// ONE controller shared by every flavor's auth UI. Contains only business
/// orchestration — validation, calling the repo, exposing state. It never
/// references Flavor or any UI. Different flavor views bind to this same class.
class AuthController extends GetxController {
  AuthController(this._repository);

  final AuthRepository _repository;

  final isLoading = false.obs;
  final errorMessage = RxnString();
  final Rxn<UserModel> user = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    // Rehydrate the in-memory user from secure storage on a warm start.
    _repository.currentUser().then((restored) {
      if (restored != null) user.value = restored;
    });
  }

  Future<void> login({required String email, required String password}) async {
    errorMessage.value = null;

    if (email.isEmpty || !email.contains('@')) {
      errorMessage.value = 'login.invalid_email'.tr;
      return;
    }
    if (password.isEmpty) {
      errorMessage.value = 'login.password_required'.tr;
      return;
    }

    isLoading.value = true;
    final result = await _repository.login(email: email, password: password);
    isLoading.value = false;

    if (result.success && result.data != null) {
      user.value = result.data;
      Get.offAllNamed(AppRoutes.home);
    } else {
      errorMessage.value = result.message;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required bool agreedToTerms,
    required String phone,
    String countryCode = 'IN',
  }) async {
    errorMessage.value = null;

    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
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
   
    if (!agreedToTerms) {
      errorMessage.value = 'terms.agree'.tr;
      return false;
    }

    isLoading.value = true;
    final result = await _repository.register(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email,
      password: password,
      countryCode: countryCode,
      phone: phone.trim(),
    );
    isLoading.value = false;

    if (result.success && result.data != null) {
      user.value = result.data;
      return true;
    }
    errorMessage.value = result.message;
    return false;
  }

  /// Clears all persisted session data and returns to the login screen.
  Future<void> logout() async {
    await _repository.logout();
    user.value = null;
    Get.offAllNamed(AppRoutes.login);
  }

  /// Verifies the OTP [code] for [email]. Returns null on success, or a
  /// user-facing error message the OTP dialog can show inline.
  Future<String?> verifyOtp({
    required String email,
    required String code,
  }) async {
    final result = await _repository.verifyEmail(email: email, code: code);
    if (result.success) {
      if (result.data != null) user.value = result.data;
      return null;
    }
    return result.message ?? 'otp.invalid_code'.tr;
  }

  /// Re-sends the OTP for [email]. Returns null on success, or an error message.
  Future<String?> resendOtp({required String email}) async {
    final result = await _repository.resendOtp(email: email);
    if (result.success) return null;
    return result.message ?? 'Something went wrong. Please try again.';
  }

  Future<bool> requestPasswordReset({required String email}) async {
    errorMessage.value = null;

    if (!email.contains('@')) {
      errorMessage.value = 'login.invalid_email'.tr;
      return false;
    }
    isLoading.value = true;
    final result = await _repository.forgotPassword(email: email.trim());
    isLoading.value = false;

    if (!result.success) {
      errorMessage.value = result.message;
      return false;
    }
    return true;
  }
}