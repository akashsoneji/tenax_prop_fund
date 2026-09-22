import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/certificate_model.dart';
import '../repositories/certificates_repository.dart';
import '../widgets/certificate_web_view.dart';

/// Drives the single-certificate viewer. Fetches the rendered document for the
/// [Certificate] passed as route arguments and exposes the two user actions
/// (share the certificate image, print/save as PDF). The WebView hands its
/// actions in through [attachWebActions], so no widget state lives here.
class CertificateViewerController extends BaseController<CertificateDocument> {
  CertificateViewerController(this._repository, this.certificate);

  final CertificatesRepository _repository;
  final Certificate certificate;

  CertificateWebActions? _webActions;

  @override
  Future<ApiResponse<CertificateDocument>> fetch() =>
      _repository.getCertificateDocument(certificate.id);

  CertificateDocument? get document => state.valueOrNull;

  void attachWebActions(CertificateWebActions actions) =>
      _webActions = actions;

  /// Portal verification URL derived from the backend's own `download_url`
  /// host, so it follows whichever brand the flavor points at.
  String? get verificationUrl {
    final code = document?.verificationCode;
    if (code == null || code.isEmpty) return null;
    final source = certificate.downloadUrl;
    if (source == null || source.isEmpty) return null;
    final uri = Uri.tryParse(source);
    if (uri == null) return null;
    return '${uri.scheme}://${uri.host}/verify/$code';
  }

  /// Shares the certificate as a PNG captured from the WebView, with the
  /// verification link as the accompanying text. The image is written to the
  /// cache directory because the share sheet needs a real file path.
  Future<void> share() async {
    final actions = _webActions;
    if (actions == null) {
      AppToast.error('certificates.downloadUnavailable'.tr);
      return;
    }

    final bytes = await actions.capture();
    if (bytes == null || bytes.isEmpty) {
      AppToast.error('certificates.shareUnavailable'.tr);
      return;
    }

    final name = document?.name ?? certificate.name;
    final url = verificationUrl;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/certificate_${certificate.id}.png');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png', name: '$name.png')],
        text: url == null
            ? name
            : 'certificates.shareMessage'
                .trParams({'name': name, 'url': url}),
        subject: name,
      ),
    );
  }

  /// Opens the OS print sheet, where both platforms offer "Save as PDF".
  Future<void> download() async {
    final actions = _webActions;
    if (actions == null) {
      AppToast.error('certificates.downloadUnavailable'.tr);
      return;
    }
    await actions.print();
  }
}
