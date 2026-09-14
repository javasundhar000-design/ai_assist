import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// A single head-pose reading from the front camera.
///
/// [yawDegrees] is left/right head turn (negative ≈ turned toward the
/// phone's left, positive ≈ turned toward its right). [pitchDegrees] is
/// up/down head tilt. Exact sign and range depend on ML Kit's convention
/// and the device's front camera — GazeCalibrationData (see
/// gaze_calibration.dart) captures your own extremes so the app doesn't
/// need to hardcode those.
class HeadPose {
  final double yawDegrees;
  final double pitchDegrees;
  const HeadPose({required this.yawDegrees, required this.pitchDegrees});
}

/// IMPORTANT — read before wiring this up on-device:
///
/// This is head-pose tracking (where your whole head is pointed), not true
/// pupil-level gaze tracking (where your eyes are pointed within a
/// stationary head). It's a genuinely usable substitute for large on-screen
/// targets like keyboard keys, and it's what most cross-platform "head
/// mouse" accessibility tools actually use — but it is not the same
/// precision as dedicated eye-tracking hardware (e.g. Tobii) or Apple's
/// ARKit `lookAtPoint` (iOS-only, needs a TrueDepth camera + native Swift
/// code, not achievable in pure Flutter).
///
/// NOT independently verified on real hardware in the environment this was
/// written in — there was no camera available there to test against. The
/// camera-image → InputImage conversion in `_inputImageFromCameraImage`
/// follows the standard camera-plugin + ML Kit integration pattern, but
/// sensor orientation handling is notoriously device/manufacturer-specific.
/// If detection doesn't work or angles seem inverted on your device, that
/// conversion function is the first place to check.
class GazeTrackingService {
  CameraController? _controller;
  FaceDetector? _faceDetector;
  StreamController<HeadPose>? _poseController;
  bool _isDetecting = false;
  CameraDescription? _frontCamera;

  Stream<HeadPose> get poses {
    final controller = _poseController;
    if (controller == null) {
      throw StateError('GazeTrackingService.start() must be called before listening to poses.');
    }
    return controller.stream;
  }

  bool get isRunning => _controller?.value.isStreamingImages ?? false;

  /// Starts the front camera and begins emitting HeadPose readings on
  /// [poses]. Throws if no camera is available or the user denies the
  /// camera permission — catch this at the call site and show a friendly
  /// message (see EyeCalibrationScreen / EyeKeyboardScreen).
  Future<void> start() async {
    if (_controller != null) return; // already running

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('No camera is available on this device.');
    }
    _frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      _frontCamera!,
      // Low resolution is intentional: face-angle detection doesn't need
      // detail, and keeping frames small keeps per-frame ML Kit inference
      // fast enough to run continuously without lagging the UI thread.
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );
    await _controller!.initialize();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableClassification: false,
        enableTracking: false,
        enableLandmarks: false,
        enableContours: false,
      ),
    );

    _poseController = StreamController<HeadPose>.broadcast();

    await _controller!.startImageStream(_onFrame);
  }

  void _onFrame(CameraImage image) {
    // Drop frames while a previous one is still being processed, rather
    // than letting a queue build up — we only care about the latest pose.
    if (_isDetecting) return;
    _isDetecting = true;
    _processFrame(image).whenComplete(() => _isDetecting = false);
  }

  Future<void> _processFrame(CameraImage image) async {
    final detector = _faceDetector;
    if (detector == null) return;
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;
      final faces = await detector.processImage(inputImage);
      if (faces.isEmpty) return;
      final face = faces.first;
      final yaw = face.headEulerAngleY ?? 0;
      final pitch = face.headEulerAngleX ?? 0;
      _poseController?.add(HeadPose(yawDegrees: yaw, pitchDegrees: pitch));
    } catch (_) {
      // A single malformed frame shouldn't kill the whole tracking session.
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _frontCamera;
    if (camera == null) return null;

    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final bytes = _concatenatePlanes(image.planes);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final buffer = WriteBuffer();
    for (final plane in planes) {
      buffer.putUint8List(plane.bytes);
    }
    return buffer.done().buffer.asUint8List();
  }

  /// Exposes the live camera preview so calibration/keyboard screens can
  /// show the user their own face for alignment. Null until start() has
  /// completed.
  CameraController? get controller => _controller;

  Future<void> stop() async {
    try {
      await _controller?.stopImageStream();
    } catch (_) {
      // Already stopped/disposed — safe to ignore.
    }
    await _controller?.dispose();
    await _faceDetector?.close();
    await _poseController?.close();
    _controller = null;
    _faceDetector = null;
    _poseController = null;
  }
}
