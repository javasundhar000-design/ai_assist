import 'package:aura_stylist_ai/features/vision/domain/services/color_science.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ColorScience.rgbToHsv', () {
    test('pure red is hue 0, full saturation and value', () {
      final (h, s, v) = ColorScience.rgbToHsv(255, 0, 0);
      expect(h, closeTo(0, 0.01));
      expect(s, closeTo(1.0, 0.01));
      expect(v, closeTo(1.0, 0.01));
    });

    test('pure green is hue 120', () {
      final (h, _, _) = ColorScience.rgbToHsv(0, 255, 0);
      expect(h, closeTo(120, 0.01));
    });

    test('white has zero saturation', () {
      final (_, s, v) = ColorScience.rgbToHsv(255, 255, 255);
      expect(s, closeTo(0, 0.01));
      expect(v, closeTo(1.0, 0.01));
    });

    test('black has zero value', () {
      final (_, _, v) = ColorScience.rgbToHsv(0, 0, 0);
      expect(v, closeTo(0, 0.01));
    });
  });

  group('ColorScience.rgbToLab', () {
    test('white maps to L=100, a=0, b=0', () {
      final (l, a, b) = ColorScience.rgbToLab(255, 255, 255);
      expect(l, closeTo(100, 0.5));
      expect(a, closeTo(0, 0.5));
      expect(b, closeTo(0, 0.5));
    });

    test('black maps to L=0', () {
      final (l, _, __) = ColorScience.rgbToLab(0, 0, 0);
      expect(l, closeTo(0, 0.5));
    });

    test('a lighter color has a higher L than a darker one', () {
      final (lightL, _, __) = ColorScience.rgbToLab(220, 190, 170);
      final (darkL, _, ___) = ColorScience.rgbToLab(90, 60, 45);
      expect(lightL, greaterThan(darkL));
    });
  });

  group('ColorSample', () {
    test('fromRgb computes consistent luminance ordering', () {
      final bright = ColorSample.fromRgb(230, 210, 190);
      final dark = ColorSample.fromRgb(60, 45, 35);
      expect(bright.luminance, greaterThan(dark.luminance));
    });
  });
}
