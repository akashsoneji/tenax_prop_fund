import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../controllers/search_instruments_controller.dart';
import '../models/symbol_models.dart';
import '../repositories/symbols_repository.dart';
import '../services/favorites_service.dart';

/// Bottom-sheet instrument search with category filter pills and add/remove
/// favorite toggles. Opened via [InstrumentSearchSheet.open]; reads the
/// app-registered [SearchInstrumentsController]. Each row rebuilds via its own
/// `Obx` so toggling one favorite does not repaint the whole list.
class InstrumentSearchSheet extends StatelessWidget {
  const InstrumentSearchSheet({super.key});

  static Future<void> open() {
    if (!Get.isRegistered<SymbolsRepository>()) {
      Get.lazyPut<SymbolsRepository>(
        () => SymbolsRepository(Get.find<ApiClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<SearchInstrumentsController>()) {
      Get.lazyPut<SearchInstrumentsController>(
        () => SearchInstrumentsController(
          Get.find<SymbolsRepository>(),
          Get.find<FavoritesService>(),
        ),
        fenix: true,
      );
    }
    return Get.bottomSheet(
      const InstrumentSearchSheet(),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<SearchInstrumentsController>();

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchHeader(controller: c),
              SizedBox(height: 10.h),
              _CategoryPills(controller: c),
              SizedBox(height: 8.h),
              Expanded(child: _ResultsList(controller: c)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({required this.controller});
  final SearchInstrumentsController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
          ),
          Expanded(
            child: TextField(
              autofocus: true,
              onChanged: controller.setQuery,
              style: AppText.body(color: scheme.onSurface),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'symbols.search.hint'.tr,
                hintStyle: AppText.body(color: scheme.onSurfaceVariant),
                prefixIcon:
                    Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
                filled: true,
                fillColor: scheme.surfaceContainerHighest
                    .withValues(alpha: AppColors.alphaMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPills extends StatelessWidget {
  const _CategoryPills({required this.controller});
  final SearchInstrumentsController controller;

  /// Localized labels for the buckets we ship translations for; any other
  /// category name coming from the API is shown as-is.
  static const _labelKey = {
    InstrumentCategory.all: 'symbols.cat.all',
    InstrumentCategory.currency: 'symbols.cat.currency',
    InstrumentCategory.metals: 'symbols.cat.metals',
    InstrumentCategory.crypto: 'symbols.cat.crypto',
    InstrumentCategory.indices: 'symbols.cat.indices',
    InstrumentCategory.shares: 'symbols.cat.shares',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.h,
      child: Obx(
        () => ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: controller.categories.length,
          separatorBuilder: (_, _) => SizedBox(width: 8.w),
          itemBuilder: (context, i) {
            final cat = controller.categories[i];
            final key = _labelKey[cat];
            return _Pill(
              label: key == null ? cat : key.tr,
              active: controller.selectedCategory.value == cat,
              onTap: () => controller.setCategory(cat),
            );
          },
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: active ? scheme.primary : AppColors.transparent,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: active ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.label(
              color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.controller});
  final SearchInstrumentsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final items = controller.filtered;
      if (items.isEmpty) {
        return Center(
          child: Text(
            'state.empty_title'.tr,
            style: AppText.subtitle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
        itemCount: items.length,
        itemBuilder: (context, i) => _InstrumentRow(
          instrument: items[i],
          controller: controller,
        ),
      );
    });
  }
}

class _InstrumentRow extends StatelessWidget {
  const _InstrumentRow({required this.instrument, required this.controller});
  final Instrument instrument;
  final SearchInstrumentsController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest
                  .withValues(alpha: AppColors.alphaMuted),
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.candlestick_chart_outlined,
                size: 20.w, color: scheme.onSurfaceVariant),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instrument.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(color: scheme.onSurface, fontSize: 15.sp),
                ),
                SizedBox(height: 2.h),
                Text(
                  instrument.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Obx(() {
            final fav = controller.favorites.isFavorite(instrument.code);
            return IconButton(
              onPressed: () => controller.toggleFavorite(instrument.code),
              icon: fav
                  ? Icon(Icons.flag_rounded, color: scheme.primary)
                  : Icon(Icons.add_circle_outline_rounded,
                      color: scheme.onSurfaceVariant),
            );
          }),
        ],
      ),
    );
  }
}
