import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/bottom_action_bar.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../controllers/verification_controller.dart';
import '../widgets/exit_verification_dialog.dart';
import '../widgets/verification_step_card.dart';

/// Entry screen of the verification journey: an intro line and the three
/// benefit steps (Personal / ID / Bank), the first highlighted. "Start
/// Verification" opens the paged stepper.
class VerificationOverviewView extends GetView<VerificationController> {
  const VerificationOverviewView({super.key});

  Future<void> _confirmExit() async {
    if (await ExitVerificationDialog.show()) Get.back();
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
                  Text(
                    'verification.hero_body'.tr,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14.5,
                      height: 1.4,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (var i = 0; i < controller.steps.length; i++) ...[
                    VerificationStepCard(
                      step: controller.steps[i],
                      highlighted: i == 0,
                      showStepLabel: true,
                    ),
                    if (i < controller.steps.length - 1)
                      const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: AppGradientButton(
          label: 'verification.start'.tr,
          onPressed: () => Get.toNamed(AppRoutes.verificationStepper),
        ),
      ),
    );
  }
}
