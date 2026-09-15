import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/flavor/flavor_resolver.dart';
import '../../challenge/models/challenge_models.dart';
import '../models/configure_models.dart';

/// Owns all Configure-screen state: selected platform, swap option, the set of
/// enabled add-ons, account quantity and the create-account form fields. A
/// single controller is the one source of truth so the live Summary + Total
/// never drift and there are no per-widget setState races.
///
/// Prices are demo values; the base plan price is passed in via [seed] from the
/// previous screen (or defaults to the $100K 2-Step).
class ConfigureController extends GetxController {
  ConfigureController({ChallengePlan? plan}) : selectedPlan = plan ?? _argumentPlan();

  static ChallengePlan? _argumentPlan() {
    final arguments = Get.arguments;
    return arguments is ChallengePlan ? arguments : null;
  }

  final ChallengePlan? selectedPlan;
  final selectedPlatformId = Rxn<Object>();
  final selectedPaymentMethodId = Rxn<Object>();
  // Selections.
  final platform = 1.obs; // index into platforms
  final swap = 0.obs; // 0 = Swap, 1 = Swap-Free +10%
  final selectedAddons = <String>{}.obs;
  final quantity = 1.obs;
  final acceptedTerms = false.obs;
  final obscurePassword = true.obs;

  static const platforms = ['MetaTrader 4', 'MetaTrader 5', 'cTrader +\$25'];

  // Base plan (demo — the 2-Step $100K from the design).
  String get planName => selectedPlan == null
      ? '${FlavorResolver.appName} 2-Step'
      : '${FlavorResolver.appName} ${selectedPlan!.name}';
  String get accountSize => selectedPlan?.size ?? r'$100K';
  int get basePrice => _minorToDollars(selectedPlan?.defaultVersion?.displayedPriceMinor ?? 0);

  static int _minorToDollars(int minor) => (minor / 100).round();

  static const addons = <Addon>[
    Addon(
      id: 'swap_free',
      title: 'Swap-free',
      description: 'No overnight swap on the account.',
      priceLabel: r'+$34',
      tagLabel: 'Swap → swap-free',
    ),
    Addon(
      id: 'no_min_days',
      title: 'No minimum trading days',
      description: 'Removes the minimum trading day rule',
      priceLabel: r'+$84',
      tagLabel: 'Minimum days → 0',
    ),
    Addon(
      id: 'lifetime_share',
      title: 'Lifetime top reward share',
      description: 'Locks the maximum share permanently.',
      priceLabel: r'+$101',
      tagLabel: 'Share → maximum',
    ),
    Addon(
      id: 'no_consistency',
      title: 'No consistency rule',
      description: 'Removes the single-day profit cap.',
      priceLabel: r'+$67',
      tagLabel: 'Consistency → off',
    ),
    Addon(
      id: 'on_demand',
      title: 'On-demand rewards',
      description: 'Request a reward any time.',
      priceLabel: r'+$84',
      tagLabel: 'Cycle → on demand',
    ),
    Addon(
      id: 'fee_back',
      title: '150% fee back',
      description: '150% of the fee back with your first reward.',
      priceLabel: r'+$34',
      tagLabel: 'Refund → 150%',
    ),
    Addon(
      id: 'double_up',
      title: 'Double up',
      description: 'A second account free once phase 1 is passed.',
      priceLabel: r'+$134',
      tagLabel: 'Second account',
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
  void setSwap(int index) => swap.value = index;
  void togglePasswordVisibility() =>
      obscurePassword.value = !obscurePassword.value;
  void setAccepted(bool value) => acceptedTerms.value = value;

  void increment() => quantity.value = quantity.value + 1;
  void decrement() {
    if (quantity.value > 1) quantity.value = quantity.value - 1;
  }

  /// Grand total in whole dollars, reactive to every input.
  int get total {
    var sum = basePrice;
    for (final id in selectedAddons) {
      sum += _addonPrices[id] ?? 0;
    }
    return sum * quantity.value;
  }

  List<SummaryRow> get summaryRows => [
        SummaryRow('Plan', planName),
        SummaryRow('Account size', accountSize),
        SummaryRow('Platform', platforms[platform.value]),
        SummaryRow('Swap', swap.value == 0 ? 'Swap' : 'Swap-Free'),
        SummaryRow(
          'Add-ons',
          selectedAddons.isEmpty
              ? '0 selected'
              : '${selectedAddons.length} selected',
        ),
        SummaryRow('Quantity', '${quantity.value}'),
      ];

  // Form controllers (disposed with the controller).
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final phone = TextEditingController();

  @override
  void onClose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    password.dispose();
    phone.dispose();
    super.onClose();
  }
}
