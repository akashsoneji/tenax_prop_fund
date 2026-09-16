import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
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
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SelectedPlanHeader(c: c),
                  SizedBox(height: 22.h),
                  if (c.availablePlatforms.isNotEmpty) ...[
                    SectionHeader('configure.platform'.tr),
                    Obx(() => AppSegmentedControl(
                          labels: c.availablePlatforms,
                          selected: c.platform.value.clamp(
                              0, c.availablePlatforms.length - 1),
                          onChanged: c.setPlatform,
                        )),
                    SizedBox(height: 20.h),
                  ],
                  SectionHeader('configure.swap'.tr),
                  Obx(() => AppSegmentedControl(
                        labels: [
                          'configure.swap'.tr,
                          'configure.swap_free'.tr
                        ],
                        selected: c.swap.value,
                        onChanged: c.setSwap,
                      )),
                  SizedBox(height: 22.h),
                  SectionHeader('configure.addons'.tr),
                  Obx(() => RulesCard(
                        children: [
                          for (var i = 0;
                              i < c.availableAddons.length;
                              i++)
                            AddonTile(
                              addon: c.availableAddons[i],
                              selected: c.isAddonSelected(
                                  c.availableAddons[i].id),
                              onTap: () => c.toggleAddon(
                                  c.availableAddons[i].id),
                              showDivider:
                                  i != c.availableAddons.length - 1,
                            ),
                        ],
                      )),
                  if (c.availablePaymentMethods.isNotEmpty) ...[
                    SizedBox(height: 22.h),
                    SectionHeader('Payment method'),
                    Obx(() => AppSegmentedControl(
                          labels: c.availablePaymentMethods,
                          selected: c.paymentMethod.value.clamp(
                              0, c.availablePaymentMethods.length - 1),
                          onChanged: c.setPaymentMethod,
                        )),
                  ],
                  SizedBox(height: 22.h),
                  SectionHeader('configure.quantity'.tr),
                  _QuantityRow(c: c),
                  SizedBox(height: 22.h),
                  SectionHeader('Coupon code'),
                  TextField(
                    controller: c.couponCode,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      filled: true,
                      fillColor: scheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 22.h),
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
            price: '${c.currency} ${c.total}',
            strikePrice: c.originalPrice > c.total
                ? '${c.currency} ${c.originalPrice}'
                : null,
            actionLabel: 'Continue',
            onAction: () {},
          )),
    );
  }
}

// ---------------------------------------------------------------------------
// Selected plan summary
// ---------------------------------------------------------------------------

class _SelectedPlanHeader extends StatelessWidget {
  const _SelectedPlanHeader({required this.c});
  final ConfigureController c;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient(scheme),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.20),
            blurRadius: 18.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.planName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  'Account size: ${c.accountSize}',
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            '\$${c.basePrice}',
            style: GoogleFonts.beVietnamPro(
              color: AppColors.accent,
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 14.r),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'configure.number_of_accounts'.tr,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14.sp,
                color: scheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
          _StepButton(icon: Icons.remove_rounded, onTap: c.decrement),
          SizedBox(width: 14.w),
          Obx(() => Text(
                '${c.quantity.value}',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              )),
          SizedBox(width: 14.w),
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
      borderRadius: BorderRadius.circular(9.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9.r),
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Icon(icon, size: 18.w, color: scheme.primary),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create account form
// ---------------------------------------------------------------------------

