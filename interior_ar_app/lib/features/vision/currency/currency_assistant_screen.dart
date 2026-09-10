import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/services/ai_vision_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../core/utilities/temp_file_cleaner.dart';
import '../camera/camera_capture_view.dart';
import '../ocr/ocr_service.dart';

/// Section 14: Indian currency recognition. [SmartCurrencyClassifier] is
/// the default — it uses the cloud AI (see [AiVisionService]) when an
/// API key is configured, since a general model reliably reads a note's
/// full printed context (not just the numerals) far better than plain
/// OCR string-matching. It falls back to [OcrCurrencyClassifier] — the
/// original fully-offline implementation, unchanged — whenever no key is
/// set or the cloud call fails, so this keeps working with zero
/// configuration exactly as before.
abstract class CurrencyClassifier {
  Future<String?> classify(String imagePath);
}

class OcrCurrencyClassifier implements CurrencyClassifier {
  static const _denominations = ['2000', '500', '200', '100', '50', '20', '10'];

  @override
  Future<String?> classify(String imagePath) async {
    final text = await OcrService.instance.extractTextFromImage(imagePath);
    if (text == null) return null;
    for (final value in _denominations) {
      if (text.contains(value)) return value;
    }
    return null;
  }
}

class SmartCurrencyClassifier implements CurrencyClassifier {
  final CurrencyClassifier _offlineFallback = OcrCurrencyClassifier();

  @override
  Future<String?> classify(String imagePath) async {
    final apiKey = await LocalStorageService.instance.getAiApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final bytes = await File(imagePath).readAsBytes();
        final result = await AiVisionService.instance.identifyCurrency(apiKey, bytes);
        if (result != null && result.toLowerCase() != 'unclear') {
          return result;
        }
      } catch (_) {
        // Fall through to on-device OCR below.
      }
    }
    final offlineDenomination = await _offlineFallback.classify(imagePath);
    return offlineDenomination != null ? '$offlineDenomination rupees' : null;
  }
}

class CurrencyAssistantScreen extends StatefulWidget {
  const CurrencyAssistantScreen({super.key});

  @override
  State<CurrencyAssistantScreen> createState() => _CurrencyAssistantScreenState();
}

class _CurrencyAssistantScreenState extends State<CurrencyAssistantScreen> {
  final CurrencyClassifier _classifier = SmartCurrencyClassifier();
  bool _processing = false;
  String? _result;

  Future<void> _onCaptured(String imagePath) async {
    setState(() => _processing = true);
    final denomination = await _classifier.classify(imagePath);
    await TempFileCleaner.deleteQuietly(imagePath);
    if (!mounted) return;
    final message = denomination != null
        ? (denomination.toLowerCase().contains('rupee') ? '$denomination.' : '$denomination rupees.')
        : "I couldn't identify the note clearly. Please try again in better lighting.";
    setState(() {
      _processing = false;
      _result = message;
    });
    await TextToSpeechService.instance.speak(message);
  }

  @override
  void dispose() {
    TextToSpeechService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Currency')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _result == null && !_processing
              ? CameraCaptureView(
                  instructionText: 'Lay the note flat and capture in good light.',
                  onCaptured: _onCaptured,
                )
              : _processing
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_result ?? '', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => setState(() => _result = null),
                          child: const Text('SCAN AGAIN'),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
