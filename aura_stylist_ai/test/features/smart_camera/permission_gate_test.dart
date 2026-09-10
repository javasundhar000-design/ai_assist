import 'package:aura_stylist_ai/core/permissions/app_permission.dart';
import 'package:aura_stylist_ai/features/smart_camera/presentation/widgets/permission_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PermissionGate', () {
    testWidgets('shows "Grant Camera Access" and calls onRequest when denied',
        (tester) async {
      var requestCalled = false;
      var settingsCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: PermissionGate(
            state: AppPermissionState.denied,
            onRequest: () => requestCalled = true,
            onOpenSettings: () => settingsCalled = true,
          ),
        ),
      );

      expect(find.text('Grant Camera Access'), findsOneWidget);
      await tester.tap(find.text('Grant Camera Access'));
      expect(requestCalled, isTrue);
      expect(settingsCalled, isFalse);
    });

    testWidgets(
        'shows "Open Settings" and calls onOpenSettings when permanently denied',
        (tester) async {
      var requestCalled = false;
      var settingsCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: PermissionGate(
            state: AppPermissionState.permanentlyDenied,
            onRequest: () => requestCalled = true,
            onOpenSettings: () => settingsCalled = true,
          ),
        ),
      );

      expect(find.text('Open Settings'), findsOneWidget);
      await tester.tap(find.text('Open Settings'));
      expect(settingsCalled, isTrue);
      expect(requestCalled, isFalse);
    });
  });
}
