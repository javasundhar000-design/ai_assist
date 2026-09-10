import 'package:aura_stylist_ai/features/tryon/domain/entities/clothing_layer.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/occasion.dart';
import 'package:aura_stylist_ai/features/wardrobe/domain/entities/saved_outfit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SavedOutfit.toMap / fromMap round-trip', () {
    test('preserves every field, including layer keys and occasion', () {
      final outfit = SavedOutfit(
        id: 'outfit-1',
        name: 'Interview Look',
        itemIdsByLayer: const {
          ClothingLayer.shirt: 'shirt-navy',
          ClothingLayer.pant: 'pant-denim',
        },
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        occasion: Occasion.interview,
        fashionScore: 82,
        isFavorite: true,
      );

      final roundTripped = SavedOutfit.fromMap(outfit.id, outfit.toMap());

      expect(roundTripped, outfit);
    });

    test('missing/corrupt fields fall back to safe defaults', () {
      final restored = SavedOutfit.fromMap('outfit-2', const {});

      expect(restored.name, 'Saved Look');
      expect(restored.itemIdsByLayer, isEmpty);
      expect(restored.occasion, isNull);
      expect(restored.fashionScore, isNull);
      expect(restored.isFavorite, isFalse);
    });

    test('an unrecognized layer name in stored data is dropped, not thrown', () {
      final restored = SavedOutfit.fromMap('outfit-3', {
        'name': 'Test',
        'itemIdsByLayer': {'shirt': 'shirt-navy', 'not_a_real_layer': 'xyz'},
        'createdAt': 1700000000000,
      });

      expect(restored.itemIdsByLayer, {ClothingLayer.shirt: 'shirt-navy'});
    });
  });

  group('SavedOutfit.copyWith', () {
    test('toggling isFavorite leaves every other field untouched', () {
      final outfit = SavedOutfit(
        id: 'outfit-1',
        name: 'Casual Friday',
        itemIdsByLayer: const {ClothingLayer.shirt: 'shirt-navy'},
        createdAt: DateTime(2026, 1, 1),
        isFavorite: false,
      );

      final favorited = outfit.copyWith(isFavorite: true);

      expect(favorited.isFavorite, isTrue);
      expect(favorited.id, outfit.id);
      expect(favorited.name, outfit.name);
      expect(favorited.itemIdsByLayer, outfit.itemIdsByLayer);
      expect(favorited.createdAt, outfit.createdAt);
    });
  });
}
