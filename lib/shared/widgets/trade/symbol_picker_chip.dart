import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../symbol_icon.dart';

/// Tappable symbol chip (icon + code + chevron) that opens a bottom sheet to
/// switch symbol. Presentation-only: the host decides what selecting does.
class SymbolPickerChip extends StatelessWidget {
  const SymbolPickerChip({
    super.key,
    required this.symbol,
    required this.symbols,
    required this.onSelected,
  });

  final String symbol;

  /// Symbols listed in the picker sheet.
  final List<String> symbols;

  final ValueChanged<String> onSelected;

  Future<void> _openPicker(BuildContext context) async {
    if (symbols.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => _SymbolPickerSheet(
        current: symbol,
        symbols: symbols,
      ),
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(12.r);
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: radius,
      child: InkWell(
        onTap: () => _openPicker(context),
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.fromLTRB(6.w, 6.h, 8.w, 6.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SymbolIcon(code: symbol, size: 24.w),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  symbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Icon(
                Icons.expand_more,
                size: 18.w,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymbolPickerSheet extends StatelessWidget {
  const _SymbolPickerSheet({required this.current, required this.symbols});

  final String current;
  final List<String> symbols;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 12.h),
            child: Text(
              'trade.select_symbol'.tr,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: symbols.length,
              itemBuilder: (context, i) {
                final s = symbols[i];
                return ListTile(
                  leading: SymbolIcon(code: s),
                  title: Text(
                    s,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: s == current
                      ? Icon(Icons.check, color: scheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(s),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
