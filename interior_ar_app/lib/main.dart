import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/text_to_speech_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Offline-first: local storage and TTS must be ready before the first
  // frame that might need them (splash screen decides routing off of
  // LocalStorageService immediately).
  await LocalStorageService.instance.init();
  await TextToSpeechService.instance.init();

  runApp(const ProviderScope(child: AiAssistApp()));
}
