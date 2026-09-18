import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../features/authentication/repositories/auth_repository.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/pinned_gradient_app_bar.dart';

/// The "More" tab: a grouped directory of every secondary destination in the
/// app, styled to match the design — a purple gradient header over six
/// card-grouped sections (Trading, Money, Rewards hub, Tools, Help, Account).
///
/// Lives inside [HomeShellView], which already provides the bottom nav, so this
/// widget only renders the header + scrolling content. Rows whose destination
/// screens don't exist yet route to a placeholder toast; wire real routes as
/// each screen lands.
class MoreTabView extends StatelessWidget {
  const MoreTabView({super.key, this.showBack = false});

  /// When opened as a standalone route (e.g. from the Home settings icon on the
  /// tenax flavor) we show a back button; inside the bottom-nav shell we don't.
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          PinnedGradientAppBar(title: 'home.tabs.more'.tr, showBack: showBack),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 28.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < _sections.length; i++) ...[
                    _MoreSection(section: _sections[i], order: i),
                    if (i < _sections.length - 1) SizedBox(height: 22.h),
                  ],
                  SizedBox(height: 22.h),
                  const _LogoutRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _sections = <_Section>[
    _Section('more.trading', [
      _Item(Icons.show_chart_rounded, 'more.item.markets', 'more.sub.markets'),
      _Item(Icons.bar_chart_rounded, 'more.item.open_positions',
          'more.sub.open_positions'),
      _Item(Icons.receipt_long_rounded, 'more.item.trade_history',
          'more.sub.trade_history'),
      _Item(Icons.groups_2_rounded, 'more.item.my_accounts',
          'more.sub.my_accounts', AppRoutes.accounts),
      _Item(Icons.emoji_events_rounded, 'more.item.buy_challenge',
          'more.sub.buy_challenge', AppRoutes.challenge),
      _Item(Icons.card_giftcard_rounded, 'more.item.rewards', 'more.sub.rewards',
          AppRoutes.rewards),
    ]),
    _Section('more.money', [
      _Item(Icons.description_outlined, 'more.item.billing', 'more.sub.billing',
          AppRoutes.billing),
      _Item(Icons.account_balance_wallet_outlined, 'more.item.payout_methods',
          'more.sub.payout_methods', AppRoutes.payoutMethods),
      _Item(Icons.redeem_rounded, 'more.item.promotional',
          'more.sub.promotional'),
    ]),
    _Section('more.rewards_hub', [
      _Item(Icons.share_rounded, 'more.item.refer', 'more.sub.refer',
          AppRoutes.referral),
      _Item(Icons.local_offer_outlined, 'more.item.offers', 'more.sub.offers',
          AppRoutes.offers),
      _Item(Icons.leaderboard_rounded, 'more.item.competitions',
          'more.sub.competitions', AppRoutes.competitions),
      _Item(Icons.workspace_premium_outlined, 'more.item.certificates',
          'more.sub.certificates', AppRoutes.certificates),
    ]),
    _Section('more.tools', [
      _Item(Icons.calculate_outlined, 'more.item.calculators',
          'more.sub.calculators', AppRoutes.calculators),
      _Item(Icons.calendar_month_rounded, 'more.item.economic_calendar',
          'more.sub.economic_calendar', AppRoutes.economicCalendar),
      // Symbols specs & utilities — hidden for now, not needed.
      // _Item(Icons.tune_rounded, 'more.item.symbols', 'more.sub.symbols',
      //     AppRoutes.symbols),
      _Item(Icons.download_rounded, 'more.item.downloads',
          'more.sub.downloads', AppRoutes.downloads),
    ]),
    _Section('more.help', [
      _Item(Icons.menu_book_rounded, 'more.item.trading_rules',
          'more.sub.trading_rules', AppRoutes.tradingRules),
      _Item(Icons.help_outline_rounded, 'more.item.faq', 'more.sub.faq',
          AppRoutes.faq),
      _Item(Icons.headset_mic_outlined, 'more.item.support', 'more.sub.support',
          AppRoutes.support),
      _Item(Icons.notifications_none_rounded, 'more.item.notifications',
          'more.sub.notifications', AppRoutes.notifications),
    ]),
    _Section('more.account', [
      _Item(Icons.account_circle_outlined, 'more.item.profile',
          'more.sub.profile', AppRoutes.profileKyc),
      _Item(Icons.edit_rounded, 'more.item.edit_profile',
          'more.sub.edit_profile', AppRoutes.editProfile),
      _Item(Icons.badge_outlined, 'more.item.profile_kyc',
          'more.sub.profile_kyc', AppRoutes.profileKyc),
      _Item(Icons.verified_user_outlined, 'more.item.verify_identity',
          'more.sub.verify_identity', AppRoutes.verification),
      _Item(Icons.shield_outlined, 'more.item.security', 'more.sub.security',
          AppRoutes.settings),
    ]),
  ];
}

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Section (label + grouped card)
// ---------------------------------------------------------------------------
class _MoreSection extends StatelessWidget {
  const _MoreSection({required this.section, required this.order});

  final _Section section;
  final int order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.page,
      curve: AppMotion.enter,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 18),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
            child: Text(section.titleKey.tr,
                style: GoogleFonts.beVietnamPro(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.65))),
          ),
          Container(
            decoration: AppTheme.surfaceCard(scheme, radius: 18.r),
            child: Column(
              children: [
                for (var i = 0; i < section.items.length; i++) ...[
                  _MoreRow(item: section.items[i]),
                  if (i < section.items.length - 1)
                    Divider(
                      height: 1.h,
                      thickness: 1,
                      indent: 64.w,
                      color: scheme.onSurface.withValues(alpha: 0.06),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Row
// ---------------------------------------------------------------------------
class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.item});

  final _Item item;

  void _onTap() {
    if (item.route != null) {
      Get.toNamed(item.route!);
      return;
    }
    Get.snackbar(
      item.titleKey.tr,
      'more.coming_soon'.tr,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(16.w),
      borderRadius: 14.r,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: _onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 38.w,
                height: 38.h,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                alignment: Alignment.center,
                child: Icon(item.icon, size: 19.w, color: scheme.primary),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.titleKey.tr,
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 14.sp, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2.h),
                    Text(item.subtitleKey.tr,
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 12.sp,
                            color: scheme.onSurface.withValues(alpha: 0.55))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: scheme.primary.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------
class _Section {
  const _Section(this.titleKey, this.items);
  final String titleKey;
  final List<_Item> items;
}

class _Item {
  const _Item(this.icon, this.titleKey, this.subtitleKey, [this.route]);
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final String? route;
}

// ---------------------------------------------------------------------------
// Logout
// ---------------------------------------------------------------------------
class _LogoutRow extends StatelessWidget {
  const _LogoutRow();

  Future<void> _confirmAndLogout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('more.logout'.tr),
        content: Text('more.logout_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('common.cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('more.logout'.tr,
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Get.find<AuthRepository>().logout();
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: AppTheme.surfaceCard(scheme, radius: 18.r),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: _confirmAndLogout,
          borderRadius: BorderRadius.circular(18.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 38.w,
                  height: 38.h,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.logout_rounded,
                      size: 19.w, color: AppColors.danger),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text('more.logout'.tr,
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
