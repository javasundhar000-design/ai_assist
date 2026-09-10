import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/services/ai_vision_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../core/utilities/temp_file_cleaner.dart';
import '../camera/camera_capture_view.dart';

/// Section 15: "Describe Surroundings". The spec explicitly requires that
/// the architecture "allow an AI service to be added later without
/// redesigning the application" and that "the basic application must
/// remain functional without cloud AI" — this is exactly that seam.
/// [CloudSceneDescriber] uses the AI vision key from Settings when one is
/// configured; [OfflineSceneDescriber] is the zero-network fallback, and
/// is honest about its own limits rather than inventing detail it can't
/// see — the app stays functional either way, per Section 35.
abstract class SceneDescriber {
  /// Returns a short spoken description of the captured scene.
  Future<String> describe(String imagePath);
}

class OfflineSceneDescriber implements SceneDescriber {
  @override
  Future<String> describe(String imagePath) async {
    return "Offline scene description isn't available on this device. "
        'Try Object Assistant to identify individual items, or add an AI '
        'key in Settings > AI Enhancement for a full description.';
  }
}

class CloudSceneDescriber implements SceneDescriber {
  final SceneDescriber _offlineFallback = OfflineSceneDescriber();

  @override
  Future<String> describe(String imagePath) async {
    final apiKey = await LocalStorageService.instance.getAiApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return _offlineFallback.describe(imagePath);
    }
    try {
      final bytes = await File(imagePath).readAsBytes();
      final result = await AiVisionService.instance.describeScene(apiKey, bytes);
      if (result != null && result.isNotEmpty) return result;
    } catch (_) {
      // Fall through to the offline message below.
    }
    return _offlineFallback.describe(imagePath);
  }
}

class SceneAssistantScreen extends StatefulWidget {
  const SceneAssistantScreen({super.key});

  @override
  State<SceneAssistantScreen> createState() => _SceneAssistantScreenState();
}

class _SceneAssistantScreenState extends State<SceneAssistantScreen> {
  final SceneDescriber _describer = CloudSceneDescriber();
  bool _processing = false;
  String? _description;

  Future<void> _onCaptured(String imagePath) async {
    setState(() => _processing = true);
    final description = await _describer.describe(imagePath);
    await TempFileCleaner.deleteQuietly(imagePath);
    if (!mounted) return;
    setState(() {
      _processing = false;
      _description = description;
    });
    await TextToSpeechService.instance.speak(description);
  }

  @override
  void dispose() {
    TextToSpeechService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Describe Surroundings')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _description == null && !_processing
              ? CameraCaptureView(
                  instructionText: 'Point the camera at your surroundings and capture.',
                  onCaptured: _onCaptured,
                )
              : _processing
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(_description ?? '', style: const TextStyle(fontSize: 20, height: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  if (_description != null) {
                                    TextToSpeechService.instance.speak(_description!);
                                  }
                                },
                                icon: const Icon(Icons.replay_rounded),
                                label: const Text('REPEAT'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => setState(() => _description = null),
                                child: const Text('SCAN AGAIN'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
