import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper around flutter_tts so every screen speaks with the same
/// configured voice/rate, and so we only initialize the plugin once.
class TtsService {
  TtsService._internal();
  static final TtsService instance = TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5); // slower, clearer default
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureInit();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> setRate(double rate) async {
    await _ensureInit();
    await _tts.setSpeechRate(rate);
  }

  Future<void> setLanguage(String bcp47Code) async {
    await _ensureInit();
    await _tts.setLanguage(bcp47Code);
  }
}
