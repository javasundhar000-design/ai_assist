import 'package:aura_stylist_ai/core/errors/failure.dart';
import 'package:aura_stylist_ai/features/auth/presentation/providers/login_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_auth_repository.dart';

void main() {
  group('LoginController', () {
    test('submit() succeeds and updates state to isSuccess', () async {
      final repo = FakeAuthRepository();
      final controller = LoginController(repo);

      expect(controller.state.isSubmitting, isFalse);

      final future = controller.submit(
        email: 'test@example.com',
        password: 'password123',
        rememberMe: true,
      );

      expect(controller.state.isSubmitting, isTrue);
      await future;

      expect(controller.state.isSubmitting, isFalse);
      expect(controller.state.isSuccess, isTrue);
      expect(controller.state.errorMessage, isNull);
      expect(repo.currentUser, isNotNull);
    });

    test('submit() surfaces a failure message and does not sign in', () async {
      final repo = FakeAuthRepository()
        ..failureToReturn = const AuthFailure('Incorrect email or password.');
      final controller = LoginController(repo);

      await controller.submit(
        email: 'wrong@example.com',
        password: 'bad',
        rememberMe: true,
      );

      expect(controller.state.isSubmitting, isFalse);
      expect(controller.state.isSuccess, isFalse);
      expect(controller.state.errorMessage, 'Incorrect email or password.');
      expect(repo.currentUser, isNull);
    });

    test('continueAsGuest() signs in an anonymous user', () async {
      final repo = FakeAuthRepository();
      final controller = LoginController(repo);

      await controller.continueAsGuest();

      expect(controller.state.isSuccess, isTrue);
      expect(repo.currentUser?.isGuest, isTrue);
    });

    test('submit() persists the rememberMe preference', () async {
      final repo = FakeAuthRepository();
      final controller = LoginController(repo);

      await controller.submit(
        email: 'test@example.com',
        password: 'password123',
        rememberMe: false,
      );

      expect(repo.rememberMe, isFalse);
    });
  });
}
