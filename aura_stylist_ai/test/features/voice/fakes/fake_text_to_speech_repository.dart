import 'package:aura_stylist_ai/core/utils/result.dart';
import 'package:aura_stylist_ai/features/voice/domain/repositories/text_to_speech_repository.dart';

class FakeTextToSpeechRepository implements TextToSpeechRepository {
  final List<String> spokenPhrases = [];

  @override
  Future<Result<void>> initialize() async => const Success(null);

  @override
  Future<Result<void>> speak(String text) async {
    spokenPhrases.add(text);
    return const Success(null);
  }

  @override
  Future<Result<void>> stop() async => const Success(null);
}
