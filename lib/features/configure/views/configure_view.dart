import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_info_banner.dart';
import '../../../shared/widgets/app_segmented_control.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/key_value_row.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/section_header.dart';
import '../../challenge/widgets/challenge_bottom_bar.dart';
import '../controllers/configure_controller.dart';
import '../widgets/addon_tile.dart';

/// Configure — platform + swap selection, add-ons, quantity stepper, the
/// create-account form and a live Summary. Every input flows through
/// [ConfigureController] so the Summary/Total and the sticky bottom bar stay
/// in sync without local state.
class ConfigureView extends StatelessWidget {
  const ConfigureView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<ConfigureController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'configure.title'.tr),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppInfoBanner(
                    tone: BannerTone.warning,
                    icon: Icons.bolt_rounded,
                    title: 'configure.trial_summary'.tr,
                    body: 'configure.trial_note'.tr,
                  ),
                  const SizedBox(height: 22),
                  SectionHeader('configure.platform'.tr),
                  Obx(() => AppSegmentedControl(
                        labels: ConfigureController.platforms,
                        selected: c.platform.value,
                        onChanged: c.setPlatform,
                      )),
                  const SizedBox(height: 20),
                  SectionHeader('configure.swap'.tr),
                  Obx(() => AppSegmentedControl(
                        labels: [
                          'configure.swap'.tr,
                          'configure.swap_free'.tr
                        ],
                        selected: c.swap.value,
                        onChanged: c.setSwap,
                      )),
                  const SizedBox(height: 22),
                  SectionHeader('configure.addons'.tr),
                  Obx(() => RulesCard(
                        children: [
                          for (var i = 0;
                              i < ConfigureController.addons.length;
                              i++)
                            AddonTile(
                              addon: ConfigureController.addons[i],
                              selected: c.isAddonSelected(
                                  ConfigureController.addons[i].id),
                              onTap: () => c.toggleAddon(
                                  ConfigureController.addons[i].id),
                              showDivider:
                                  i != ConfigureController.addons.length - 1,
                            ),
                        ],
                      )),
                  const SizedBox(height: 22),
                  SectionHeader('configure.quantity'.tr),
                  _QuantityRow(c: c),
                  const SizedBox(height: 22),
                  SectionHeader('configure.your_details'.tr),
                  _CreateAccountCard(c: c),
                  const SizedBox(height: 22),
                  SectionHeader('configure.summary'.tr),
                  Obx(() {
                    final rows = c.summaryRows;
                    return RulesCard(
                      children: [
                        for (final r in rows)
                          KeyValueRow(label: r.label, value: r.value),
                        KeyValueRow(
                          label: 'configure.total'.tr,
                          value: '\$${c.total}',
                          emphasize: true,
                          valueColor: scheme.primary,
                          showDivider: false,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() => ChallengeBottomBar(
            planName: '${c.planName} · ${c.accountSize}',
            price: '\$${c.total}',
            strikePrice: r'$479',
            actionLabel: 'configure.title'.tr,
            onAction: () {},
          )),
    );
  }
}

// ---------------------------------------------------------------------------
// Quantity stepper
// ---------------------------------------------------------------------------

class _QuantityRow extends StatelessWidget {
  const _QuantityRow({required this.c});
  final ConfigureController c;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.surfaceCard(scheme, radius: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'configure.number_of_accounts'.tr,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                color: scheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
          _StepButton(icon: Icons.remove_rounded, onTap: c.decrement),
          const SizedBox(width: 14),
          Obx(() => Text(
                '${c.quantity.value}',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              )),
          const SizedBox(width: 14),
          _StepButton(icon: Icons.add_rounded, onTap: c.increment),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: scheme.primary),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create account form
// ---------------------------------------------------------------------------

class _CreateAccountCard extends StatelessWidget {
  const _CreateAccountCard({required this.c});
  final ConfigureController c;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.surfaceCard(scheme, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'configure.create_account'.tr,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('configure.sign_in'.tr),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'configure.details_note'.tr,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12.5,
              height: 1.4,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: c.firstName,
                  label: 'configure.first_name'.tr,
                  hint: 'configure.first_name_hint'.tr,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: c.lastName,
                  label: 'configure.last_name'.tr,
                  hint: 'configure.last_name_hint'.tr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: c.email,
            label: 'configure.email'.tr,
            hint: 'configure.email_hint'.tr,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          Obx(() => AppTextField(
                controller: c.password,
                label: 'configure.password'.tr,
                hint: 'configure.password_hint'.tr,
                obscureText: c.obscurePassword.value,
                suffixIcon: IconButton(
                  icon: Icon(
                    c.obscurePassword.value
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                  onPressed: c.togglePasswordVisibility,
                ),
              )),
          const SizedBox(height: 12),
          AppTextField(
            controller: c.phone,
            label: 'configure.mobile'.tr,
            hint: 'configure.mobile_hint'.tr,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          Obx(() => InkWell(
                onTap: () => c.setAccepted(!c.acceptedTerms.value),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: c.acceptedTerms.value,
                      onChanged: (v) => c.setAccepted(v ?? false),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'configure.accept_terms'.tr,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12.5,
                            height: 1.4,
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
