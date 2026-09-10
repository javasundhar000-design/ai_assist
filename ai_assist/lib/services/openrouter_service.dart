import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Central service for all OpenRouter calls used across AI Assist:
/// - Vision tasks (Blind Mode): OCR, object recognition, scene description,
///   currency ID, medicine label reading.
/// - Text-only tasks (Non-Speaking Mode): quick phrase generation,
///   notepad word/sentence suggestions, translation.
///
/// IMPORTANT (read before shipping):
/// Do NOT ship this key hardcoded in a production APK — it can be extracted
/// via reverse engineering. For a prototype / coursework project this is
/// fine. For real deployment, move this class's HTTP call behind your own
/// backend (Flutter -> your server -> OpenRouter) and keep the key server-side.
class OpenRouterService {
  static const String _apiUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  // Replace with your real key, or better: load it from --dart-define
  // at build time so it's not committed to source control:
  //   flutter run --dart-define=OPENROUTER_API_KEY=sk-or-v1-xxxx
  static const String _apiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: 'YOUR_OPENROUTER_API_KEY',
  );

  // Model used for BOTH vision and text tasks.
  //
  // 'openrouter/free' is OpenRouter's own free auto-router: instead of you
  // pinning one specific model, it inspects each request and picks a free
  // model that supports what that request needs (image understanding, tool
  // calling, structured outputs, etc). That means:
  //   - $0 cost per request
  //   - no need to keep this string updated as individual free models
  //     get renamed, deprecated, or swapped by their providers
  //   - one constant covers both the vision calls (Blind Mode) and the
  //     text-only calls (Non-Speaking Mode)
  //
  // Trade-off: since it's free and routes across different underlying
  // models, response quality/latency can vary request to request. If you
  // later want consistent, higher-quality output and don't mind paying,
  // swap this for a specific paid model id (e.g. 'openai/gpt-4o-mini' for
  // text, 'google/gemini-2.0-flash-001' for vision) instead.
  static const String _model = 'openrouter/free';

  static const String _systemPrompt = '''
You are AI Assist, an accessibility assistant for people with visual,
speech, and motor impairments.

Rules:
- Give clear, simple, and useful answers.
- Do not invent information that cannot be seen or verified.
- If something is uncertain, clearly say it is uncertain.
- Never give medical dosing instructions — only report what's printed.
- Keep responses concise enough to be read aloud comfortably.
''';

  Future<String> _postChat(List<Map<String, dynamic>> messages,
      {int maxTokens = 500}) async {
    if (_apiKey == 'YOUR_OPENROUTER_API_KEY') {
      throw Exception(
        'No OpenRouter API key configured. Run with '
        '--dart-define=OPENROUTER_API_KEY=your_key or set it in '
        'openrouter_service.dart for local testing.',
      );
    }

    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'messages': messages.map((message) {
              final cleanMessage = Map<String, dynamic>.from(message);
              cleanMessage.remove('_isVision');
              return cleanMessage;
            }).toList(),
            'temperature': 0.2,
            'max_tokens': maxTokens,
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw Exception(
        'OpenRouter error ${response.statusCode}: ${response.body}',
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final choices = data['choices'];
    if (choices == null || choices.isEmpty) {
      throw Exception('No AI response received.');
    }
    final content = choices[0]['message']['content'];
    if (content == null) {
      throw Exception('AI returned an empty response.');
    }
    // The free router can proxy to different underlying models, and some
    // of them return content as a plain string while others return a list
    // of content parts (e.g. [{'type': 'text', 'text': '...'}]). Handle both.
    if (content is String) return content.trim();
    if (content is List) {
      return content
          .whereType<Map>()
          .map((part) => part['text'])
          .whereType<String>()
          .join()
          .trim();
    }
    throw Exception('AI returned an unsupported response format.');
  }

  /// Analyze an image (OCR, objects, scene, currency, medicine label, etc.)
  Future<String> analyzeImage({
    required File imageFile,
    required String task,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(imageFile.path);
      final imageData = 'data:$mimeType;base64,$base64Image';

      return await _postChat([
        {
          '_isVision': true,
          'role': 'system',
          'content': _systemPrompt,
        },
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': task},
            {
              'type': 'image_url',
              'image_url': {'url': imageData},
            },
          ],
        },
      ], maxTokens: 500);
    } catch (e) {
      throw Exception('Image processing failed: $e');
    }
  }

  /// Text-only helper for Non-Speaking Mode: word/sentence completion,
  /// quick-phrase generation, and translation.
  Future<String> generateText({
    required String prompt,
    String? systemOverride,
    int maxTokens = 200,
  }) async {
    try {
      return await _postChat([
        {
          '_isVision': false,
          'role': 'system',
          'content': systemOverride ?? _systemPrompt,
        },
        {
          'role': 'user',
          'content': prompt,
        },
      ], maxTokens: maxTokens);
    } catch (e) {
      throw Exception('Text generation failed: $e');
    }
  }

  String _getMimeType(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) return 'image/png';
    if (lowerPath.endsWith('.webp')) return 'image/webp';
    if (lowerPath.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}

/// Pre-built prompt templates so every screen asks OpenRouter for exactly
/// the right thing instead of one generic "describe this image" prompt.
class AssistPrompts {
  static const textRecognition = '''
Read all visible text in this image.
Return only the text that you can clearly read. Do not guess missing
characters. Preserve headings, numbers, dates, names, and labels in the
order they appear.
''';

  static const objectRecognition = '''
Identify the important objects visible in this image.
For each object, give its name, its approximate position (e.g. "left",
"center", "top right"), and a brief description.
Only mention objects that are reasonably visible.
''';

  static const sceneUnderstanding = '''
Describe this scene for a visually impaired person. Cover, in this order:
1. Where the person appears to be
2. Important objects
3. People present
4. Potential obstacles or hazards
5. Any important safety information
Use short, simple sentences suitable for text-to-speech.
''';

  static const currencyIdentification = '''
Identify the currency visible in this image.
Return: country/currency, denomination, and your confidence level.
Do not guess if the denomination cannot be clearly identified — say so.
''';

  static const medicineLabel = '''
Analyze this medicine package. Extract only clearly visible information:
- medicine name
- strength/dosage as printed on the package
- manufacturer, if visible
- expiry date, if visible
- other important printed information (e.g. "take with food")
Do not provide medical advice or dosing recommendations of your own.
If any field is unclear or not visible, say "unclear" for that field.
Recommend the user confirm with a pharmacist or doctor before taking it.
''';

  static const fullAnalysis = '''
Analyze this image for a visually impaired user. In order:
1. Read all clearly visible text (put this first if present).
2. Identify important objects.
3. Describe the scene briefly.
4. Mention any important safety information.
Keep it concise and suitable for text-to-speech.
''';
}
