import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/app_labeled_dropdown.dart';
import '../../../shared/widgets/app_labeled_field.dart';
import '../../../shared/widgets/bottom_action_bar.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/upload_dropzone.dart';
import '../controllers/add_bank_controller.dart';
import '../controllers/verification_controller.dart';
import '../widgets/verify_mobile_dialog.dart';

/// "Add bank" screen: account type/currency/holder fields, IBAN + code,
/// account numbers, swift code, a proof upload, and a "Send OTP" CTA.
class AddBankView extends GetView<AddBankController> {
  const AddBankView({super.key});

  Future<void> _sendOtp() async {
    await controller.sendOtp();
    final code = await VerifyMobileDialog.show(phone: '+91 987654321');
    if (code == null) return;
    // When opened as the final step of the verification journey, mark the
    // Bank step complete and return to the stepper. Standalone use just pops.
    if (Get.isRegistered<VerificationController>()) {
      Get.find<VerificationController>().completeCurrentStep();
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          PinnedGradientAppBar(
            title: 'verification.add_bank'.tr,
            actions: [
              IconButton(
                onPressed: Get.back,
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
                  Obx(
                    () => AppLabeledDropdown(
                      label: 'verification.account_type'.tr,
                      value: controller.accountType.value,
                      options: controller.accountTypes,
                      onChanged: (v) => controller.accountType.value = v,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => AppLabeledDropdown(
                      label: 'verification.currency'.tr,
                      value: controller.currency.value,
                      options: controller.currencies,
                      onChanged: (v) => controller.currency.value = v,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppLabeledField(
                      controller: controller.accountHolder,
                      label: 'verification.account_holder'.tr),
                  const SizedBox(height: 16),
                  AppLabeledField(
                      controller: controller.beneficiaryBank,
                      label: 'verification.beneficiary_bank'.tr),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Obx(
                          () => AppLabeledDropdown(
                            label: 'verification.iban'.tr,
                            hint: 'verification.code'.tr,
                            value: controller.ibanType.value,
                            options: controller.ibanTypes,
                            onChanged: (v) => controller.ibanType.value = v,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Obx(
                          () => AppLabeledDropdown(
                            label: 'verification.code'.tr,
                            hint: 'verification.code'.tr,
                            value: controller.code.value,
                            options: controller.ibanTypes,
                            onChanged: (v) => controller.code.value = v,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppLabeledField(
                    controller: controller.accountNumber,
                    label: 'verification.bank_account_number'.tr,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  AppLabeledField(
                    controller: controller.confirmAccountNumber,
                    label: 'verification.confirm_bank_account_number'.tr,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  AppLabeledField(
                    controller: controller.swiftCode,
                    label: 'verification.swift_code'.tr,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 22),
                  Text('verification.add_proof'.tr,
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Obx(
                    () => UploadDropzone(
                      onTap: controller.pickProof,
                      hasFile: controller.proof.value.isFilled,
                      height: 180,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: AppGradientButton(
            label: 'verification.send_otp'.tr, onPressed: _sendOtp),
      ),
    );
  }
}
