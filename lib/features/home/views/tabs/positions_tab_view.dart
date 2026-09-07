import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '_placeholder.dart';

class PositionsTabView extends StatelessWidget {
  const PositionsTabView({super.key});
  @override
  Widget build(BuildContext context) => TabPlaceholder(
        title: 'home.tabs.positions'.tr,
        icon: Icons.list_alt_rounded,
      );
}
