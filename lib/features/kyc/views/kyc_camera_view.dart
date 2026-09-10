import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_toast.dart';

/// Full-screen camera capture for KYC documents. Pops with the captured file
/// path (a `String`) on success, or `null` if the user backs out. Kept simple:
/// a live preview, a shutter button, and a close button.
class KycCameraView extends StatefulWidget {
  const KycCameraView({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<KycCameraView> createState() => _KycCameraViewState();
}

class _KycCameraViewState extends State<KycCameraView> {
  CameraController? _controller;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = controller;
    await controller.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final shot = await controller.takePicture();
      Get.back<String>(result: shot.path);
    } catch (_) {
      if (mounted) setState(() => _capturing = false);
      AppToast.error('kyc.docs_no_camera'.tr);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            CameraPreview(controller)
          else
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.white),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Get.back<String>(),
                icon: Icon(Icons.close_rounded,
                    color: AppColors.white, size: 28.w),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 32.h),
                child: _ShutterButton(
                  busy: _capturing,
                  onTap: ready ? _capture : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74.w,
        height: 74.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white.withValues(alpha: 0.2),
          border: Border.all(color: AppColors.white, width: 4.w),
        ),
        child: busy
            ? Padding(
                padding: EdgeInsets.all(22.w),
                child: const CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(AppColors.white),
                ),
              )
            : Icon(Icons.camera_alt_rounded,
                color: AppColors.white, size: 30.w),
      ),
    );
  }
}
