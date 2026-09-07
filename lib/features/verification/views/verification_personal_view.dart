import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/app_labeled_dropdown.dart';
import '../../../shared/widgets/app_labeled_field.dart';
import '../../../shared/widgets/bottom_action_bar.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../controllers/verification_controller.dart';
import '../widgets/exit_verification_dialog.dart';
import '../widgets/verify_mobile_dialog.dart';

/// Step 1 form: personal details with an inline phone "Send OTP" action that
/// flips to a green check once verified.
class VerificationPersonalView extends GetView<VerificationController> {
  const VerificationPersonalView({super.key});

  Future<void> _confirmExit() async {
    if (await ExitVerificationDialog.show()) Get.back();
  }

  Future<void> _sendOtp() async {
    await controller.sendOtp();
    final code = await VerifyMobileDialog.show(
      phone: controller.phone.text,
      verifying: controller.verifyingOtp,
    );
    if (code != null) await controller.verifyOtp(code);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          PinnedGradientAppBar(
            title: 'verification.verify_account'.tr,
            actions: [
              IconButton(
                onPressed: _confirmExit,
        icon: const Icon(Icons.cancel_outlined, color: AppColors.white),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('verification.personal_details'.tr,
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 18),
                  AppLabeledField(
                      controller: controller.firstName,
                      label: 'verification.first_name'.tr),
                  const SizedBox(height: 16),
                  AppLabeledField(
                      controller: controller.lastName,
                      label: 'verification.last_name'.tr),
                  const SizedBox(height: 16),
                  AppLabeledField(
                    controller: controller.email,
                    label: 'verification.email'.tr,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => AppLabeledField(
                      controller: controller.phone,
                      label: 'verification.phone'.tr,
                      keyboardType: TextInputType.phone,
                      trailing: controller.phoneVerified.value
                          ? Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: scheme.onSurface.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(Icons.check_rounded,
                                  size: 16, color: Colors.white),
                            )
                          : _SendOtpAction(
                              loading: controller.sendingOtp.value,
                              onTap: _sendOtp,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Obx(
                          () => AppLabeledDropdown(
                            label: 'verification.city'.tr,
                            hint: 'verification.city_hint'.tr,
                            value: controller.city.value,
                            options: controller.cities,
                            onChanged: (v) => controller.city.value = v,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Obx(
                          () => AppLabeledDropdown(
                            label: 'verification.state'.tr,
                            hint: 'verification.state_hint'.tr,
                            value: controller.state.value,
                            options: controller.states,
                            onChanged: (v) => controller.state.value = v,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppLabeledField(
                    controller: controller.address,
                    label: 'verification.residence_address'.tr,
                    hint: 'verification.address_hint'.tr,
                    maxLines: 4,
                    minHeight: 130,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: AppGradientButton(label: 'verification.save'.tr, onPressed: _save),
      ),
    );
  }

  void _save() {
    controller.completeCurrentStep();
    Get.back();
  }
}

class _SendOtpAction extends StatelessWidget {
  const _SendOtpAction({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: loading ? null : onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: loading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: scheme.primary),
            )
          : Text('verification.send_otp'.tr,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary)),
    );
  }
}
