import 'package:flutter_tts/flutter_tts.dart';

/// Single point of control for all speech output (spec §16).
/// Every screen that needs Play/Pause/Resume/Stop/Replay uses this instead
/// of instantiating its own FlutterTts.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  String _lastSpoken = '';

  double speechRate = 0.5; // 0.0 - 1.0
  double pitch = 1.0; // 0.5 - 2.0
  double volume = 1.0; // 0.0 - 1.0
  String language = 'en-US';

  Future<void> _applySettings() async {
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(speechRate);
    await _tts.setPitch(pitch);
    await _tts.setVolume(volume);
  }

  Future<void> speak(String text) async {
    await _applySettings();
    _lastSpoken = text;
    await _tts.speak(text);
  }

  Future<void> replay() async {
    if (_lastSpoken.isNotEmpty) {
      await speak(_lastSpoken);
    }
  }

  Future<void> pause() => _tts.pause();

  Future<void> stop() => _tts.stop();

  Future<List<dynamic>> availableVoices() async {
    final voices = await _tts.getVoices;
    return List<dynamic>.from(voices as List);
  }
}
