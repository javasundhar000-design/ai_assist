import 'package:aura_stylist_ai/features/recommendation/domain/services/recommendation_engine.dart';
import 'package:aura_stylist_ai/features/tryon/data/local/demo_clothing_catalog.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/clothing_layer.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/occasion.dart';
import 'package:aura_stylist_ai/features/vision/domain/entities/body_metrics.dart';
import 'package:aura_stylist_ai/features/vision/domain/entities/skin_tone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = RecommendationEngine();

  test('picks one item per layer present in the catalog', () {
    final recommendation = engine.recommend(
      catalog: demoClothingCatalog,
      occasion: Occasion.interview,
    );

    final catalogLayers = demoClothingCatalog.map((i) => i.layer).toSet();
    expect(recommendation.items.keys.toSet(), catalogLayers);
  });

  test(
      'prefers the white shirt over navy for a wedding '
      '(navy is not tagged wedding, white is)', () {
    final recommendation = engine.recommend(
      catalog: demoClothingCatalog,
      occasion: Occasion.wedding,
    );
    expect(recommendation.items[ClothingLayer.shirt]?.id, 'shirt-white');
  });

  test('picks the black jacket for an interview', () {
    final recommendation = engine.recommend(
      catalog: demoClothingCatalog,
      occasion: Occasion.interview,
    );
    expect(recommendation.items[ClothingLayer.jacket]?.id, 'jacket-black');
  });

  test('matchingColors reflects the given skin tone', () {
    final recommendation = engine.recommend(
      catalog: demoClothingCatalog,
      occasion: Occasion.casual,
      skinTone: SkinTone.olive,
    );
    expect(recommendation.matchingColors, SkinTone.olive.recommendedColors);
  });

  test('matchingColors is empty with no skin tone provided', () {
    final recommendation = engine.recommend(
      catalog: demoClothingCatalog,
      occasion: Occasion.casual,
    );
    expect(recommendation.matchingColors, isEmpty);
  });

  test('produces style tips and a fashion score', () {
    final recommendation = engine.recommend(
      catalog: demoClothingCatalog,
      occasion: Occasion.office,
      skinTone: SkinTone.medium,
      bodyType: BodyType.athletic,
    );
    expect(recommendation.styleTips, isNotEmpty);
    expect(recommendation.fashionScore.overallScore, greaterThan(0));
  });

  test('handles an empty catalog gracefully', () {
    final recommendation = engine.recommend(catalog: const [], occasion: Occasion.casual);
    expect(recommendation.items, isEmpty);
    expect(recommendation.fashionScore.overallScore, 0);
  });
}
