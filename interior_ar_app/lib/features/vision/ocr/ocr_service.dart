import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/services/ai_vision_service.dart';
import '../../../core/services/local_storage_service.dart';

/// Section 10/12: OCR shared by the general Vision Reader, Medicine
/// Reader, and Book Reader.
///
/// [extractTextSmart] is the hybrid entry point every screen should call:
/// it uses the optional cloud AI (Section 35 — "online AI should be
/// optional") when the user has configured an API key in Settings, since
/// ML Kit's on-device OCR genuinely struggles with small, angled, or
/// low-contrast text like medicine labels; it falls back to the fully
/// offline [extractTextFromImage] whenever no key is set, there's no
/// connectivity, or the cloud call fails for any reason — so the app
/// keeps working exactly as before with zero configuration.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> extractTextSmart(String imagePath) async {
    final apiKey = await LocalStorageService.instance.getAiApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final bytes = await File(imagePath).readAsBytes();
        final cloudResult = await AiVisionService.instance.readText(apiKey, bytes);
        if (cloudResult != null && cloudResult.isNotEmpty) return cloudResult;
      } catch (_) {
        // Fall through to on-device OCR below.
      }
    }
    return extractTextFromImage(imagePath);
  }

  /// Returns extracted text, or null if nothing could be read — callers
  /// should show [AppStrings.errOcrGeneric] rather than a raw empty state.
  Future<String?> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText result = await _recognizer.processImage(inputImage);
      final text = result.text.trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  /// Returns per-block text with bounding boxes, useful for structured
  /// reads like a medicine label where name/strength/expiry sit in
  /// distinct regions of the packaging.
  Future<List<TextBlock>> extractBlocks(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await _recognizer.processImage(inputImage);
      return result.blocks;
    } catch (_) {
      return [];
    }
  }

  void dispose() {
    _recognizer.close();
  }
}
