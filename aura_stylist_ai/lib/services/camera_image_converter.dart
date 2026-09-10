import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Converts a live [CameraImage] frame into the [InputImage] format ML Kit's
/// on-device pose detector expects. This follows Google ML Kit's documented
/// Flutter conversion pattern: https://pub.dev/packages/google_mlkit_pose_detection
///
/// Two platform-specific gotchas this handles:
/// - **Rotation**: Android reports frames in the sensor's native orientation
///   regardless of device rotation, so we combine the camera's fixed sensor
///   orientation with the current device orientation. iOS frames are already
///   rotation-corrected by the sensor orientation value alone.
/// - **Pixel format**: Android streams NV21; iOS streams BGRA8888. The
///   camera controller must be created with a matching `imageFormatGroup`
///   (see `TryOnScreen._initCamera`) or this returns null and the frame is
///   skipped rather than crashing.
class CameraImageConverter {
  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  static InputImage? toInputImage({
    required CameraImage image,
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
  }) {
    final rotation = rotationFor(camera, deviceOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    final isAndroidNv21 = Platform.isAndroid && format == InputImageFormat.nv21;
    final isIosBgra = Platform.isIOS && format == InputImageFormat.bgra8888;
    if (format == null || !(isAndroidNv21 || isIosBgra)) return null;

    // Both NV21 and BGRA8888 are delivered as a single plane by the camera
    // plugin when the matching imageFormatGroup is requested.
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  static InputImageRotation? rotationFor(CameraDescription camera, DeviceOrientation deviceOrientation) {
    if (Platform.isIOS) {
      return InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    }
    if (Platform.isAndroid) {
      var rotationCompensation = _orientations[deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (camera.sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (camera.sensorOrientation - rotationCompensation + 360) % 360;
      }
      return InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    return null;
  }

  /// The size the *rotated* image occupies — needed to map ML Kit's
  /// landmark coordinates (given in the sensor's native, unrotated frame)
  /// onto a portrait preview correctly.
  static Size rotatedSize(CameraImage image, InputImageRotation rotation) {
    final raw = Size(image.width.toDouble(), image.height.toDouble());
    final isSideways = rotation == InputImageRotation.rotation90deg || rotation == InputImageRotation.rotation270deg;
    return isSideways ? Size(raw.height, raw.width) : raw;
  }
}
