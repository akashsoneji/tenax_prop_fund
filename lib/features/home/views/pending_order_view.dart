import 'package:flutter/material.dart';

/// Full-screen pending order editor, opened from the floating trade ticket's
/// pending-order action. Intentionally blank for now — the order form will be
/// built out here.
class PendingOrderView extends StatelessWidget {
  const PendingOrderView({super.key, required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pending order · $symbol')),
      body: const SizedBox.shrink(),
    );
  }
}
