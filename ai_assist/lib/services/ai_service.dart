import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../core/constants/app_config.dart';
import '../core/errors/app_exception.dart';
import 'secure_storage_service.dart';

/// Structured result of a vision task. [confidenceIsLow] drives the
/// "Some text could not be clearly recognized." style messaging (spec §7-11)
/// instead of ever letting the model's guess look like a stated fact.
class VisionResult {
  final String summary;
  final Map<String, String?> fields;
  final bool confidenceIsLow;

  const VisionResult({
    required this.summary,
    this.fields = const {},
    this.confidenceIsLow = false,
  });
}

/// All AI operations the app can perform. There is no backend anymore —
/// this talks to OpenRouter directly using a key the person enters in
/// Settings -> AI Configuration (see app_config.dart for the security
/// reasoning behind that choice). Every method maps 1:1 to the strict,
/// non-hallucinating prompts from spec §36-40.
abstract class AiService {
  Future<VisionResult> extractText(Uint8List image); // OCR (§7, §36)
  Future<VisionResult> recognizeMedicine(Uint8List image); // §8, §39
  Future<VisionResult> recognizeObject(Uint8List image); // §9, §37
  Future<VisionResult> recognizeCurrency(Uint8List image); // §10
  Future<VisionResult> understandScene(Uint8List image); // §11, §38
  Future<List<String>> generateWordSuggestions(String partialText); // §14, §40
  Future<List<String>> generateSentenceSuggestions(String partialText); // §15
}

const _ocrPrompt = '''
You are an OCR assistant for an accessibility application.
Read only text that is clearly visible in the supplied image.
Do not guess missing characters.
Preserve words, numbers, dates, headings, labels, medicine names, and prices.
If a section is unreadable, report it as unclear.
Return only the recognized text and a confidence indication.''';

const _objectPrompt = '''
You are an accessibility assistant.
Analyze the image for important visible objects.
Identify only objects that are reasonably visible.
For each object provide: name, approximate position (left/center/right, near/far), and a short description.
Do not invent objects.''';

const _scenePrompt = '''
You are an accessibility assistant helping a visually impaired person.
Describe the visible environment concisely.
Mention: location/environment, important objects, people, obstacles, and potentially useful safety information.
Use simple natural language. Do not speculate about information that cannot be seen.''';

const _medicinePrompt = '''
You are assisting with reading medicine packaging.
Extract only clearly visible printed information.
Return: medicine name, strength, manufacturer, expiry date, and batch number if visible.
Never guess missing information. Do not provide medical diagnosis or medical advice.''';

const _currencyPrompt = '''
You are an accessibility assistant identifying currency.
Identify only the currency, country, and denomination if clearly visible in the image.
If you are not confident, say so plainly instead of guessing.''';

const _textSuggestionPrompt = '''
You are an accessibility communication assistant.
The user is typing a message. Based on the partial text, generate 3-5 short, natural suggestions.
Use simple language. Do not change the user's intended meaning.
Return JSON only: {"suggestions": ["...", "...", "..."]}''';

/// Calls OpenRouter directly from the device using the key stored in
/// SecureStorageService. Throws a friendly AppException (spec §44) if no
/// key has been configured yet, prompting the person to add one in
/// Settings, rather than a raw 401 from OpenRouter.
class OpenRouterAiService implements AiService {
  final SecureStorageService _secureStorage;
  final Dio _dio;

  OpenRouterAiService({SecureStorageService? secureStorage, Dio? dio})
      : _secureStorage = secureStorage ?? SecureStorageService(),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.openRouterBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 45),
            ));

  Future<String> _requireKey() async {
    final key = await _secureStorage.getOpenRouterKey();
    if (key == null || key.trim().isEmpty) {
      throw const AppException(
          'Add your OpenRouter API key in Settings -> AI Configuration to use AI features.');
    }
    return key;
  }

  /// No model is hardcoded — this reads whatever the person configured in
  /// Settings, or falls back to OpenRouter's own "auto" router, which picks
  /// a suitable model per request. The same resolution is used whether the
  /// call involves an image or plain text.
  Future<String> _resolveModel() async {
    final model = await _secureStorage.getOpenRouterModel();
    return (model == null || model.trim().isEmpty) ? AppConfig.defaultOpenRouterModel : model.trim();
  }

  Future<String> _chat({
    required String systemPrompt,
    required dynamic userContent,
  }) async {
    final key = await _requireKey();
    final model = await _resolveModel();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/chat/completions',
        options: Options(headers: {'Authorization': 'Bearer $key'}),
        data: {
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userContent},
          ],
        },
      );
      final choices = response.data?['choices'] as List?;
      String? content;

      if (choices!.isNotEmpty) {
        final message = choices.first['message'];

        if (message is Map<String, dynamic>) {
          final value = message['content'];

          if (value is String) {
            content = value;
          }
        }
      }
      return content ?? '';
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  VisionResult _validate(String raw) {
    final text = raw.trim();
    final lower = text.toLowerCase();
    // Spec §35: validate before trusting — flag uncertain language as
    // low-confidence rather than silently presenting a guess as fact.
    const uncertainMarkers = [
      'cannot confidently',
      'unclear',
      'could not be',
      'not clearly visible',
      "can't tell",
    ];
    final confidenceIsLow = text.isEmpty || uncertainMarkers.any((m) => lower.contains(m));
    return VisionResult(
      summary: text.isNotEmpty ? text : 'Information could not be clearly read.',
      confidenceIsLow: confidenceIsLow,
    );
  }

  Future<VisionResult> _analyzeImage(String systemPrompt, Uint8List image) async {
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(image)}';
    final content = [
      {'type': 'text', 'text': 'Analyze the attached image according to your instructions.'},
      {
        'type': 'image_url',
        'image_url': {'url': dataUrl},
      },
    ];
    final raw = await _chat(systemPrompt: systemPrompt, userContent: content);
    return _validate(raw);
  }

  @override
  Future<VisionResult> extractText(Uint8List image) => _analyzeImage(_ocrPrompt, image);

  @override
  Future<VisionResult> recognizeMedicine(Uint8List image) => _analyzeImage(_medicinePrompt, image);

  @override
  Future<VisionResult> recognizeObject(Uint8List image) => _analyzeImage(_objectPrompt, image);

  @override
  Future<VisionResult> recognizeCurrency(Uint8List image) => _analyzeImage(_currencyPrompt, image);

  @override
  Future<VisionResult> understandScene(Uint8List image) => _analyzeImage(_scenePrompt, image);

  Future<List<String>> _suggest(String partialText, String mode) async {
    final systemPrompt =
        '$_textSuggestionPrompt\nMode: ${mode == 'word' ? 'single next words' : 'full sentence completions'}.';
    final raw = await _chat(systemPrompt: systemPrompt, userContent: partialText);
    try {
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start == -1 || end == -1) return [];
      final parsed = jsonDecode(raw.substring(start, end + 1));
      final list = parsed['suggestions'];
      if (list is List) return list.map((e) => e.toString()).take(5).toList();
    } catch (_) {
      // Suggestions are a convenience — a parse failure returns an empty
      // list rather than surfacing a raw error to the user (spec §44).
    }
    return [];
  }

  @override
  Future<List<String>> generateWordSuggestions(String partialText) => _suggest(partialText, 'word');

  @override
  Future<List<String>> generateSentenceSuggestions(String partialText) =>
      _suggest(partialText, 'sentence');
}

/// Deterministic canned responses shown when no OpenRouter key has been
/// configured yet, so the full UX (results screens, TTS, suggestion chips,
/// loading/error states) can be explored immediately on first install.
class DemoAiService implements AiService {
  Future<void> _think() => Future.delayed(AppConfig.mockLatency * 2);

  @override
  Future<VisionResult> extractText(Uint8List image) async {
    await _think();
    return const VisionResult(
      summary:
          'SATHYABAMA UNIVERSITY\nDepartment of Computer Science\nAnnual Report 2026\n\nSome text near the bottom margin could not be clearly recognized.',
      confidenceIsLow: true,
    );
  }

  @override
  Future<VisionResult> recognizeMedicine(Uint8List image) async {
    await _think();
    return const VisionResult(
      summary: 'Medicine label recognized.',
      fields: {
        'Medicine Name': 'Paracetamol',
        'Strength': '500 mg',
        'Manufacturer': 'Information could not be clearly read.',
        'Expiry Date': '11/2027',
        'Batch Number': null,
      },
    );
  }

  @override
  Future<VisionResult> recognizeObject(Uint8List image) async {
    await _think();
    return const VisionResult(
      summary:
          'Chair detected in front of you. Table to the left. Door in the distance, center.',
      fields: {
        'Chair': 'center, near',
        'Table': 'left, near',
        'Door': 'center, far',
      },
    );
  }

  @override
  Future<VisionResult> recognizeCurrency(Uint8List image) async {
    await _think();
    return const VisionResult(
      summary: 'Indian Rupee — ₹500 note detected.',
      fields: {'Currency': 'Indian Rupee', 'Denomination': '₹500'},
    );
  }

  @override
  Future<VisionResult> understandScene(Uint8List image) async {
    await _think();
    return const VisionResult(
      summary:
          'You are in a park. A walking path is directly ahead. A bench is on the right and trees are on both sides.',
    );
  }

  @override
  Future<List<String>> generateWordSuggestions(String partialText) async {
    await _think();
    const bank = ['help', 'water', 'to go outside', 'medical assistance', 'a break'];
    return bank.take(4).toList();
  }

  @override
  Future<List<String>> generateSentenceSuggestions(String partialText) async {
    await _think();
    final trimmed = partialText.trim();
    if (trimmed.isEmpty) {
      return const ['I need help.', 'I am fine.', 'Please wait.'];
    }
    return [
      '$trimmed go home.',
      '$trimmed speak with someone.',
      '$trimmed use the restroom.',
    ];
  }
}

/// Tries the real OpenRouter service first; if no key has been configured
/// (the specific "add a key" AppException), transparently falls back to the
/// demo responses instead of dead-ending the whole screen. Any other error
/// (bad key, no internet, rate limit) still surfaces normally so it isn't
/// silently masked.
class HybridAiService implements AiService {
  final OpenRouterAiService _real;
  final DemoAiService _demo = DemoAiService();
  final SecureStorageService _secureStorage;

  HybridAiService({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService(),
        _real = OpenRouterAiService(secureStorage: secureStorage);

  Future<T> _withFallback<T>(Future<T> Function(AiService) call) async {
    final key = await _secureStorage.getOpenRouterKey();
    if (key == null || key.trim().isEmpty) {
      return call(_demo);
    }
    return call(_real);
  }

  @override
  Future<VisionResult> extractText(Uint8List image) => _withFallback((s) => s.extractText(image));

  @override
  Future<VisionResult> recognizeMedicine(Uint8List image) =>
      _withFallback((s) => s.recognizeMedicine(image));

  @override
  Future<VisionResult> recognizeObject(Uint8List image) =>
      _withFallback((s) => s.recognizeObject(image));

  @override
  Future<VisionResult> recognizeCurrency(Uint8List image) =>
      _withFallback((s) => s.recognizeCurrency(image));

  @override
  Future<VisionResult> understandScene(Uint8List image) =>
      _withFallback((s) => s.understandScene(image));

  @override
  Future<List<String>> generateWordSuggestions(String partialText) =>
      _withFallback((s) => s.generateWordSuggestions(partialText));

  @override
  Future<List<String>> generateSentenceSuggestions(String partialText) =>
      _withFallback((s) => s.generateSentenceSuggestions(partialText));
}
