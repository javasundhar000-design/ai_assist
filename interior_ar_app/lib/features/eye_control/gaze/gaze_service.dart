import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Section 21/22: Camera -> Face detection -> Eye landmarks -> Gaze
/// estimation -> Highlight -> Dwell -> Select.
///
/// Honest scope note: ML Kit's on-device face detector gives head pose
/// (Euler X/Y/Z angles) and per-eye "open probability", not a true
/// pupil-tracked gaze vector. This service uses head pose as a practical,
/// fully-offline proxy for gaze direction — which is the standard
/// approach for phone-camera eye control (the user points their face,
/// not just their eyes, at the target). [setCalibration] personalizes
/// estimation to the user's own neutral/extreme head-pose angles,
/// matching Section 22's calibration flow. Swapping in a dedicated
/// pupil-tracking model later only requires replacing this class.
class GazePoint {
  final double x; // normalized 0.0 (left) - 1.0 (right)
  final double y; // normalized 0.0 (top) - 1.0 (bottom)
  final double leftEyeOpenProb;
  final double rightEyeOpenProb;

  const GazePoint(this.x, this.y, this.leftEyeOpenProb, this.rightEyeOpenProb);

  bool get isBlinking => leftEyeOpenProb < 0.25 && rightEyeOpenProb < 0.25;
}

class GazeCalibration {
  final double minYaw, maxYaw; // head turn left/right
  final double minPitch, maxPitch; // head tilt up/down

  const GazeCalibration({
    required this.minYaw,
    required this.maxYaw,
    required this.minPitch,
    required this.maxPitch,
  });

  Map<String, dynamic> toJson() => {
        'minYaw': minYaw,
        'maxYaw': maxYaw,
        'minPitch': minPitch,
        'maxPitch': maxPitch,
      };

  factory GazeCalibration.fromJson(Map json) => GazeCalibration(
        minYaw: (json['minYaw'] as num).toDouble(),
        maxYaw: (json['maxYaw'] as num).toDouble(),
        minPitch: (json['minPitch'] as num).toDouble(),
        maxPitch: (json['maxPitch'] as num).toDouble(),
      );

  static const fallback = GazeCalibration(minYaw: -20, maxYaw: 20, minPitch: -15, maxPitch: 15);
}

class GazeService {
  GazeService._();
  static final GazeService instance = GazeService._();

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  CameraController? _cameraController;
  CameraDescription? _cameraDescription;
  bool _busy = false;
  GazeCalibration _calibration = GazeCalibration.fallback;

  void setCalibration(GazeCalibration calibration) => _calibration = calibration;

  /// This was the root cause of eye control "not working" at all on real
  /// devices: the camera stream previously had no explicit format
  /// requested, so Android delivered multi-plane YUV_420_888 while the
  /// decoder assumed single-plane NV21 — every frame silently failed to
  /// decode into a face. Requesting `ImageFormatGroup.nv21` explicitly
  /// (the format ML Kit's face detector reliably accepts on Android)
  /// fixes that at the source.
  Future<CameraController> startFrontCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraDescription = front;

    final controller = CameraController(
      front,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    await controller.initialize();
    _cameraController = controller;
    return controller;
  }

  /// Computed once at camera start rather than per-frame, on the
  /// assumption that eye-control screens are portrait-locked — this
  /// matches the standard rotation formula used in ML Kit's own Flutter
  /// camera examples for a fixed-orientation app, without the overhead
  /// of tracking live device-orientation changes for a feature where the
  /// phone is expected to stay steady in front of the user's face.
  InputImageRotation get rotation {
    final camera = _cameraDescription;
    if (camera == null) return InputImageRotation.rotation0deg;
    if (Platform.isIOS) {
      return InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
          InputImageRotation.rotation0deg;
    }
    // Android, front camera, assumed portrait-up device orientation.
    final rotationCompensation = camera.sensorOrientation % 360;
    return InputImageRotationValue.fromRawValue(rotationCompensation) ??
        InputImageRotation.rotation0deg;
  }

  Future<void> stop() async {
    await _cameraController?.dispose();
    _cameraController = null;
    _cameraDescription = null;
  }

  /// Streams raw head-pose readings (unmapped to screen space) for the
  /// calibration screen, which records extremes as the user looks at each
  /// corner of the calibration dot pattern.
  Future<void> processFrameForCalibration(
    CameraImage image,
    void Function(double yaw, double pitch) onPose,
  ) async {
    if (_busy) return;
    _busy = true;
    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) return;
      final faces = await _detector.processImage(inputImage);
      if (faces.isNotEmpty) {
        final face = faces.first;
        onPose(face.headEulerAngleY ?? 0, face.headEulerAngleX ?? 0);
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> processFrame(
    CameraImage image,
    void Function(GazePoint point) onGaze,
  ) async {
    if (_busy) return;
    _busy = true;
    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) return;
      final faces = await _detector.processImage(inputImage);
      if (faces.isEmpty) return;
      final face = faces.first;
      final yaw = face.headEulerAngleY ?? 0;
      final pitch = face.headEulerAngleX ?? 0;

      final x = ((yaw - _calibration.minYaw) / (_calibration.maxYaw - _calibration.minYaw))
          .clamp(0.0, 1.0)
          .toDouble();
      // Inverted: looking up (positive pitch) -> lower Y (top of screen).
      final y = 1.0 -
          ((pitch - _calibration.minPitch) / (_calibration.maxPitch - _calibration.minPitch))
              .clamp(0.0, 1.0)
              .toDouble();

      onGaze(GazePoint(
        x,
        y,
        face.leftEyeOpenProbability ?? 1.0,
        face.rightEyeOpenProbability ?? 1.0,
      ));
    } finally {
      _busy = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    try {
      final bytes = image.planes.first.bytes;
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888,
        bytesPerRow: image.planes.first.bytesPerRow,
      );
      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _detector.close();
  }
}
