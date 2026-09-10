import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused, continued }

/// One shared TTS engine for the whole app (Section 16). Every module —
/// Vision, Communication, Eye Control — calls this instead of creating
/// its own FlutterTts instance, so speed/pitch/language settings applied
/// once in Accessibility Settings apply everywhere.
class TextToSpeechService {
  TextToSpeechService._();
  static final TextToSpeechService instance = TextToSpeechService._();

  final FlutterTts _tts = FlutterTts();
  TtsState state = TtsState.stopped;

  Future<void> init() async {
    await _tts.awaitSpeakCompletion(true);
    _tts.setStartHandler(() => state = TtsState.playing);
    _tts.setCompletionHandler(() => state = TtsState.stopped);
    _tts.setCancelHandler(() => state = TtsState.stopped);
    _tts.setPauseHandler(() => state = TtsState.paused);
    _tts.setContinueHandler(() => state = TtsState.continued);
    _tts.setErrorHandler((_) => state = TtsState.stopped);
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.speak(text);
  }

  Future<void> pause() async {
    await _tts.pause();
  }

  /// flutter_tts has no true "resume" on all platforms; re-speaking the
  /// remaining text is the practical cross-platform approach, so callers
  /// (e.g. Book Reader) should track reading position themselves and pass
  /// the remaining substring back in.
  Future<void> resume(String remainingText) async {
    await speak(remainingText);
  }

  Future<void> stop() async {
    await _tts.stop();
    state = TtsState.stopped;
  }

  Future<void> setSpeed(double rate) async {
    // flutter_tts expects 0.0–1.0 on most platforms.
    await _tts.setSpeechRate(rate.clamp(0.1, 1.0).toDouble());
  }

  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch.clamp(0.5, 2.0).toDouble());
  }

  Future<void> setLanguage(String languageCode) async {
    await _tts.setLanguage(languageCode);
  }
}
