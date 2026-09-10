import 'dart:ui';

import 'package:aura_stylist_ai/features/recommendation/domain/services/color_matching_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ColorMatchingService();

  group('nameFor', () {
    test('names an exact palette color correctly', () {
      expect(service.nameFor(const Color(0xFF1B2A4A)), 'Navy');
      expect(service.nameFor(const Color(0xFFD4AF37)), 'Gold');
    });

    test('names a near-palette color as its closest match', () {
      // Slightly off from pure Navy but clearly closer to Navy than
      // anything else in the palette.
      final name = service.nameFor(const Color(0xFF1C2C4C));
      expect(name, 'Navy');
    });
  });

  group('scoreFor', () {
    const fairPalette = ['Navy', 'Emerald', 'Burgundy', 'Cool Gray'];

    test('scores 100 for an exact recommended color', () {
      expect(service.scoreFor(const Color(0xFF1B2A4A), fairPalette), 100);
    });

    test('scores lower for a color far from any recommended color', () {
      final navyScore = service.scoreFor(const Color(0xFF1B2A4A), fairPalette);
      final fuchsiaScore = service.scoreFor(const Color(0xFFFF00FF), fairPalette);
      expect(fuchsiaScore, lessThan(navyScore));
    });

    test('never scores below the 20-point floor', () {
      final score = service.scoreFor(const Color(0xFFFFFFFF), fairPalette);
      expect(score, greaterThanOrEqualTo(20));
    });

    test('returns a neutral score when no recommended colors are given', () {
      expect(service.scoreFor(const Color(0xFF1B2A4A), const []), 50);
    });
  });
}
