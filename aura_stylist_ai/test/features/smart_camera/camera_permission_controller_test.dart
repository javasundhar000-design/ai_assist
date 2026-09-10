import 'package:aura_stylist_ai/core/permissions/app_permission.dart';
import 'package:aura_stylist_ai/features/smart_camera/presentation/providers/camera_permission_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/permissions/fakes/fake_permission_gateway.dart';

void main() {
  group('CameraPermissionController', () {
    test('initializes from the gateway\'s current status', () async {
      final gateway = FakePermissionGateway(initialStatus: AppPermissionState.granted);
      final controller = CameraPermissionController(gateway);

      // The constructor kicks off an async check; let it resolve.
      await Future<void>.delayed(Duration.zero);

      expect(controller.state, AppPermissionState.granted);
    });

    test('request() updates state to granted when the user allows it', () async {
      final gateway = FakePermissionGateway(initialStatus: AppPermissionState.denied)
        ..nextRequestResult = AppPermissionState.granted;
      final controller = CameraPermissionController(gateway);
      await Future<void>.delayed(Duration.zero);

      await controller.request();

      expect(controller.state, AppPermissionState.granted);
    });

    test('request() reflects permanently-denied without re-prompting', () async {
      final gateway = FakePermissionGateway(initialStatus: AppPermissionState.denied)
        ..nextRequestResult = AppPermissionState.permanentlyDenied;
      final controller = CameraPermissionController(gateway);
      await Future<void>.delayed(Duration.zero);

      await controller.request();

      expect(controller.state, AppPermissionState.permanentlyDenied);
    });

    test('openSettings() delegates to the gateway', () async {
      final gateway = FakePermissionGateway();
      final controller = CameraPermissionController(gateway);
      await Future<void>.delayed(Duration.zero);

      await controller.openSettings();

      expect(gateway.openSettingsCalled, isTrue);
    });
  });
}
