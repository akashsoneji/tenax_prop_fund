import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_gradient_button.dart';

/// Shown on the Support screen when the user has never opened a ticket:
/// a layered ticket thumbnail, headline, helper line and an "Open a ticket"
/// CTA that launches the same sheet as the app-bar "+" action.
class SupportEmptyState extends StatelessWidget {
  const SupportEmptyState({super.key, required this.onOpenTicket});

  final VoidCallback onOpenTicket;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 20.h),
      decoration: AppTheme.surfaceCard(scheme, radius: 20.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _TicketThumbnail(),
          SizedBox(height: 18.h),
          Text(
            'support.no_tickets'.tr,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.title(fontSize: 17.sp, color: scheme.onSurface),
          ),
          SizedBox(height: 6.h),
          Text(
            'support.no_tickets_hint'.tr,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              fontSize: 13.sp,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 20.h),
          AppGradientButton(
            label: 'support.open_ticket'.tr,
            icon: Icons.add_rounded,
            height: 46.h,
            onPressed: onOpenTicket,
          ),
        ],
      ),
    );
  }
}

/// Two soft concentric rings around a primary-tinted tile holding the ticket
/// glyph, with a small chat bubble badge — reads as "support ticket" at a
/// glance without shipping an image asset.
class _TicketThumbnail extends StatelessWidget {
  const _TicketThumbnail();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 112.w,
      height: 112.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.06),
            ),
          ),
          Container(
            width: 84.w,
            height: 84.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.10),
            ),
          ),
          Container(
            width: 58.w,
            height: 58.w,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient(scheme),
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.30),
                  blurRadius: 16.r,
                  offset: Offset(0, 6.h),
                ),
              ],
            ),
            child: Icon(
              Icons.confirmation_number_rounded,
              size: 28.w,
              color: scheme.onPrimary,
            ),
          ),
          Positioned(
            right: 16.w,
            top: 18.w,
            child: Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface,
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                Icons.support_agent_rounded,
                size: 16.w,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
