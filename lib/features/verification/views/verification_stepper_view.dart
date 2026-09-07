import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/bottom_action_bar.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../controllers/verification_controller.dart';
import '../widgets/exit_verification_dialog.dart';
import '../widgets/page_dots.dart';
import '../widgets/verification_hero_banner.dart';
import '../widgets/verification_step_card.dart';

/// The paged stepper. The hero banner + step card swap as [currentStep]
/// changes; the footer shows a single CTA on the first/last step and a
/// Previous/Next pair in between, matching the design's three states.
class VerificationStepperView extends GetView<VerificationController> {
  const VerificationStepperView({super.key});

  Future<void> _confirmExit() async {
    if (await ExitVerificationDialog.show()) Get.back();
  }

  void _openStepScreen(int index) {
    // Step 1 → personal details, step 2 → ID proof, step 3 → bank.
    switch (index) {
      case 0:
        Get.toNamed(AppRoutes.verificationPersonal);
      case 1:
        Get.toNamed(AppRoutes.verificationDocuments);
      case 2:
        Get.toNamed(AppRoutes.addBank);
    }
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
              child: Obx(() {
                final i = controller.currentStep.value;
                final step = controller.steps[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VerificationHeroBanner(
                      stepNumber: step.numberLabel,
                      stepLabel: 'verification.step_label'
                          .trParams({'index': '${step.index}'}),
                    ),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: VerificationStepCard(
                        key: ValueKey(step.index),
                        step: step,
                      ),
                    ),
                    const SizedBox(height: 18),
                    PageDots(count: controller.steps.length, active: i),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: Obx(() {
          final i = controller.currentStep.value;
          final label = controller.isFirstStep
              ? 'verification.start'.tr
              : (controller.isLastStep
                  ? 'verification.submit'.tr
                  : 'common.continue'.tr);
          final primary = AppGradientButton(
            label: label,
            onPressed: () => _openStepScreen(i),
          );
          if (controller.isFirstStep) return primary;
          return Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.previousStep,
                  child: Text('verification.previous'.tr),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: primary),
            ],
          );
        }),
      ),
    );
  }
}
