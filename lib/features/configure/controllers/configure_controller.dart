import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../challenge/models/challenge_models.dart';
import '../../challenge/repositories/challenge_repository.dart';
import '../models/configure_models.dart';

/// Owns all Configure-screen state: selected platform, swap option, the set of
/// enabled add-ons, account quantity and the create-account form fields. A
/// single controller is the one source of truth so the live Summary + Total
/// never drift and there are no per-widget setState races.
///
/// Prices are demo values; the base plan price is passed in via [seed] from the
/// previous screen (or defaults to the $100K 2-Step).
class ConfigureController extends GetxController {
  ConfigureController({ChallengePlan? plan})
      : selectedPlan = plan ?? _argumentPlan(),
        availableAddons = _argumentAddons(),
        availablePlatforms = _argumentPlatforms(),
        availablePaymentMethods = _argumentPaymentMethods(),
        currency = _argumentCurrency();

  static ChallengePlan? _argumentPlan() {
    final arguments = Get.arguments;
    if (arguments is ChallengePlan) return arguments;
    if (arguments is Map && arguments['plan'] is ChallengePlan) {
      return arguments['plan'] as ChallengePlan;
    }
    return null;
  }

  final ChallengePlan? selectedPlan;
  final List<Addon> availableAddons;
  final List<String> availablePlatforms;
  final List<PaymentMethod> availablePaymentMethods;
  final String currency;

  /// Segmented-control labels for the payment methods.
  List<String> get paymentMethodLabels =>
      availablePaymentMethods.map((m) => m.name).toList(growable: false);

  /// The payment method currently selected in the segmented control.
  PaymentMethod? get selectedPaymentMethod => availablePaymentMethods.isEmpty
      ? null
      : availablePaymentMethods[
          paymentMethod.value.clamp(0, availablePaymentMethods.length - 1)];
  final selectedPlatformId = Rxn<Object>();
  final selectedPaymentMethodId = Rxn<Object>();
  // Selections.
  final platform = 0.obs;
  final paymentMethod = 0.obs;
  final swap = 0.obs; // 0 = Swap, 1 = Swap-Free +10%
  final selectedAddons = <String>{}.obs;
  final quantity = 1.obs;
  final acceptedTerms = false.obs;
  final obscurePassword = true.obs;

  static List<String> _argumentPlatforms() {
    final arguments = Get.arguments;
    if (arguments is Map && arguments['platforms'] is List) {
      final values = (arguments['platforms'] as List)
          .map((item) => item is ChallengePlatform ? item.label : item.toString())
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false);
      if (values.isNotEmpty) return values;
    }
    return const <String>[];
  }

  static List<PaymentMethod> _argumentPaymentMethods() {
    final arguments = Get.arguments;
    if (arguments is Map && arguments['paymentMethods'] is List) {
      return (arguments['paymentMethods'] as List)
          .whereType<PaymentMethod>()
          .toList(growable: false);
    }
    return const <PaymentMethod>[];
  }

  static String _argumentCurrency() {
    final arguments = Get.arguments;
    if (arguments is Map && arguments['currency'] is String) {
      final value = arguments['currency'] as String;
      if (value.trim().isNotEmpty) return value;
    }
    return 'USD';
  }

  late final ChallengeRepository _repository =
      ChallengeRepository(Get.find<ApiClient>());

  // Coupon state.
  final applyingCoupon = false.obs;
  final appliedCoupon = RxnString();
  final couponError = RxnString();
  final couponDiscount = 0.obs; // whole dollars, per single account

  // Base plan (demo — the 2-Step $100K from the design).
  String get planName =>
      selectedPlan == null ? '2-Step' : selectedPlan!.name;
  String get accountSize => selectedPlan?.size ?? r'$100K';
  int get basePrice => _minorToDollars(
        selectedPlan?.defaultVersion?.displayedPriceMinor ?? 0,
      );
  int get originalPrice => basePrice;

  static int _minorToDollars(int minor) => (minor / 100).round();

  static List<Addon> _argumentAddons() {
    final arguments = Get.arguments;
    if (arguments is Map && arguments['addons'] is List) {
      final serverAddons = (arguments['addons'] as List).whereType<ChallengeAddon>();
      final converted = serverAddons.map((addon) {
        final priceLabel = addon.priceMinor > 0
            ? '+\$${(addon.priceMinor / 100).round()}'
            : addon.percentOfFee > 0
                ? '+${addon.percentOfFee}%'
                : 'Included';
        return Addon(
          id: '${addon.id}',
          title: addon.name,
          description: addon.description,
          priceLabel: priceLabel,
          tagLabel: addon.percentOfFee > 0
              ? '${addon.percentOfFee}% of plan fee'
              : 'Server priced',
          priceMinor: addon.priceMinor,
        );
      }).toList(growable: false);
      return converted;
    }
    return const <Addon>[];
  }

  static const addons = <Addon>[
    Addon(
      id: 'swap_free',
      title: 'configure.addon_swap_free',
      description: 'configure.addon_swap_free_desc',
      priceLabel: r'+$34',
      tagLabel: 'configure.addon_swap_free_tag',
    ),
    Addon(
      id: 'no_min_days',
      title: 'configure.addon_no_min_days',
      description: 'configure.addon_no_min_days_desc',
      priceLabel: r'+$84',
      tagLabel: 'configure.addon_no_min_days_tag',
    ),
    Addon(
      id: 'lifetime_share',
      title: 'configure.addon_lifetime_share',
      description: 'configure.addon_lifetime_share_desc',
      priceLabel: r'+$101',
      tagLabel: 'configure.addon_lifetime_share_tag',
    ),
    Addon(
      id: 'no_consistency',
      title: 'configure.addon_no_consistency',
      description: 'configure.addon_no_consistency_desc',
      priceLabel: r'+$67',
      tagLabel: 'configure.addon_no_consistency_tag',
    ),
    Addon(
      id: 'on_demand',
      title: 'configure.addon_on_demand',
      description: 'configure.addon_on_demand_desc',
      priceLabel: r'+$84',
      tagLabel: 'configure.addon_on_demand_tag',
    ),
    Addon(
      id: 'fee_back',
      title: 'configure.addon_fee_back',
      description: 'configure.addon_fee_back_desc',
      priceLabel: r'+$34',
      tagLabel: 'configure.addon_fee_back_tag',
    ),
    Addon(
      id: 'double_up',
      title: 'configure.addon_double_up',
      description: 'configure.addon_double_up_desc',
      priceLabel: r'+$134',
      tagLabel: 'configure.addon_double_up_tag',
    ),
  ];

  static const Map<String, int> _addonPrices = {
    'swap_free': 34,
    'no_min_days': 84,
    'lifetime_share': 101,
    'no_consistency': 67,
    'on_demand': 84,
    'fee_back': 34,
    'double_up': 134,
  };

  bool isAddonSelected(String id) => selectedAddons.contains(id);

  void toggleAddon(String id) {
    // Reassign a new set so the RxSet reliably notifies listeners.
    final next = Set<String>.from(selectedAddons);
    if (!next.add(id)) next.remove(id);
    selectedAddons.assignAll(next);
  }

  void setPlatform(int index) => platform.value = index;
  void setPaymentMethod(int index) => paymentMethod.value = index;
  void setSwap(int index) => swap.value = index;
  void togglePasswordVisibility() =>
      obscurePassword.value = !obscurePassword.value;
  void setAccepted(bool value) => acceptedTerms.value = value;

  void increment() => quantity.value = quantity.value + 1;
  void decrement() {
    if (quantity.value > 1) quantity.value = quantity.value - 1;
  }

  /// Swap-free surcharge: a static 10% of the plan price, applied per account
  /// when the "Swap-Free" option is selected (mirrors the leverage add-on's
  /// percent-of-plan-fee handling).
  static const int swapFreePercent = 10;
  int get swapFreeFee =>
      swap.value == 1 ? (basePrice * swapFreePercent / 100).round() : 0;

  /// Per-account price (plan + add-ons + swap-free) before the coupon, in whole
  /// dollars.
  int get _unitPrice {
    var sum = basePrice + swapFreeFee;
    for (final id in selectedAddons) {
      final serverAddon =
          availableAddons.firstWhereOrNull((addon) => addon.id == id);
      if (serverAddon != null) {
        if (serverAddon.priceMinor > 0) {
          sum += (serverAddon.priceMinor / 100).round();
        } else if (serverAddon.tagLabel.contains('% of plan fee')) {
          final percent =
              int.tryParse(serverAddon.tagLabel.split('%').first) ?? 0;
          sum += (basePrice * percent / 100).round();
        }
      } else {
        sum += _addonPrices[id] ?? 0;
      }
    }
    return sum;
  }

  /// Total discount in whole dollars across every account.
  int get discount => (couponDiscount.value * quantity.value)
      .clamp(0, _unitPrice * quantity.value);

  /// Grand total in whole dollars, reactive to every input (coupon applied).
  int get total => (_unitPrice * quantity.value - discount).clamp(0, 1 << 31);

  /// Total before any coupon discount.
  int get subtotal => _unitPrice * quantity.value;

  /// Apply the coupon typed into [couponCode] against the current plan version.
  Future<void> applyCoupon() async {
    final code = couponCode.text.trim();
    final versionId = selectedPlan?.defaultVersion?.id;
    if (code.isEmpty || versionId == null) return;

    applyingCoupon.value = true;
    couponError.value = null;
    final res = await _repository.applyCoupon(
      planVersionId: versionId,
      couponCode: code,
      quantity: quantity.value,
      addonIds: _selectedAddonIds,
      swapFree: swap.value == 1,
      currency: currency,
    );
    applyingCoupon.value = false;

    if (res.success && res.data != null) {
      final quote = res.data!;
      appliedCoupon.value = quote.couponCode ?? code.toUpperCase();
      // Discount per single account = subtotal − total from the coupon quote.
      couponDiscount.value =
          ((quote.subtotalMinor - quote.totalMinor) / 100).round();
    } else {
      couponError.value = res.message ?? 'This coupon code is invalid.';
    }
  }

  /// Clears an applied coupon and restores the full price.
  void removeCoupon() {
    couponCode.clear();
    appliedCoupon.value = null;
    couponError.value = null;
    couponDiscount.value = 0;
  }

  // Purchase / checkout.
  final purchasing = false.obs;

  /// Add-on ids selected on this screen as integers (server add-on ids).
  List<int> get _selectedAddonIds => selectedAddons
      .map(int.tryParse)
      .whereType<int>()
      .toList(growable: false);

  /// Creates the order and routes by payment path:
  /// - `manual`  → Complete-payment screen (upload proof)
  /// - `free`    → success toast (instant provision, no payment)
  /// - `gateway` → not yet handled here (redirect URL)
  Future<void> continuePressed() async {
    final versionId = selectedPlan?.defaultVersion?.id;
    final method = selectedPaymentMethod;
    if (versionId == null) {
      AppToast.error('This plan cannot be purchased right now.');
      return;
    }
    if (method == null) {
      AppToast.error('Please choose a payment method.');
      return;
    }

    purchasing.value = true;
    final res = await _repository.purchase(
      planVersionId: versionId,
      quantity: quantity.value,
      addonIds: _selectedAddonIds,
      swapFree: swap.value == 1,
      couponCode: appliedCoupon.value,
      paymentMethodId: method.id,
      isManual: method.isManual,
      currency: currency,
    );
    purchasing.value = false;

    if (!res.success || res.data == null) return; // guard already toasted
    final result = res.data!;

    if (result.isManual) {
      Get.toNamed(AppRoutes.completePayment, arguments: result.orderId);
    } else if (result.isFree) {
      AppToast.success('Your account is being provisioned.');
      Get.until((route) => route.settings.name == AppRoutes.home);
    } else if (result.isGateway &&
        (result.gatewayUrl?.isNotEmpty ?? false)) {
      // Hosted checkout — open the gateway URL in an in-app webview so the user
      // can pay and return to the app via the app bar back button.
      Get.toNamed(
        AppRoutes.gatewayPayment,
        arguments: {
          'url': result.gatewayUrl,
          'orderId': result.orderId,
        },
      );
    } else {
      AppToast.error('This order could not be started. Please try again.');
    }
  }

  List<SummaryRow> get summaryRows => [
        SummaryRow('Plan', planName),
        SummaryRow('Account size', accountSize),
        if (availablePlatforms.isNotEmpty)
          SummaryRow('Platform', availablePlatforms[platform.value.clamp(0, availablePlatforms.length - 1)]),
        SummaryRow('Swap',
            swap.value == 0 ? 'Swap' : 'Swap-Free (+$swapFreePercent%)'),
        if (selectedPaymentMethod != null)
          SummaryRow('Payment method', selectedPaymentMethod!.name),
        SummaryRow('Currency', currency),
        SummaryRow(
          'Add-ons',
          selectedAddons.isEmpty
              ? '0 selected'
              : '${selectedAddons.length} selected',
        ),
        SummaryRow('Quantity', '${quantity.value}'),
        if (appliedCoupon.value != null)
          SummaryRow('Discount (${appliedCoupon.value})', '-\$$discount'),
      ];

  // Form controllers (disposed with the controller).
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final phone = TextEditingController();
  final couponCode = TextEditingController();

  @override
  void onClose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    password.dispose();
    phone.dispose();
    couponCode.dispose();
    super.onClose();
  }
}
