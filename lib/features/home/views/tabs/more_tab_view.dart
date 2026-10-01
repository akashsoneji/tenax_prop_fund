import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/session/session_manager.dart';
import '../../../../features/authentication/repositories/auth_repository.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../widgets/delete_account_dialog.dart';
import '../../../../shared/theme/app_spacing.dart';

/// The "More" tab: a grouped directory of every secondary destination in the
/// app. Each section is a single card that carries its own tinted title strip,
/// with compact single-line rows underneath — no second line of helper text.
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
      resizeToAvoidBottomInset: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
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
                    if (i < _sections.length - 1) Gap.vLg,
                  ],
                  18.verticalSpace,
                  const _DangerZone(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _sections = <_Section>[
    _Section(Icons.person_rounded, 'more.account', [
      _Item(
        Icons.account_circle_outlined,
        'more.item.profile',
        AppRoutes.profileKyc,
      ),
      // _Item(Icons.verified_user_outlined, 'more.item.verify_identity',
      //     AppRoutes.verification),
      _Item(Icons.shield_outlined, 'more.item.security', AppRoutes.settings),
    ]),
    _Section(Icons.account_balance_wallet_rounded, 'more.money', [
      _Item(Icons.description_outlined, 'more.item.billing', AppRoutes.billing),
      _Item(
        Icons.account_balance_wallet_outlined,
        'more.item.payout_methods',
        AppRoutes.payoutMethods,
      ),
      _Item(
        Icons.card_giftcard_rounded,
        'more.item.rewards',
        AppRoutes.rewards,
      ),
    ]),
    _Section(Icons.auto_awesome_rounded, 'more.rewards_hub', [
      _Item(Icons.share_rounded, 'more.item.refer', AppRoutes.referral),
      _Item(Icons.local_offer_outlined, 'more.item.offers', AppRoutes.offers),
      _Item(
        Icons.leaderboard_rounded,
        'more.item.competitions',
        AppRoutes.competitions,
      ),
      _Item(
        Icons.workspace_premium_outlined,
        'more.item.certificates',
        AppRoutes.certificates,
      ),
    ]),
    _Section(Icons.handyman_rounded, 'more.tools', [
      _Item(
        Icons.calculate_outlined,
        'more.item.calculators',
        AppRoutes.calculators,
      ),
    ]),
    _Section(Icons.support_agent_rounded, 'more.help', [
      _Item(
        Icons.menu_book_rounded,
        'more.item.trading_rules',
        AppRoutes.tradingRules,
      ),
      _Item(Icons.help_outline_rounded, 'more.item.faq', AppRoutes.faq),
      _Item(Icons.headset_mic_outlined, 'more.item.support', AppRoutes.support),
      _Item(
        Icons.notifications_none_rounded,
        'more.item.notifications',
        AppRoutes.notifications,
      ),
    ]),
  ];
}

// ---------------------------------------------------------------------------
// Section — one card carrying a tinted title strip + its rows
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
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: AppTheme.surfaceCard(scheme, radius: 18.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              color: scheme.primary.withValues(alpha: 0.07),
              child: Row(
                children: [
                  Icon(section.icon, size: 15.w, color: scheme.primary),
                  Gap.hSm,
                  Expanded(
                    child: Text(
                      section.titleKey.tr.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppText.label(
                            fontSize: 11.sp,
                            color: scheme.primary,
                          ).copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < section.items.length; i++) ...[
              _MoreRow(item: section.items[i]),
              if (i < section.items.length - 1)
                Divider(
                  height: 1.h,
                  thickness: 1,
                  indent: 48.w,
                  color: scheme.onSurface.withValues(alpha: 0.06),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Row — single line: icon, title, chevron
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          child: Row(
            children: [
              Icon(item.icon, size: 20.w, color: scheme.primary),
              14.horizontalSpace,
              Expanded(
                child: Text(
                  item.titleKey.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.subtitle(
                    fontSize: 14.sp,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20.w,
                color: scheme.onSurface.withValues(alpha: 0.35),
              ),
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
  const _Section(this.icon, this.titleKey, this.items);
  final IconData icon;
  final String titleKey;
  final List<_Item> items;
}

class _Item {
  const _Item(this.icon, this.titleKey, [this.route]);
  final IconData icon;
  final String titleKey;
  final String? route;
}

// ---------------------------------------------------------------------------
// Danger zone — delete account + logout
// ---------------------------------------------------------------------------
class _DangerZone extends StatelessWidget {
  const _DangerZone();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AppTheme.surfaceCard(scheme, radius: 18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DangerRow(
            icon: Icons.delete_forever_rounded,
            label: 'more.delete_account'.tr,
            onTap: showDeleteAccountDialog,
          ),
          Divider(
            height: 1.h,
            thickness: 1,
            indent: 48.w,
            color: scheme.onSurface.withValues(alpha: 0.06),
          ),
          _DangerRow(
            icon: Icons.logout_rounded,
            label: 'more.logout'.tr,
            onTap: _confirmAndLogout,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndLogout() async {
    final confirmed = await AppConfirmDialog.show(
      title: 'more.logout'.tr,
      message: TextSpan(text: 'more.logout_confirm'.tr),
      confirmLabel: 'more.logout'.tr,
      destructive: true,
      icon: Icons.logout_rounded,
    );
    if (!confirmed) return;
    await Get.find<AuthRepository>().logout();
    SessionManager.clear();
    Get.offAllNamed(AppRoutes.login);
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          child: Row(
            children: [
              Icon(icon, size: 20.w, color: AppColors.danger),
              14.horizontalSpace,
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.subtitle(
                    fontSize: 14.sp,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
