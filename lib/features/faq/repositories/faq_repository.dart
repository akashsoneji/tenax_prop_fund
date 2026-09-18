import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/faq_models.dart';

/// Single source of truth for FAQ content. Calls the live `GET /support/faq`
/// endpoint (standard `{success, message, data}` envelope where `data.items[]`
/// holds `{q, a}` pairs). The flat list is presented as one section so the
/// existing accordion view/controller stay unchanged.
class FaqRepository {
  FaqRepository(this._api);

  final ApiClient _api;

  Future<ApiResponse<List<FaqSection>>> getFaqs() {
    return ApiEnvelope.guard<List<FaqSection>>(
      () => _api.get<Map<String, dynamic>>(ApiEndpoints.supportFaq),
      (data) {
        final list = (data is Map ? data['items'] as List? : null) ?? const [];
        final items = list
            .whereType<Map>()
            .map((e) => FaqItem('${e['q'] ?? ''}', '${e['a'] ?? ''}'))
            .where((e) => e.question.isNotEmpty)
            .toList();
        if (items.isEmpty) return const <FaqSection>[];
        return [FaqSection('faq.common_questions'.tr, items)];
      },
    );
  }
}
