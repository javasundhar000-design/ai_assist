import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_strings.dart';

/// Shared camera-preview + capture widget used by Vision Reader,
/// Medicine Reader, Book Reader, Object Assistant, and Currency
/// Assistant, so camera lifecycle handling (init/dispose, permission
/// prompts) is written exactly once (Section 30 — reusable modules).
class CameraCaptureView extends StatefulWidget {
  final String instructionText;
  final void Function(String imagePath) onCaptured;
  final bool autoCapture;

  const CameraCaptureView({
    super.key,
    required this.instructionText,
    required this.onCaptured,
    this.autoCapture = false,
  });

  @override
  State<CameraCaptureView> createState() => _CameraCaptureViewState();
}

class _CameraCaptureViewState extends State<CameraCaptureView> {
  CameraController? _controller;
  bool _permissionDenied = false;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _permissionDenied = true);
      return;
    }
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(backCamera, ResolutionPreset.high, enableAudio: false);
    await controller.initialize();
    if (!mounted) return;
    setState(() => _controller = controller);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      widget.onCaptured(file.path);
    } catch (_) {
      // Surfaced by the calling screen via its own error state.
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(AppStrings.errCameraPermission, textAlign: TextAlign.center),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CameraPreview(controller),
          ),
        ),
        const SizedBox(height: 12),
        Text(widget.instructionText, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        SizedBox(
          height: 72,
          width: 72,
          child: FloatingActionButton(
            onPressed: _capturing ? null : _capture,
            child: _capturing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.camera_alt_rounded, size: 32),
          ),
        ),
      ],
    );
  }
}
