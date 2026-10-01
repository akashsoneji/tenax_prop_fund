import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/app_labeled_dropdown.dart';
import '../../../shared/widgets/app_labeled_field.dart';
import '../../../shared/widgets/bottom_action_bar.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/upload_dropzone.dart';
import '../controllers/add_bank_controller.dart';
import '../controllers/verification_controller.dart';
import '../models/verification_models.dart';
import '../widgets/verify_mobile_dialog.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// "Add bank" screen: account type/currency/holder fields, IBAN + code,
/// account numbers, swift code, a proof upload, and a "Send OTP" CTA.
class AddBankView extends GetView<AddBankController> {
  const AddBankView({super.key});

  Future<void> _sendOtp() async {
    await controller.sendOtp();
    final code = await VerifyMobileDialog.show(phone: '+91 987654321');
    if (code == null) return;
    // When opened as the final step of the verification journey, mark the Bank
    // step complete and return to the overview. Standalone use just pops.
    if (Get.isRegistered<VerificationController>()) {
      final vc = Get.find<VerificationController>();
      vc.steps[2] = vc.steps[2].copyWith(status: VerificationStatus.completed);
      vc.steps.refresh();
      Get.until((route) => route.settings.name == AppRoutes.verification);
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
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
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
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
                  Gap.vLg,
                  Obx(
                    () => AppLabeledDropdown(
                      label: 'verification.currency'.tr,
                      value: controller.currency.value,
                      options: controller.currencies,
                      onChanged: (v) => controller.currency.value = v,
                    ),
                  ),
                  Gap.vLg,
                  AppLabeledField(
                    controller: controller.accountHolder,
                    label: 'verification.account_holder'.tr,
                  ),
                  Gap.vLg,
                  AppLabeledField(
                    controller: controller.beneficiaryBank,
                    label: 'verification.beneficiary_bank'.tr,
                  ),
                  Gap.vLg,
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
                      14.horizontalSpace,
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
                  Gap.vLg,
                  AppLabeledField(
                    controller: controller.accountNumber,
                    label: 'verification.bank_account_number'.tr,
                    keyboardType: TextInputType.number,
                  ),
                  Gap.vLg,
                  AppLabeledField(
                    controller: controller.confirmAccountNumber,
                    label: 'verification.confirm_bank_account_number'.tr,
                    keyboardType: TextInputType.number,
                  ),
                  Gap.vLg,
                  AppLabeledField(
                    controller: controller.swiftCode,
                    label: 'verification.swift_code'.tr,
                    keyboardType: TextInputType.number,
                  ),
                  22.verticalSpace,
                  Text(
                    'verification.add_proof'.tr,
                    style: AppText.base(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Gap.vMd,
                  Obx(
                    () => UploadDropzone(
                      onTap: controller.pickProof,
                      hasFile: controller.proof.value.isFilled,
                      height: 180.h,
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
          label: 'verification.send_otp'.tr,
          onPressed: _sendOtp,
        ),
      ),
    );
  }
}
