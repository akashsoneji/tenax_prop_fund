import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/bottom_action_bar.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/upload_dropzone.dart';
import '../controllers/verification_controller.dart';
import '../models/verification_models.dart';
import '../widgets/exit_verification_dialog.dart';

/// Step 2: ID Proof and Address Proof — each a pair of upload tiles (a filled
/// primary slot + a faint secondary slot) as in the design.
class VerificationDocumentsView extends GetView<VerificationController> {
  const VerificationDocumentsView({super.key});

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
                  _ProofSection(
                    title: 'verification.id_proof'.tr,
                    front: controller.idFront,
                    back: controller.idBack,
                    onFront: () => controller.pickProof(ProofKind.idFront),
                    onBack: () => controller.pickProof(ProofKind.idBack),
                  ),
                  const SizedBox(height: 26),
                  _ProofSection(
                    title: 'verification.address_proof'.tr,
                    front: controller.addressFront,
                    back: controller.addressBack,
                    onFront: () => controller.pickProof(ProofKind.addressFront),
                    onBack: () => controller.pickProof(ProofKind.addressBack),
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

class _ProofSection extends StatelessWidget {
  const _ProofSection({
    required this.title,
    required this.front,
    required this.back,
    required this.onFront,
    required this.onBack,
  });

  final String title;
  final Rx<ProofSlot> front;
  final Rx<ProofSlot> back;
  final VoidCallback onFront;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.beVietnamPro(
                fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => UploadDropzone(
                  onTap: onFront,
                  hasFile: front.value.isFilled,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Obx(
                () => UploadDropzone(
                  onTap: onBack,
                  filled: false,
                  hasFile: back.value.isFilled,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
