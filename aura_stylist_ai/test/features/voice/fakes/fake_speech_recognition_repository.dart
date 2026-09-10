import 'dart:async';

import 'package:aura_stylist_ai/core/errors/failure.dart';
import 'package:aura_stylist_ai/core/utils/result.dart';
import 'package:aura_stylist_ai/features/voice/domain/entities/speech_recognition_event.dart';
import 'package:aura_stylist_ai/features/voice/domain/repositories/speech_recognition_repository.dart';

class FakeSpeechRecognitionRepository implements SpeechRecognitionRepository {
  final _controller = StreamController<SpeechRecognitionEvent>.broadcast();
  bool _isListening = false;

  bool availableOnInit = true;
  Failure? initializeFailure;
  Failure? startListeningFailure;

  int startListeningCallCount = 0;

  @override
  Stream<SpeechRecognitionEvent> get events => _controller.stream;

  @override
  bool get isListening => _isListening;

  @override
  Future<Result<bool>> initialize() async {
    if (initializeFailure != null) return Err(initializeFailure!);
    return Success(availableOnInit);
  }

  @override
  Future<Result<void>> startListening({String localeId = 'en_US'}) async {
    startListeningCallCount++;
    if (startListeningFailure != null) return Err(startListeningFailure!);
    _isListening = true;
    return const Success(null);
  }

  @override
  Future<Result<void>> stopListening() async {
    _isListening = false;
    return const Success(null);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  /// Test helper: simulate the plugin reporting a transcript.
  void emit(String text, {bool isFinal = true, double confidence = 0.9}) {
    _controller.add(SpeechRecognitionEvent(
      recognizedText: text,
      isFinal: isFinal,
      confidence: confidence,
    ));
  }
}
