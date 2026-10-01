import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_segmented_control.dart';
import '../../../shared/widgets/key_value_row.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/section_header.dart';
import '../../challenge/widgets/challenge_bottom_bar.dart';
import '../controllers/configure_controller.dart';
import '../widgets/addon_tile.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/payment_method_tile.dart';

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
                  SizedBox(height: 14.h),
                  if (c.availablePlatforms.isNotEmpty) ...[
                    SectionHeader('configure.platform'.tr),
                    Obx(() => AppSegmentedControl(
                          labels: c.availablePlatforms,
                          selected: c.platform.value.clamp(
                              0, c.availablePlatforms.length - 1),
                          onChanged: c.setPlatform,
                        )),
                    SizedBox(height: 14.h),
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
                  if (c.availableAddons.isNotEmpty) ...[
                    SizedBox(height: 14.h),
                    SectionHeader('configure.addons'.tr),
                    Obx(() {
                      // Touch the RxSet so Obx rebuilds on toggle.
                      c.selectedAddons.length;
                      return RulesCard(
                        children: [
                          for (var i = 0; i < c.availableAddons.length; i++)
                            AddonTile(
                              addon: c.availableAddons[i],
                              selected:
                                  c.isAddonSelected(c.availableAddons[i].id),
                              onTap: () =>
                                  c.toggleAddon(c.availableAddons[i].id),
                              showDivider: i != c.availableAddons.length - 1,
                            ),
                        ],
                      );
                    }),
                  ],
                  if (c.availablePaymentMethods.isNotEmpty) ...[
                    SizedBox(height: 14.h),
                    SectionHeader('configure.payment_method'.tr),
                    PaymentMethodTile(c: c),
                  ],
                  SizedBox(height: 14.h),
                  SectionHeader('configure.quantity'.tr),
                  _QuantityRow(c: c),
                  SizedBox(height: 14.h),
                  SectionHeader('configure.coupon_code'.tr),
                  _CouponField(c: c),
                  SizedBox(height: 14.h),
                  SectionHeader('configure.summary'.tr),
                  OrderSummaryCard(c: c),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() => ChallengeBottomBar(
            planName: '${c.planName} · ${c.accountSize}',
            price: '${c.currency} ${c.total}',
            strikePrice: c.subtotal > c.total
                ? '${c.currency} ${c.subtotal}'
                : null,
            actionLabel: 'configure.continue'.tr,
            loading: c.purchasing.value,
            onAction: c.purchasing.value ? null : c.continuePressed,
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
        gradient: AppTheme.heroGradient(scheme),
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
              color: Theme.of(context).colorScheme.secondary,
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
// Coupon code field
// ---------------------------------------------------------------------------

class _CouponField extends StatelessWidget {
  const _CouponField({required this.c});
  final ConfigureController c;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final applied = c.appliedCoupon.value != null;
      final error = c.couponError.value;
      final loading = c.applyingCoupon.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: c.couponCode,
            enabled: !applied,
            // Keyboard stays in normal mode; the formatter uppercases what is
            // typed so codes still match the server's uppercase format.
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: const [_UpperCaseFormatter()],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => c.applyCoupon(),
            style: GoogleFonts.beVietnamPro(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'configure.enter_coupon_code'.tr,
              hintStyle: GoogleFonts.beVietnamPro(
                fontSize: 14.sp,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
              suffix:  SizedBox(
                height: 20.h,
                child: _CouponAction(
                                  applied: applied,
                                  loading: loading,
                                  onApply: c.applyCoupon,
                                  onRemove: c.removeCoupon,
                                ),
              ),
            ),
          ),
          if (applied) ...[
            SizedBox(height: 8.h),
            Text(
              '${c.appliedCoupon.value} applied — you save \$${c.discount}',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ] else if (error != null) ...[
            SizedBox(height: 8.h),
            Text(
              error,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: scheme.error,
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _CouponAction extends StatelessWidget {
  const _CouponAction({
    required this.applied,
    required this.loading,
    required this.onApply,
    required this.onRemove,
  });
  final bool applied;
  final bool loading;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (loading) {
      return SizedBox(
        width: 20.w,
        height: 20.w,
        child: CircularProgressIndicator(
          strokeWidth: 2.2.w,
          valueColor: AlwaysStoppedAnimation(scheme.primary),
        ),
      );
    }
    if (applied) {
      return IconButton(
        onPressed: onRemove,
        visualDensity: VisualDensity.compact,
        icon: Icon(Icons.close_rounded, size: 20.w, color: scheme.error),
      );
    }
    return TextButton(
      onPressed: onApply,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        minimumSize: Size(0, 36.h),
      ),
      child: Text(
        'configure.apply'.tr,
        style: GoogleFonts.beVietnamPro(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
      ),
    );
  }
}

/// Uppercases typed text while keeping the cursor/selection where it was, so
/// the keyboard itself doesn't need caps-lock.
class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}