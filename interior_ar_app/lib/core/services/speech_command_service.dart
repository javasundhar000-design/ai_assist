import 'package:speech_to_text/speech_to_text.dart';

/// Maps recognized speech to app-level intents. Voice commands are an
/// optional accelerator (Section 17 — "do not make voice commands
/// mandatory for every action"), so every command here has an equivalent
/// on-screen button somewhere in the UI.
enum VoiceCommand {
  readThis,
  describeThis,
  readMedicine,
  openBookReader,
  stop,
  repeat,
  emergency,
  unknown,
}

class SpeechCommandService {
  SpeechCommandService._();
  static final SpeechCommandService instance = SpeechCommandService._();

  final SpeechToText _speech = SpeechToText();
  bool isListening = false;

  Future<bool> init() => _speech.initialize();

  Future<void> listen({
    required void Function(VoiceCommand command, String rawText) onCommand,
  }) async {
    if (!_speech.isAvailable) {
      final available = await init();
      if (!available) return;
    }
    isListening = true;
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          isListening = false;
          onCommand(_parse(result.recognizedWords), result.recognizedWords);
        }
      },
    );
  }

  Future<void> stopListening() async {
    isListening = false;
    await _speech.stop();
  }

  VoiceCommand _parse(String text) {
    final t = text.toLowerCase().trim();
    if (t.contains('emergency')) return VoiceCommand.emergency;
    if (t.contains('read medicine') || t.contains('medicine')) {
      return VoiceCommand.readMedicine;
    }
    if (t.contains('book reader') || t.contains('open book')) {
      return VoiceCommand.openBookReader;
    }
    if (t.contains('describe')) return VoiceCommand.describeThis;
    if (t.contains('repeat')) return VoiceCommand.repeat;
    if (t.contains('stop')) return VoiceCommand.stop;
    if (t.contains('read')) return VoiceCommand.readThis;
    return VoiceCommand.unknown;
  }
}
