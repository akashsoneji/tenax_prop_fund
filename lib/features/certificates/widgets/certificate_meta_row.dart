import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/certificate_model.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';

/// Holder / issue date / verification code strip shown above the certificate
/// sheet, so the key facts are readable without zooming into the document.
class CertificateMetaRow extends StatelessWidget {
  const CertificateMetaRow({super.key, required this.document});

  final CertificateDocument document;

  @override
  Widget build(BuildContext context) {
    final issued = document.issuedAt;

    return AppCard(
      radius: 18.r,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _MetaCell(
              label: 'certificates.issuedTo'.tr,
              value: document.holder,
            ),
          ),
          Gap.hMd,
          Expanded(
            child: _MetaCell(
              label: 'certificates.issuedOn'.tr,
              value: issued == null
                  ? '—'
                  : DateFormat.yMMMd().format(issued.toLocal()),
            ),
          ),
          Gap.hMd,
          Expanded(
            child: _MetaCell(
              label: 'certificates.verificationCode'.tr,
              value: document.verificationCode,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        Gap.vXs,
        Text(
          value.isEmpty ? '—' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
