import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../shared/widgets/app_toast.dart';
import '../models/kyc_status.dart';
import '../repositories/kyc_repository.dart';
import '../views/kyc_camera_view.dart';
import 'kyc_controller.dart';

/// Drives the KYC document upload screen. Holds one picked [File] per document
/// slot, exposes camera/gallery pickers, and submits every selected file in a
/// single multipart `POST /kyc/documents` through [KycRepository]. Pure
/// orchestration — no widgets are held here.
class KycDocsController extends GetxController {
  KycDocsController(this._repository);

  final KycRepository _repository;

  final files = <KycDocSlot, File>{}.obs;
  final submitting = false.obs;

  bool get hasSelection => files.isNotEmpty;

  File? fileFor(KycDocSlot slot) => files[slot];

  /// Picks an image from the gallery/files for [slot].
  Future<void> pickFromGallery(KycDocSlot slot) async {
    final picked = await FilePicker.pickFile(type: FileType.image);
    final path = picked?.path;
    if (path != null) _set(slot, File(path));
  }

  /// Captures a photo with the device camera for [slot].
  Future<void> pickFromCamera(KycDocSlot slot) async {
    final granted = await _ensureCameraPermission();
    if (!granted) {
      AppToast.error('kyc.docs_permission_denied'.tr);
      return;
    }
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      AppToast.error('kyc.docs_no_camera'.tr);
      return;
    }
    final path = await Get.to<String>(() => KycCameraView(cameras: cameras));
    if (path != null && path.isNotEmpty) _set(slot, File(path));
  }

  void remove(KycDocSlot slot) => files.remove(slot);

  Future<void> submit() async {
    if (submitting.value) return;
    final idFront = files[KycDocSlot.idDocument];
    final addressFront = files[KycDocSlot.proofOfAddress];
    // The API requires identity + address proof in the same request.
    if (idFront == null || addressFront == null) {
      AppToast.error('kyc.docs_both_required'.tr);
      return;
    }
    submitting.value = true;
    final res = await _repository.uploadDocuments(
      idDocument: idFront,
      idDocumentBack: files[KycDocSlot.idDocumentBack],
      proofOfAddress: addressFront,
      proofOfAddressBack: files[KycDocSlot.proofOfAddressBack],
    );
    submitting.value = false;
    if (!res.success) return;

    if (Get.isRegistered<KycController>()) {
      await Get.find<KycController>().refreshProfile();
    }
    Get.back();
  }

  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  void _set(KycDocSlot slot, File file) {
    files[slot] = file;
    files.refresh();
  }
}
