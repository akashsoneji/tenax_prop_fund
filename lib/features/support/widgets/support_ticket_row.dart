import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/support_models.dart';

/// A single ticket row: leading rounded purple-tint chat icon + bold title +
/// muted subtitle + trailing status pill and chevron.
class SupportTicketRow extends StatelessWidget {
  const SupportTicketRow({
    super.key,
    required this.ticket,
    this.showDivider = true,
  });

  final SupportTicket ticket;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOpen = ticket.status == TicketStatus.open;
    final statusColor =
        isOpen ? AppColors.warning : scheme.onSurfaceVariant;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.chat_bubble_outline_rounded,
                    color: scheme.primary, size: 20.w),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      ticket.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12.5.sp,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                isOpen ? 'Open' : 'Closed',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
              SizedBox(width: 2.w),
              Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant, size: 20.w),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
