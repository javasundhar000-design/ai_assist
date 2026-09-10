import 'dart:ui';

import 'package:aura_stylist_ai/features/recommendation/domain/services/fashion_score_calculator.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/clothing_anchor_config.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/clothing_item.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/clothing_layer.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/fit_type.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/occasion.dart';
import 'package:aura_stylist_ai/features/vision/domain/entities/body_metrics.dart';
import 'package:aura_stylist_ai/features/vision/domain/entities/skin_tone.dart';
import 'package:flutter_test/flutter_test.dart';

ClothingItem _item({
  required Color color,
  FitType fit = FitType.regular,
  List<Occasion> occasions = const [Occasion.casual],
  ClothingLayer layer = ClothingLayer.shirt,
}) {
  return ClothingItem(
    id: 'test-${color.value}-$layer',
    name: 'Test item',
    layer: layer,
    color: color,
    anchorConfig: const ClothingAnchorConfig(reference: AnchorReference.neckToChest),
    fit: fit,
    suitableOccasions: occasions,
  );
}

void main() {
  const calculator = FashionScoreCalculator();

  test('empty item list returns an all-zero score with a helpful message', () {
    final score = calculator.calculate(items: const [], occasion: Occasion.casual);
    expect(score.overallScore, 0);
    expect(score.explanation, contains('No items selected'));
  });

  test('occasionMatchScore is 100 when every item suits the occasion', () {
    final items = [
      _item(color: const Color(0xFF000000), occasions: const [Occasion.interview]),
      _item(color: const Color(0xFF111111), occasions: const [Occasion.interview]),
    ];
    final score = calculator.calculate(items: items, occasion: Occasion.interview);
    expect(score.occasionMatchScore, 100);
  });

  test('occasionMatchScore is 40 when no items suit the occasion', () {
    final items = [
      _item(color: const Color(0xFF000000), occasions: const [Occasion.party]),
    ];
    final score = calculator.calculate(items: items, occasion: Occasion.interview);
    expect(score.occasionMatchScore, 40);
  });

  test('colorMatchScore reflects proximity to the skin tone palette', () {
    final navyItem = _item(color: const Color(0xFF1B2A4A)); // exact "Navy"
    final fuchsiaItem = _item(color: const Color(0xFFFF00FF)); // far from fair palette

    final navyScore = calculator.calculate(
      items: [navyItem],
      occasion: Occasion.casual,
      skinTone: SkinTone.fair,
    );
    final fuchsiaScore = calculator.calculate(
      items: [fuchsiaItem],
      occasion: Occasion.casual,
      skinTone: SkinTone.fair,
    );

    expect(navyScore.colorMatchScore, greaterThan(fuchsiaScore.colorMatchScore));
  });

  test('bodyMatchScore reflects the BodyMatchService compatibility table', () {
    final structuredItem = _item(color: const Color(0xFF000000), fit: FitType.structured);

    final athleticScore = calculator.calculate(
      items: [structuredItem],
      occasion: Occasion.casual,
      bodyType: BodyType.athletic,
    );
    final slimBodyScore = calculator.calculate(
      items: [structuredItem],
      occasion: Occasion.casual,
      bodyType: BodyType.slim,
    );

    // Structured fit scores higher for athletic builds than slim builds
    // per BodyMatchService's table.
    expect(athleticScore.bodyMatchScore, greaterThan(slimBodyScore.bodyMatchScore));
  });

  test(
      'professionalScore is high for office/interview/formal-tagged items '
      'regardless of occasion', () {
    final formalItem = _item(
      color: const Color(0xFF000000),
      occasions: const [Occasion.office, Occasion.interview],
    );
    // Requesting a "party" recommendation, but the item is still tagged
    // professional — professionalScore should reflect that independently
    // of occasionMatchScore.
    final score = calculator.calculate(items: [formalItem], occasion: Occasion.party);
    expect(score.professionalScore, 100);
    expect(score.occasionMatchScore, 40); // doesn't suit "party"
  });

  test('styleScore is penalized when many distinct colors are used', () {
    final coherent = [
      _item(color: const Color(0xFF1B2A4A)),
      _item(color: const Color(0xFF1A1A1A), layer: ClothingLayer.pant),
    ];
    final chaotic = [
      _item(color: const Color(0xFF1B2A4A)),
      _item(color: const Color(0xFFFF00FF), layer: ClothingLayer.pant),
      _item(color: const Color(0xFFFFBF00), layer: ClothingLayer.jacket),
      _item(color: const Color(0xFF008080), layer: ClothingLayer.hat),
      _item(color: const Color(0xFFE1AD01), layer: ClothingLayer.shoes),
    ];

    final coherentScore = calculator.calculate(items: coherent, occasion: Occasion.casual);
    final chaoticScore = calculator.calculate(items: chaotic, occasion: Occasion.casual);

    expect(coherentScore.styleScore, greaterThanOrEqualTo(chaoticScore.styleScore));
  });

  test('all scores stay within 0-100', () {
    final items = [
      _item(color: const Color(0xFFFF00FF), occasions: const [Occasion.party]),
    ];
    final score = calculator.calculate(
      items: items,
      occasion: Occasion.interview,
      skinTone: SkinTone.dark,
      bodyType: BodyType.broad,
    );

    for (final value in [
      score.overallScore,
      score.colorMatchScore,
      score.occasionMatchScore,
      score.bodyMatchScore,
      score.professionalScore,
      score.styleScore,
    ]) {
      expect(value, inInclusiveRange(0, 100));
    }
  });
}
