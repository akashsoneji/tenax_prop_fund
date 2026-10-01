import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_checkbox.dart';
import '../../../shared/theme/app_spacing.dart';

/// Long-form T&C content. Stateless presentation — no business logic. Receives
/// [agreed] + [onAgreed] from the caller so RegisterView can persist the
/// checkbox state.
class TermsView extends StatefulWidget {
  const TermsView({super.key, this.initialAgreed = false, this.onChanged});

  final bool initialAgreed;
  final ValueChanged<bool>? onChanged;

  @override
  State<TermsView> createState() => _TermsViewState();
}

class _TermsViewState extends State<TermsView> {
  late bool _agreed = widget.initialAgreed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('terms.title'.tr)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Text('terms.body'.tr),
              ),
            ),
            if (widget.onChanged != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: AppCheckbox(
                  value: _agreed,
                  onChanged: (v) {
                    setState(() => _agreed = v ?? false);
                    widget.onChanged!(_agreed);
                  },
                  label: 'terms.agree'.tr,
                ),
              ),
            Gap.vMd,
          ],
        ),
      ),
    );
  }
}
