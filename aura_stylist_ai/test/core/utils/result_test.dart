import 'package:aura_stylist_ai/core/errors/failure.dart';
import 'package:aura_stylist_ai/core/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Success exposes data via when() and valueOrNull', () {
      const result = Success<int>(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 42);

      final mapped = result.when(
        success: (data) => 'got $data',
        failure: (f) => 'failed: ${f.message}',
      );
      expect(mapped, 'got 42');
    });

    test('Err exposes failure via when() and valueOrNull is null', () {
      const result = Err<int>(AuthFailure('nope'));

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);

      final mapped = result.when(
        success: (data) => 'got $data',
        failure: (f) => 'failed: ${f.message}',
      );
      expect(mapped, 'failed: nope');
    });
  });
}
