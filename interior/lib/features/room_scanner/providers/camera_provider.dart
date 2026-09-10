import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/errors/app_exception.dart';

/// Cached list of physical cameras on the device. Doesn't change during
/// the app's lifetime, so a plain (non-autoDispose) provider is fine.
final availableCamerasProvider =
    FutureProvider<List<CameraDescription>>((ref) async {
  try {
    return await availableCameras();
  } catch (e) {
    throw const CameraException(
        'Could not access the camera on this device.');
  }
});

/// Requests camera permission, picks the back camera, initializes a
/// [CameraController], and disposes it automatically when the screen
/// watching this provider is popped (autoDispose) — this is what
/// satisfies "dispose camera resources" from Sec. 30.
final cameraControllerProvider =
    FutureProvider.autoDispose<CameraController>((ref) async {
  final status = await Permission.camera.request();
  if (status.isPermanentlyDenied) {
    throw const CameraException(
      'Camera permission was denied. Enable it in Settings to scan a room.',
    );
  }
  if (!status.isGranted) {
    throw const CameraException(
      'Camera permission is required to scan a room.',
    );
  }

  final cameras = await ref.watch(availableCamerasProvider.future);
  if (cameras.isEmpty) {
    throw const CameraException('No camera was found on this device.');
  }

  final backCamera = cameras.firstWhere(
    (c) => c.lensDirection == CameraLensDirection.back,
    orElse: () => cameras.first,
  );

  final controller = CameraController(
    backCamera,
    ResolutionPreset.high,
    enableAudio: false,
    imageFormatGroup: ImageFormatGroup.jpeg,
  );

  try {
    await controller.initialize();
  } catch (e) {
    await controller.dispose();
    throw const CameraException(
      'Could not start the camera. Please try again.',
    );
  }

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});
