import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/offer_models.dart';

/// Single source of truth for offers data. Currently returns static demo data
/// so the "My offers" screen renders without a live backend.
class OffersRepository {
  OffersRepository(this._api);

  // ignore: unused_field
  final ApiClient _api;

  Future<ApiResponse<OffersData>> getOffers() =>
      Future.value(ApiResponse.success(_demoOffers));

  static const OffersData _demoOffers = OffersData(
    available: [
      Offer(
        code: 'PIPZE30',
        percentLabel: '30% off',
        subLabel: 'every plan',
        description: 'Apply this voucher at checkout on any challenge size.',
        badge: '482 of 500 left',
      ),
      Offer(
        code: 'RESET50',
        percentLabel: '50% off',
        subLabel: 'a reset',
        description: 'Half price on your next account reset. One-time use.',
        badge: 'Expires in 12 days',
      ),
    ],
    locked: [
      Offer(
        code: 'PASS100',
        percentLabel: '100% off',
        subLabel: 'next challenge',
        description: 'Unlocked automatically when you pass your current trial.',
        badge: 'Pass a trial to unlock',
        locked: true,
      ),
    ],
  );
}
