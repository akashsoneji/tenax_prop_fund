import '../../../core/network/api_response.dart';
import '../models/faq_models.dart';

/// Single source of truth for FAQ content. Today it returns demo data after a
/// short delay to simulate the network; when the API lands, replace the body of
/// [getFaqs] with an `ApiClient` call + `fromJson`. The controller and view do
/// not change when that swap happens — that is the point of this layer.
class FaqRepository {
  Future<ApiResponse<List<FaqSection>>> getFaqs() async {
    try {
      // Simulated network latency so the shimmer is visible during development.
      await Future<void>.delayed(const Duration(milliseconds: 900));
      return ApiResponse.success(_demoSections);
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  // -------------------------------------------------------------------------
  // Demo data (moved out of the controller). Delete when the API is wired.
  // -------------------------------------------------------------------------
  static const List<FaqSection> _demoSections = [
    FaqSection('Money', [
      FaqItem(
        'When is my fee refunded?',
        'With your first reward on 2-Step and 1-Step plans. Instant funding '
            'fees are not refundable.',
      ),
      FaqItem(
        'How is the refund paid?',
        'It is added to your first reward payout using the same method you '
            'chose for that payout.',
      ),
      FaqItem(
        'How long does a payout take?',
        'Most payouts are approved within one business day and settle to your '
            'method within one to three business days after that.',
      ),
      FaqItem(
        'Why is my reward on hold?',
        'A hold usually means a rule check is still running or your KYC is not '
            'yet complete. Support can tell you the exact reason.',
      ),
    ]),
    FaqSection('Rules', [
      FaqItem(
        'What actually closes an account?',
        'Only three things: breaching the daily loss limit, breaching the '
            'maximum loss limit, or a prohibited-strategy violation.',
      ),
      FaqItem(
        'Can I hold trades over the weekend?',
        'Yes. Weekend and overnight holding are both allowed on every plan '
            'unless you chose a swap-free add-on.',
      ),
      FaqItem(
        'Can I run an EA?',
        'Expert Advisors are allowed on paid challenges. They are not allowed '
            'inside monthly competitions.',
      ),
      FaqItem(
        'Is the consistency rule a hard fail?',
        'No. It delays a reward rather than closing the account — the reward '
            'waits until your numbers come back inside the line.',
      ),
    ]),
    FaqSection('Account', [
      FaqItem(
        'Do I need KYC to start trading?',
        'No. You can trade the evaluation immediately. KYC is only required '
            'before your first reward can be paid.',
      ),
      FaqItem(
        'What happens if I breach?',
        'The account is closed and moved to read-only. Your history stays '
            'visible and you can buy a new challenge at any time.',
      ),
      FaqItem(
        'Can I have more than one account?',
        'Yes, up to the per-person limit. Competition accounts are separate '
            'and do not count toward it.',
      ),
    ]),
  ];
}
