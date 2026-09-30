import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_glass.dart';

class _QuickAction {
  const _QuickAction(this.route, this.labelKey, this.icon);
  final String route;
  final String labelKey;
  final IconData icon;
}

const _quickActions = <_QuickAction>[
  _QuickAction(
      AppRoutes.challenge, 'home.qa.challenge', Icons.emoji_events_outlined),
  _QuickAction(
      AppRoutes.profileKyc, 'home.qa.kyc', Icons.verified_user_outlined),
  _QuickAction(
      AppRoutes.rewards, 'home.qa.reward', Icons.card_giftcard_rounded),
  _QuickAction(
      AppRoutes.tradingRules, 'home.qa.rules', Icons.menu_book_rounded),
];

/// App-style shortcut row: four round tinted icon buttons with a caption
/// underneath, sitting directly on the page surface (no card boxes).
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final action in _quickActions)
          Expanded(child: _QuickActionButton(action: action)),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () => Get.toNamed(action.route),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
        child: Column(
          children: [
            if (scheme.brightness == Brightness.dark)
              AppGlass(
                width: 50.w,
                height: 50.w,
                shape: BoxShape.circle,
                child: Icon(action.icon, color: scheme.primary, size: 22.w),
              )
            else
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withValues(alpha: 0.18),
                      scheme.primary.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(action.icon, color: scheme.primary, size: 22.w),
              ),
            SizedBox(height: 8.h),
            Text(
              action.labelKey.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.subtitle(
                color: scheme.onSurface.withValues(alpha: 0.85),
                fontSize: 11.5.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
