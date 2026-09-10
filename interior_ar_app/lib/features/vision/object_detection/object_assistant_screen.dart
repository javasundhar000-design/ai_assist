import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import '../../../core/services/ai_vision_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../core/utilities/temp_file_cleaner.dart';
import '../camera/camera_capture_view.dart';

/// Section 13: object recognition. ML Kit's bundled on-device detector
/// only classifies ~5 very coarse categories (fashion goods, food, home
/// goods, place, plant) unless custom-trained, so this prefers the cloud
/// AI (see [AiVisionService]) when the user has configured an API key in
/// Settings — it names specific everyday objects (chair, bottle, laptop,
/// door...) rather than broad buckets. It falls back to the on-device
/// detector, unchanged, whenever no key is set or the cloud call fails.
/// Neither path claims precise distances — only coarse left/right/center
/// framing, the most a single 2D frame can reliably support.
class ObjectAssistantScreen extends StatefulWidget {
  const ObjectAssistantScreen({super.key});

  @override
  State<ObjectAssistantScreen> createState() => _ObjectAssistantScreenState();
}

class _ObjectAssistantScreenState extends State<ObjectAssistantScreen> {
  late final ObjectDetector _detector;
  bool _processing = false;
  List<String> _results = [];

  @override
  void initState() {
    super.initState();
    _detector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );
  }

  Future<void> _onCaptured(String imagePath) async {
    setState(() => _processing = true);

    final apiKey = await LocalStorageService.instance.getAiApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final bytes = await File(imagePath).readAsBytes();
        final cloudResult = await AiVisionService.instance.describeObjects(apiKey, bytes);
        if (cloudResult != null && cloudResult.isNotEmpty) {
          await TempFileCleaner.deleteQuietly(imagePath);
          final lines = cloudResult
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .toList();
          if (!mounted) return;
          setState(() {
            _processing = false;
            _results = lines.isEmpty ? [cloudResult] : lines;
          });
          await TextToSpeechService.instance.speak(_results.join(' '));
          return;
        }
      } catch (_) {
        // Fall through to on-device detection below.
      }
    }

    await _detectOnDevice(imagePath);
  }

  Future<void> _detectOnDevice(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final objects = await _detector.processImage(inputImage);
      final descriptions = objects.map((o) {
        final label = o.labels.isNotEmpty ? o.labels.first.text : 'Object';
        final position = _describePosition(o.boundingBox);
        return position != null ? '$label detected $position.' : '$label detected.';
      }).toList();
      await TempFileCleaner.deleteQuietly(imagePath);
      if (!mounted) return;

      setState(() {
        _processing = false;
        _results = descriptions.isEmpty ? ['No objects were clearly detected.'] : descriptions;
      });
      await TextToSpeechService.instance.speak(_results.join(' '));
    } catch (_) {
      await TempFileCleaner.deleteQuietly(imagePath);
      if (!mounted) return;
      setState(() {
        _processing = false;
        _results = ["I couldn't identify any objects. Please try again."];
      });
      await TextToSpeechService.instance.speak(_results.first);
    }
  }

  /// Coarse left/right/center only — never a fabricated distance figure.
  String? _describePosition(Rect box) {
    // Without the source frame's width reliably on hand here, we keep
    // this conservative: bounding-box center thirds of a nominal frame.
    final centerX = box.left + box.width / 2;
    if (centerX < 400) return 'on your left';
    if (centerX > 800) return 'on your right';
    return 'in front of you';
  }

  @override
  void dispose() {
    _detector.close();
    TextToSpeechService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Object Assistant')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _results.isEmpty && !_processing
              ? CameraCaptureView(
                  instructionText: 'Point the camera around you and capture.',
                  onCaptured: _onCaptured,
                )
              : _processing
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ListView(
                            children: _results
                                .map((r) => Card(
                                      child: ListTile(
                                        leading: const Icon(Icons.check_circle_rounded),
                                        title: Text(r, style: const TextStyle(fontSize: 18)),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() => _results = []),
                          child: const Text('SCAN AGAIN'),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
