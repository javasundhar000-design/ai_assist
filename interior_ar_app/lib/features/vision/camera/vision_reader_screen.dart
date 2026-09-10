import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../core/utilities/temp_file_cleaner.dart';
import '../ocr/ocr_service.dart';
import 'camera_capture_view.dart';

/// Section 10: Camera -> Detect text -> Extract text -> Display -> TTS,
/// with Read / Pause / Resume / Repeat / Stop controls. Works for books,
/// documents, newspapers, signboards, product labels, and bills — it's
/// deliberately generic rather than content-type-specific.
class VisionReaderScreen extends StatefulWidget {
  const VisionReaderScreen({super.key});

  @override
  State<VisionReaderScreen> createState() => _VisionReaderScreenState();
}

class _VisionReaderScreenState extends State<VisionReaderScreen> {
  String? _extractedText;
  bool _processing = false;
  String? _error;

  Future<void> _onCaptured(String imagePath) async {
    setState(() {
      _processing = true;
      _error = null;
    });
    final text = await OcrService.instance.extractTextSmart(imagePath);
    await TempFileCleaner.deleteQuietly(imagePath);
    if (!mounted) return;
    setState(() {
      _processing = false;
      _extractedText = text;
      _error = text == null ? AppStrings.errOcrGeneric : null;
    });
    if (text != null) {
      await TextToSpeechService.instance.speak(text);
    } else {
      await TextToSpeechService.instance.speak(AppStrings.errOcrGeneric);
    }
  }

  @override
  void dispose() {
    TextToSpeechService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Read Text')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _extractedText == null && !_processing
              ? CameraCaptureView(
                  instructionText: 'Point the camera at text and tap to capture.',
                  onCaptured: _onCaptured,
                )
              : _processing
                  ? const Center(child: CircularProgressIndicator())
                  : _buildResult(),
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: Text(_extractedText ?? '', style: const TextStyle(fontSize: 20, height: 1.5)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _controlButton(Icons.play_arrow_rounded, 'Read', () {
              if (_extractedText != null) TextToSpeechService.instance.speak(_extractedText!);
            }),
            _controlButton(Icons.pause_rounded, 'Pause', () => TextToSpeechService.instance.pause()),
            _controlButton(Icons.replay_rounded, 'Repeat', () {
              if (_extractedText != null) TextToSpeechService.instance.speak(_extractedText!);
            }),
            _controlButton(Icons.stop_rounded, 'Stop', () => TextToSpeechService.instance.stop()),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() {
            _extractedText = null;
            _error = null;
          }),
          child: const Text('SCAN AGAIN'),
        ),
      ],
    );
  }

  Widget _controlButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        IconButton.filled(onPressed: onTap, icon: Icon(icon)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
