import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Optional cloud AI layer, added specifically because on-device ML Kit
/// has real, known accuracy limits the spec's Section 35 already
/// anticipated: "Online AI should be optional... the basic application
/// must remain functional without cloud AI." ML Kit's bundled object
/// detector only classifies ~5 very coarse categories (fashion goods,
/// food, home goods, place, plant) unless custom-trained, and its OCR
/// struggles with small/angled/low-contrast text like medicine labels.
///
/// This uses Google's Gemini API (generativelanguage.googleapis.com)
/// because it's multimodal — one HTTP call handles OCR, object
/// identification, scene description, and currency recognition, all
/// through a tailored prompt, rather than needing four separate cloud
/// SDKs. The user supplies their own API key (Settings -> AI
/// Enhancement); nothing is called unless a key is configured, and every
/// caller in this app falls back to the on-device path if this returns
/// null (no key, no network, or an API error).
class AiVisionService {
  AiVisionService._();
  static final AiVisionService instance = AiVisionService._();

  static const _model = 'gemini-2.0-flash';
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  Future<String?> _generate({
    required String apiKey,
    required String prompt,
    required List<int> imageBytes,
  }) async {
    try {
      final uri = Uri.parse('$_endpoint?key=$apiKey');
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Encode(imageBytes),
                }
              },
            ],
          }
        ],
        'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 400},
      });

      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;

      final text = (parts.first['text'] as String?)?.trim();
      return (text == null || text.isEmpty) ? null : text;
    } on SocketException {
      return null; // No connectivity — caller falls back to offline path.
    } catch (_) {
      return null; // Any other failure — same fallback contract.
    }
  }

  /// Reads and transcribes visible text — used to enhance Vision Reader,
  /// Medicine Reader, and Book Reader beyond ML Kit's on-device accuracy.
  Future<String?> readText(String apiKey, List<int> imageBytes) {
    return _generate(
      apiKey: apiKey,
      imageBytes: imageBytes,
      prompt: 'Transcribe all visible text in this image exactly as printed, '
          'in reading order. Reply with only the transcribed text and '
          'nothing else — no commentary, no markdown formatting.',
    );
  }

  /// Identifies objects with coarse left/right/center position, spoken
  /// as short sentences — replaces ML Kit's ~5-category limitation.
  Future<String?> describeObjects(String apiKey, List<int> imageBytes) {
    return _generate(
      apiKey: apiKey,
      imageBytes: imageBytes,
      prompt: 'List the distinct physical objects clearly visible in this '
          'image. For each, name it and say whether it is on the left, '
          'right, or center of the frame. Reply as short sentences like '
          '"A chair detected on your left.", one per line. Do not guess '
          'distances. If nothing is clearly identifiable, say so plainly.',
    );
  }

  /// Free-form description of the whole scene, for Section 15's Describe
  /// Surroundings — the offline fallback for this feature is honest
  /// about having no output at all, so this is the feature's real value.
  Future<String?> describeScene(String apiKey, List<int> imageBytes) {
    return _generate(
      apiKey: apiKey,
      imageBytes: imageBytes,
      prompt: 'Describe this scene in two or three short sentences for a '
          'blind person, focused on what is physically around them '
          '(people, furniture, obstacles, layout) rather than aesthetics. '
          'Be concrete and spatial. Do not mention that this is an image.',
    );
  }

  /// Identifies an Indian currency note's denomination — used to enhance
  /// the OCR-only fallback in Currency Assistant.
  Future<String?> identifyCurrency(String apiKey, List<int> imageBytes) {
    return _generate(
      apiKey: apiKey,
      imageBytes: imageBytes,
      prompt: 'This image shows an Indian currency note. Reply with only '
          'the denomination, like "500 rupees". If you cannot identify it '
          'confidently, reply with exactly: unclear.',
    );
  }
}
