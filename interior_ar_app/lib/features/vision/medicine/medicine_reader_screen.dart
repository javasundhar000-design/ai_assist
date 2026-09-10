import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../core/utilities/temp_file_cleaner.dart';
import '../camera/camera_capture_view.dart';
import '../ocr/ocr_service.dart';

/// Section 11: reads whatever is printed on medicine packaging — name,
/// strength, expiry, instructions — and speaks it back. Explicitly does
/// NOT diagnose or recommend dosage; it only relays what's printed, with
/// a mandatory safety disclaimer shown every time.
class MedicineReaderScreen extends StatefulWidget {
  const MedicineReaderScreen({super.key});

  @override
  State<MedicineReaderScreen> createState() => _MedicineReaderScreenState();
}

class _MedicineReaderScreenState extends State<MedicineReaderScreen> {
  String? _extractedText;
  bool _processing = false;

  Future<void> _onCaptured(String imagePath) async {
    setState(() => _processing = true);
    final text = await OcrService.instance.extractTextSmart(imagePath);
    await TempFileCleaner.deleteQuietly(imagePath);
    if (!mounted) return;
    setState(() {
      _processing = false;
      _extractedText = text;
    });
    final toSpeak = text ?? AppStrings.errOcrGeneric;
    await TextToSpeechService.instance.speak('$toSpeak. ${AppStrings.medicineDisclaimer}');
  }

  @override
  void dispose() {
    TextToSpeechService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Reader')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_rounded, color: scheme.error),
                    const SizedBox(width: 10),
                    Expanded(child: Text(AppStrings.medicineDisclaimer)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _extractedText == null && !_processing
                    ? CameraCaptureView(
                        instructionText: 'Show the medicine label or box to the camera.',
                        onCaptured: _onCaptured,
                      )
                    : _processing
                        ? const Center(child: CircularProgressIndicator())
                        : _buildResult(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              _extractedText ?? AppStrings.errOcrGeneric,
              style: const TextStyle(fontSize: 20, height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  if (_extractedText != null) {
                    TextToSpeechService.instance.speak(_extractedText!);
                  }
                },
                icon: const Icon(Icons.replay_rounded),
                label: const Text('REPEAT'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _extractedText = null),
                child: const Text('SCAN AGAIN'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
