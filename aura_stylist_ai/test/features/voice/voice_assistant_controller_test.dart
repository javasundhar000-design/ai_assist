import 'package:aura_stylist_ai/core/permissions/app_permission.dart';
import 'package:aura_stylist_ai/core/permissions/permission_providers.dart';
import 'package:aura_stylist_ai/core/theme/theme_provider.dart';
import 'package:aura_stylist_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:aura_stylist_ai/features/voice/domain/entities/voice_command.dart';
import 'package:aura_stylist_ai/features/voice/presentation/providers/voice_assistant_controller.dart';
import 'package:aura_stylist_ai/features/voice/presentation/providers/voice_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/permissions/fakes/fake_permission_gateway.dart';
import 'fakes/fake_speech_recognition_repository.dart';
import 'fakes/fake_text_to_speech_repository.dart';

void main() {
  late FakeSpeechRecognitionRepository speechRepo;
  late FakeTextToSpeechRepository ttsRepo;
  late FakePermissionGateway permissionGateway;
  late ProviderContainer container;
  late SharedPreferences sharedPreferences;

  setUp(() async {
    // themeModeProvider (exercised by the darkMode/lightMode voice
    // commands below) now persists via SettingsLocalPreferences (Module
    // 11), which needs a real SharedPreferences instance — an in-memory
    // one via setMockInitialValues, same as production code gets a real
    // one from SharedPreferences.getInstance() in main().
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();

    speechRepo = FakeSpeechRecognitionRepository();
    ttsRepo = FakeTextToSpeechRepository();
    permissionGateway = FakePermissionGateway(initialStatus: AppPermissionState.granted);

    container = ProviderContainer(
      overrides: [
        speechRecognitionRepositoryProvider.overrideWithValue(speechRepo),
        textToSpeechRepositoryProvider.overrideWithValue(ttsRepo),
        permissionGatewayProvider.overrideWithValue(permissionGateway),
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpMicrotasks() => Future<void>.delayed(Duration.zero);

  test('does not start listening without microphone permission', () async {
    permissionGateway = FakePermissionGateway(initialStatus: AppPermissionState.denied);
    container = ProviderContainer(
      overrides: [
        speechRecognitionRepositoryProvider.overrideWithValue(speechRepo),
        textToSpeechRepositoryProvider.overrideWithValue(ttsRepo),
        permissionGatewayProvider.overrideWithValue(permissionGateway),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(voiceAssistantControllerProvider.notifier);
    await pumpMicrotasks(); // let the constructor's permission check resolve

    await controller.start();

    expect(container.read(voiceAssistantControllerProvider).isListening, isFalse);
    expect(speechRepo.startListeningCallCount, 0);
  });

  test('start() initializes and begins listening when permission is granted', () async {
    final controller = container.read(voiceAssistantControllerProvider.notifier);
    await pumpMicrotasks();

    await controller.start();

    expect(container.read(voiceAssistantControllerProvider).isListening, isTrue);
    expect(speechRepo.startListeningCallCount, 1);
  });

  test('a final "dark mode" transcript sets dark theme and speaks a confirmation', () async {
    final controller = container.read(voiceAssistantControllerProvider.notifier);
    await pumpMicrotasks();
    await controller.start();

    speechRepo.emit('dark mode');
    await pumpMicrotasks();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(container.read(voiceAssistantControllerProvider).lastCommand?.type,
        VoiceCommandType.darkMode);
    expect(ttsRepo.spokenPhrases, isNotEmpty);
    expect(ttsRepo.spokenPhrases.last.toLowerCase(), contains('dark mode'));
  });

  test('a final "light mode" transcript sets light theme', () async {
    final controller = container.read(voiceAssistantControllerProvider.notifier);
    await pumpMicrotasks();
    await controller.start();

    speechRepo.emit('light mode');
    await pumpMicrotasks();

    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('an unimplemented command (e.g. "capture") is acknowledged honestly, not silently dropped',
      () async {
    final controller = container.read(voiceAssistantControllerProvider.notifier);
    await pumpMicrotasks();
    await controller.start();

    speechRepo.emit('capture');
    await pumpMicrotasks();

    final state = container.read(voiceAssistantControllerProvider);
    expect(state.lastCommand?.type, VoiceCommandType.capture);
    expect(state.lastCommand?.type.isImplemented, isFalse);
    expect(ttsRepo.spokenPhrases.last, contains('arrives in'));
  });

  test('a partial (non-final) transcript updates partialText without dispatching a command',
      () async {
    final controller = container.read(voiceAssistantControllerProvider.notifier);
    await pumpMicrotasks();
    await controller.start();

    speechRepo.emit('dark', isFinal: false);
    await pumpMicrotasks();

    final state = container.read(voiceAssistantControllerProvider);
    expect(state.partialText, 'dark');
    expect(state.lastCommand, isNull);
    expect(ttsRepo.spokenPhrases, isEmpty);
  });

  test('listening restarts automatically after a final result (continuous listening)', () async {
    final controller = container.read(voiceAssistantControllerProvider.notifier);
    await pumpMicrotasks();
    await controller.start();
    expect(speechRepo.startListeningCallCount, 1);

    speechRepo.emit('next');
    await pumpMicrotasks();

    expect(speechRepo.startListeningCallCount, 2);
  });

  test('stop() clears isListening', () async {
    final controller = container.read(voiceAssistantControllerProvider.notifier);
    await pumpMicrotasks();
    await controller.start();
    expect(container.read(voiceAssistantControllerProvider).isListening, isTrue);

    await controller.stop();

    expect(container.read(voiceAssistantControllerProvider).isListening, isFalse);
    expect(speechRepo.isListening, isFalse);
  });
}
