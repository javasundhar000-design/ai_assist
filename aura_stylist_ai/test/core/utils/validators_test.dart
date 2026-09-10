import 'package:aura_stylist_ai/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty input', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
    });

    test('rejects malformed addresses', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('missing@tld'), isNotNull);
    });

    test('accepts valid addresses', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('  user@example.com  '), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects empty and too-short passwords', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('12345'), isNotNull);
    });

    test('accepts 6+ character passwords', () {
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects mismatches and empty input', () {
      expect(Validators.confirmPassword('', 'abcdef'), isNotNull);
      expect(Validators.confirmPassword('abcdeg', 'abcdef'), isNotNull);
    });

    test('accepts an exact match', () {
      expect(Validators.confirmPassword('abcdef', 'abcdef'), isNull);
    });
  });

  group('Validators.displayName', () {
    test('rejects empty or single-character names', () {
      expect(Validators.displayName(''), isNotNull);
      expect(Validators.displayName('A'), isNotNull);
    });

    test('accepts a normal name', () {
      expect(Validators.displayName('Priya'), isNull);
    });
  });
}
