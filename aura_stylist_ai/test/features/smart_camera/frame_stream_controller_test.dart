import 'package:aura_stylist_ai/core/errors/failure.dart';
import 'package:aura_stylist_ai/features/smart_camera/presentation/providers/camera_providers.dart';
import 'package:aura_stylist_ai/features/smart_camera/presentation/providers/frame_stream_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_camera_repository.dart';

void main() {
  group('FrameStreamController', () {
    test('start() sets isStreaming and calls repository.startFrameStream()', () async {
      final fakeRepo = FakeCameraRepository();
      final container = ProviderContainer(
        overrides: [cameraRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final controller = container.read(frameStreamControllerProvider.notifier);
      expect(container.read(frameStreamControllerProvider).isStreaming, isFalse);

      await controller.start();

      expect(fakeRepo.startFrameStreamCalled, isTrue);
      expect(container.read(frameStreamControllerProvider).isStreaming, isTrue);
    });

    test('stop() clears isStreaming and calls repository.stopFrameStream()', () async {
      final fakeRepo = FakeCameraRepository();
      final container = ProviderContainer(
        overrides: [cameraRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final controller = container.read(frameStreamControllerProvider.notifier);
      await controller.start();
      await controller.stop();

      expect(fakeRepo.stopFrameStreamCalled, isTrue);
      expect(container.read(frameStreamControllerProvider).isStreaming, isFalse);
      expect(container.read(frameStreamControllerProvider).fps, 0);
    });

    test('start() leaves isStreaming false if the repository fails to start', () async {
      final fakeRepo = FakeCameraRepository()
        ..startFrameStreamFailure = const UnknownFailure('Camera busy.');
      final container = ProviderContainer(
        overrides: [cameraRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final controller = container.read(frameStreamControllerProvider.notifier);
      await controller.start();

      expect(container.read(frameStreamControllerProvider).isStreaming, isFalse);
    });

    test('start() is a no-op if already streaming', () async {
      final fakeRepo = FakeCameraRepository();
      final container = ProviderContainer(
        overrides: [cameraRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final controller = container.read(frameStreamControllerProvider.notifier);
      await controller.start();
      fakeRepo.startFrameStreamCalled = false; // reset to detect a second call
      await controller.start();

      expect(fakeRepo.startFrameStreamCalled, isFalse);
    });
  });
}
