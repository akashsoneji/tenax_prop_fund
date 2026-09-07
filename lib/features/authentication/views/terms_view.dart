import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_checkbox.dart';

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
                padding: const EdgeInsets.all(24),
                child: Text('terms.body'.tr),
              ),
            ),
            if (widget.onChanged != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCheckbox(
                  value: _agreed,
                  onChanged: (v) {
                    setState(() => _agreed = v ?? false);
                    widget.onChanged!(_agreed);
                  },
                  label: 'terms.agree'.tr,
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}