import 'package:aura_stylist_ai/core/errors/failure.dart';
import 'package:aura_stylist_ai/features/profile/domain/entities/user_profile.dart';
import 'package:aura_stylist_ai/features/profile/presentation/providers/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_profile_repository.dart';

void main() {
  group('ProfileController', () {
    test('save() succeeds and marks isSuccess', () async {
      final repo = FakeProfileRepository();
      final controller = ProfileController(repo);
      final profile = UserProfile(
        uid: 'uid-1',
        name: 'Priya',
        createdAt: DateTime.now(),
      );

      await controller.save(profile);

      expect(controller.state.isSubmitting, isFalse);
      expect(controller.state.isSuccess, isTrue);
      expect(controller.state.errorMessage, isNull);
    });

    test('save() surfaces a failure message on error', () async {
      final repo = FakeProfileRepository()
        ..failureToReturn = const UnknownFailure('Database error.');
      final controller = ProfileController(repo);
      final profile = UserProfile(
        uid: 'uid-1',
        name: 'Priya',
        createdAt: DateTime.now(),
      );

      await controller.save(profile);

      expect(controller.state.isSuccess, isFalse);
      expect(controller.state.errorMessage, 'Database error.');
    });
  });
}
