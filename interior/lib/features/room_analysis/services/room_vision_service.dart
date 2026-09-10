import 'dart:io';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../../core/errors/app_exception.dart';
import '../../../models/room_and_design_models.dart';
import 'label_mapping.dart';

/// Runs a two-stage, fully on-device detection pipeline over a set of
/// room photos (Sec. 10):
///
///  1. ML Kit Object Detection locates candidate regions (bounding boxes)
///     in each photo — it does NOT know furniture types, only "there's
///     something here".
///  2. Each cropped region is re-classified with ML Kit Image Labeling,
///     which has a much richer label vocabulary, then mapped onto our
///     furniture taxonomy via [mapLabelToObjectType].
///
/// IMPORTANT LIMITATION (documented deliberately, not hidden): the
/// resulting positionX/Y/width/height are normalized 2D coordinates
/// within the source PHOTO (0.0–1.0, top-left origin) — not real-world
/// 3D coordinates within the physical room. positionZ, rotation, and
/// depth are set to 0 here because a single 2D photo cannot recover
/// them; true 3D placement is derived later from AR anchors in the
/// AR Visualization phase (Sec. 18).
///
/// A minimum confidence threshold is applied so low-confidence guesses
/// aren't presented to the user as detections.
class RoomVisionService {
  static const double _minConfidence = 0.55;

  Future<List<DetectedObjectModel>> analyzeImages(
    List<File> images, {
    void Function(double progress)? onProgress,
  }) async {
    final objectDetector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: false,
        multipleObjects: true,
      ),
    );
    final imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: _minConfidence),
    );

    final results = <DetectedObjectModel>[];
    final tempDir = await getTemporaryDirectory();

    try {
      for (var i = 0; i < images.length; i++) {
        final file = images[i];
        try {
          final detections = await _analyzeSingleImage(
            file: file,
            objectDetector: objectDetector,
            imageLabeler: imageLabeler,
            tempDir: tempDir.path,
            sourceIndex: i,
          );
          results.addAll(detections);

          // Whole-frame pass for elements Object Detection tends to miss
          // entirely (doors, windows are often large/flat and don't get
          // boxed as discrete "objects"). No bounding box is available
          // for these, so we mark them as covering the whole frame and
          // rely on the caption in the UI to explain that position is
          // not meaningful for these entries.
          final wholeFrameLabels =
              await imageLabeler.processImage(InputImage.fromFilePath(file.path));
          for (final label in wholeFrameLabels) {
            if (label.confidence < _minConfidence) continue;
            final type = mapLabelToObjectType(label.label);
            if (type == null || !isRoomComponent(type)) continue;
            results.add(DetectedObjectModel(
              id: '', // assigned by the repository on save
              objectType: type,
              confidence: label.confidence,
              positionX: 0.5,
              positionY: 0.5,
              width: 1.0,
              height: 1.0,
            ));
          }
        } catch (e) {
          // A single bad photo shouldn't abort the whole scan (Sec. 29:
          // never crash). Skip it and keep going.
          continue;
        }
        onProgress?.call((i + 1) / images.length);
      }
    } finally {
      await objectDetector.close();
      await imageLabeler.close();
    }

    return _dedupe(results);
  }

  Future<List<DetectedObjectModel>> _analyzeSingleImage({
    required File file,
    required ObjectDetector objectDetector,
    required ImageLabeler imageLabeler,
    required String tempDir,
    required int sourceIndex,
  }) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const VisionException('Could not read one of the scan photos.');
    }

    final inputImage = InputImage.fromFilePath(file.path);
    final detectedObjects = await objectDetector.processImage(inputImage);

    final output = <DetectedObjectModel>[];

    for (var j = 0; j < detectedObjects.length; j++) {
      final box = detectedObjects[j].boundingBox;

      // Clamp the box to the actual image bounds — ML Kit can occasionally
      // return a box that slightly overshoots the frame.
      final left = box.left.clamp(0, decoded.width.toDouble()).toInt();
      final top = box.top.clamp(0, decoded.height.toDouble()).toInt();
      final right = box.right.clamp(0, decoded.width.toDouble()).toInt();
      final bottom = box.bottom.clamp(0, decoded.height.toDouble()).toInt();
      final cropWidth = (right - left).clamp(1, decoded.width);
      final cropHeight = (bottom - top).clamp(1, decoded.height);

      final crop = img.copyCrop(
        decoded,
        x: left,
        y: top,
        width: cropWidth,
        height: cropHeight,
      );
      final cropPath =
          '$tempDir/crop_${sourceIndex}_$j.jpg';
      final cropFile = File(cropPath)
        ..writeAsBytesSync(img.encodeJpg(crop));

      final labels = await imageLabeler
          .processImage(InputImage.fromFilePath(cropFile.path));
      await cropFile.delete().catchError((_) => cropFile);

      if (labels.isEmpty) continue;
      // Highest-confidence label for this crop.
      labels.sort((a, b) => b.confidence.compareTo(a.confidence));
      final best = labels.first;
      if (best.confidence < _minConfidence) continue;

      final objectType = mapLabelToObjectType(best.label);
      if (objectType == null) continue;

      output.add(DetectedObjectModel(
        id: '',
        objectType: objectType,
        confidence: best.confidence,
        positionX: (left + cropWidth / 2) / decoded.width,
        positionY: (top + cropHeight / 2) / decoded.height,
        width: cropWidth / decoded.width,
        height: cropHeight / decoded.height,
      ));
    }

    return output;
  }

  /// Collapses near-duplicate detections of the same type into one entry
  /// keyed by objectType, keeping the highest-confidence instance. Multiple
  /// distinct pieces of the same furniture type (e.g. two chairs) are
  /// intentionally still collapsed for this prototype's checklist-style
  /// display (Sec. 11 shows presence, not a count) — full multi-instance
  /// tracking across photos would need cross-photo re-identification,
  /// which is out of scope without a backend.
  List<DetectedObjectModel> _dedupe(List<DetectedObjectModel> input) {
    final byType = <String, DetectedObjectModel>{};
    for (final obj in input) {
      final existing = byType[obj.objectType];
      if (existing == null || obj.confidence > existing.confidence) {
        byType[obj.objectType] = obj;
      }
    }
    return byType.values.toList();
  }
}
