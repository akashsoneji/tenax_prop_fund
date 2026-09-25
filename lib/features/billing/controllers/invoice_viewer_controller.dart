import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../certificates/widgets/certificate_web_view.dart';
import '../models/billing_models.dart';
import '../repositories/billing_repository.dart';

/// Drives the invoice viewer. Fetches the rendered invoice for the
/// [BillingTransaction] passed as route arguments and exposes Download (OS
/// print sheet → "Save as PDF") and Share (PNG of the invoice). The WebView
/// hands its actions in via [attachWebActions], so no widget state lives here.
class InvoiceViewerController extends BaseController<InvoiceDocument> {
  InvoiceViewerController(this._repository, this.transaction);

  final BillingRepository _repository;
  final BillingTransaction transaction;

  CertificateWebActions? _webActions;

  @override
  Future<ApiResponse<InvoiceDocument>> fetch() =>
      _repository.getInvoice(transaction.id);

  @override
  bool isEmpty(InvoiceDocument data) => data.html.trim().isEmpty;

  /// App-bar title: the server's invoice number once loaded, else the one
  /// already on the billing row.
  String get title {
    final loaded = state.valueOrNull?.invoiceNumber ?? '';
    if (loaded.isNotEmpty) return loaded;
    return transaction.invoiceNumber.isNotEmpty
        ? transaction.invoiceNumber
        : 'billing.invoice'.tr;
  }

  void attachWebActions(CertificateWebActions actions) =>
      _webActions = actions;

  /// Opens the OS print sheet, where both platforms offer "Save as PDF".
  Future<void> download() async {
    final actions = _webActions;
    if (actions == null) {
      AppToast.error('billing.invoice_unavailable'.tr);
      return;
    }
    await actions.print();
  }

  /// Shares the invoice as a PNG captured from the WebView. Written to the
  /// cache directory because the share sheet needs a real file path.
  Future<void> share() async {
    final actions = _webActions;
    final bytes = actions == null ? null : await actions.capture();
    if (bytes == null || bytes.isEmpty) {
      AppToast.error('billing.invoice_unavailable'.tr);
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_${transaction.id}.png');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png', name: '$title.png')],
        text: title,
        subject: title,
      ),
    );
  }
}
