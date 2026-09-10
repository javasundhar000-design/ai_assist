import 'package:aura_stylist_ai/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile', () {
    test('toMap/fromMap round-trips all fields', () {
      final profile = UserProfile(
        uid: 'uid-1',
        name: 'Priya',
        email: 'priya@example.com',
        gender: 'Female',
        age: 27,
        preferredLanguage: 'ta',
        skinTone: 'Medium',
        bodyType: 'Athletic',
        faceShape: 'Oval',
        photoUrl: 'https://example.com/photo.jpg',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      final map = profile.toMap();
      final restored = UserProfile.fromMap('uid-1', map);

      expect(restored, profile);
    });

    test('fromMap applies sensible defaults for missing fields', () {
      final restored = UserProfile.fromMap('uid-2', const {});

      expect(restored.name, 'Stylist');
      expect(restored.preferredLanguage, 'en');
      expect(restored.email, isNull);
      expect(restored.skinTone, isNull);
    });

    test('fromMap tolerates age/createdAt arriving as double (RTDB numbers)', () {
      final restored = UserProfile.fromMap('uid-3', {
        'name': 'Arjun',
        'age': 30.0,
        'createdAt': 1700000000000.0,
      });

      expect(restored.age, 30);
      expect(restored.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });

    test('copyWith only overrides the given fields', () {
      final profile = UserProfile(
        uid: 'uid-4',
        name: 'Original',
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = profile.copyWith(name: 'Updated', age: 22);

      expect(updated.name, 'Updated');
      expect(updated.age, 22);
      expect(updated.uid, profile.uid);
      expect(updated.createdAt, profile.createdAt);
    });
  });
}
