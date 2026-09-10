import 'package:flutter_test/flutter_test.dart';
import 'package:ai_assist/models/accessibility_role.dart';
import 'package:ai_assist/models/user_profile.dart';
import 'package:ai_assist/features/communication/prediction/prediction_service.dart';

void main() {
  group('AccessibilityRole', () {
    test('maps vision-family roles to the Vision module', () {
      expect(AccessibilityRole.blind.module, AppModule.vision);
      expect(AccessibilityRole.lowVision.module, AppModule.vision);
    });

    test('maps nonSpeaking to Communication and motorImpaired to EyeControl', () {
      expect(AccessibilityRole.nonSpeaking.module, AppModule.communication);
      expect(AccessibilityRole.motorImpaired.module, AppModule.eyeControl);
    });

    test('a mixed role set activates exactly the distinct modules it implies', () {
      final roles = {AccessibilityRole.blind, AccessibilityRole.nonSpeaking};
      expect(roles.activeModules, {AppModule.vision, AppModule.communication});
    });

    test('two vision-family roles together still activate a single module', () {
      final roles = {AccessibilityRole.blind, AccessibilityRole.lowVision};
      expect(roles.activeModules, {AppModule.vision});
    });

    test('fromStorage round-trips storageValue', () {
      for (final role in AccessibilityRole.values) {
        expect(AccessibilityRole.fromStorage(role.storageValue), role);
      }
    });
  });

  group('UserProfile', () {
    test('serializes and deserializes without losing role information', () {
      final user = UserProfile(
        id: 'abc123',
        name: 'Asha Rao',
        email: 'asha@example.com',
        passwordHash: 'hash',
        accessibilityProfiles: {AccessibilityRole.blind, AccessibilityRole.nonSpeaking},
        preferredLanguage: 'English',
        emergencyContact: '+911234567890',
        createdAt: DateTime(2026, 1, 1),
      );

      final json = user.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.id, user.id);
      expect(restored.name, user.name);
      expect(restored.accessibilityProfiles, user.accessibilityProfiles);
      expect(restored.emergencyContact, user.emergencyContact);
    });

    test('copyWith only changes the specified fields', () {
      final user = UserProfile(
        id: '1',
        name: 'A',
        email: 'a@a.com',
        passwordHash: 'h',
        accessibilityProfiles: {AccessibilityRole.blind},
        preferredLanguage: 'English',
        emergencyContact: '123',
        createdAt: DateTime(2026, 1, 1),
      );
      final updated = user.copyWith(accessibilityProfiles: {AccessibilityRole.motorImpaired});

      expect(updated.accessibilityProfiles, {AccessibilityRole.motorImpaired});
      expect(updated.name, user.name);
      expect(updated.id, user.id);
    });
  });

  group('PredictionService', () {
    final service = PredictionService.instance;

    test('suggests words starting with the current partial word', () {
      final suggestions = service.suggestWords('w');
      expect(suggestions, isNotEmpty);
      expect(suggestions.every((w) => w.startsWith('w')), isTrue);
    });

    test('returns no word suggestions for an empty fragment', () {
      expect(service.suggestWords(''), isEmpty);
    });

    test('suggests whole sentences for a known stem like "I need"', () {
      final sentences = service.suggestSentences('I need');
      expect(sentences, isNotEmpty);
      expect(sentences.any((s) => s.toLowerCase().contains('water')), isTrue);
    });

    test('combined suggest() splits trailing word vs stem correctly', () {
      final result = service.suggest('I need w');
      expect(result.words, isNotEmpty);
      expect(result.words.every((w) => w.startsWith('w')), isTrue);
    });
  });
}
