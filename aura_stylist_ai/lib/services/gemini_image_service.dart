import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Generates real, actual images via Google's Gemini API image-generation
/// models ("Nano Banana") — not stock photos, not placeholders. Every image
/// returned here is freshly synthesized by the model from the text prompt
/// you give it, so there's no bundled or scraped photography involved and
/// no "which photo is copyrighted" question: it's new, generated content
/// produced through your own Gemini API key.
///
/// Setup: get a free key at https://aistudio.google.com/apikey, then run:
/// `flutter run --dart-define=GEMINI_API_KEY=your_key_here`
/// Image generation is billed per Google's current Gemini API pricing once
/// you're past the free tier — check https://ai.google.dev/pricing for
/// current rates before generating at volume.
///
/// **Model availability is genuinely unstable right now.** Gemini 2.5
/// models are scheduled to shut down in October 2026, "model not found"
/// 404s are a very common real-world issue with this API even for models
/// that should be live, and not every API key has access to every model.
/// Rather than hardcode one model name and fail outright, this tries a
/// short list of models in order and only reports failure once every
/// candidate has been tried — with Google's *actual* error text attached,
/// not a generic wrapper, so a real permissions/quota/model problem is
/// visible instead of hidden behind "didn't work."
class GeminiImageService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static bool get hasApiKey => _apiKey.isNotEmpty;

  /// Tried in order; update this list if Google ships a newer model or
  /// retires one of these. Run the curl check in the README before
  /// assuming the code is wrong — it usually means a model name here needs
  /// updating, not a bug in the request logic.
  static const _candidateModels = [
    'gemini-3.1-flash-image',
    'gemini-2.5-flash-image',
  ];

  Future<Uint8List> generateImage({required String prompt}) async {
    if (!hasApiKey) {
      throw Exception('No Gemini API key configured. Run with --dart-define=GEMINI_API_KEY=your_key');
    }

    final errors = <String>[];
    for (final model in _candidateModels) {
      try {
        return await _generateWithModel(model: model, prompt: prompt);
      } catch (e) {
        errors.add('$model → $e');
        debugPrint('[GeminiImageService] $model failed: $e');
      }
    }

    throw Exception('All Gemini models failed:\n${errors.join('\n')}');
  }

  Future<Uint8List> _generateWithModel({required String model, required String prompt}) async {
    final uri = Uri.parse('https://generativelanguage.googleapis.com/v1/models/$model:generateContent');
    final response = await http
        .post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _apiKey,
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'responseModalities': ['TEXT', 'IMAGE'],
        },
      }),
    )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      // Surface Google's actual error message (model not found, permission
      // denied, quota exceeded, etc.) rather than a generic failure.
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No candidates in response: ${response.body}');
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = (content?['parts'] as List?) ?? const [];
    for (final part in parts) {
      // The REST API's JSON mapping uses camelCase (inlineData/mimeType);
      // some client examples show snake_case, so this checks both.
      final inline = (part as Map<String, dynamic>)['inlineData'] ?? part['inline_data'];
      if (inline is Map<String, dynamic>) {
        final base64Data = inline['data'] as String?;
        if (base64Data != null) return base64Decode(base64Data);
      }
    }

    throw Exception('Response had no image part (model may only support text for this prompt): ${response.body}');
  }
}
