import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_gradient_button.dart';
import '../controllers/support_controller.dart';
import '../models/support_models.dart';
import '../repositories/support_repository.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// Bottom sheet showing one ticket's message thread with a reply composer.
/// Loads the full ticket (with its messages) on open, then lets the user post
/// a reply — both backed by the live `/support/tickets/{id}` API.
class TicketDetailSheet extends StatefulWidget {
  const TicketDetailSheet({super.key, required this.ticket});

  final SupportTicket ticket;

  @override
  State<TicketDetailSheet> createState() => _TicketDetailSheetState();
}

class _TicketDetailSheetState extends State<TicketDetailSheet> {
  final _repo = Get.find<SupportRepository>();
  final _replyCtrl = TextEditingController();

  late SupportTicket _ticket = widget.ticket;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await _repo.getTicket(widget.ticket.id);
    if (!mounted) return;
    setState(() {
      if (res.success && res.data != null) _ticket = res.data!;
      _loading = false;
    });
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final res = await _repo.replyTicket(id: _ticket.id, message: text);
    if (!mounted) return;
    setState(() {
      if (res.success && res.data != null) {
        _ticket = res.data!;
        _replyCtrl.clear();
      }
      _sending = false;
    });
    // Keep the list in sync with the new status/last-reply.
    if (Get.isRegistered<SupportController>()) {
      Get.find<SupportController>().refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.85.sh),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ticket.subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.base(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    Gap.vXxs,
                    Text(
                      _ticket.subtitle,
                      style: AppText.base(
                        fontSize: 12.5.sp,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              Flexible(
                child: _loading
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.h),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
                        itemCount: _ticket.messages.length,
                        separatorBuilder: (_, _) => Gap.vMd,
                        itemBuilder: (_, i) =>
                            _MessageBubble(message: _ticket.messages[i]),
                      ),
              ),
              if (_ticket.status != TicketStatus.closed)
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 16.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyCtrl,
                          minLines: 1,
                          maxLines: 4,
                          style: AppText.base(color: scheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'support.reply_hint'.tr,
                          ),
                        ),
                      ),
                      10.horizontalSpace,
                      SizedBox(
                        width: 120.w,
                        child: AppGradientButton(
                          label: 'support.reply'.tr,
                          icon: Icons.send_rounded,
                          height: 48,
                          loading: _sending,
                          onPressed: _sendReply,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isStaff = message.isStaff;
    return Align(
      alignment: isStaff ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: 0.78.sw),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isStaff
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
              : scheme.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.author,
              style: AppText.base(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: isStaff ? scheme.primary : scheme.onSurface,
              ),
            ),
            3.verticalSpace,
            Text(
              message.body,
              style: AppText.base(
                fontSize: 13.5.sp,
                height: 1.35,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
