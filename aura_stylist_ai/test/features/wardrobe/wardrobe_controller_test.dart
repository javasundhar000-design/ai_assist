import 'package:aura_stylist_ai/features/tryon/domain/entities/clothing_layer.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/occasion.dart';
import 'package:aura_stylist_ai/features/wardrobe/domain/entities/saved_outfit.dart';
import 'package:aura_stylist_ai/features/wardrobe/domain/entities/wardrobe_sort.dart';
import 'package:aura_stylist_ai/features/wardrobe/presentation/providers/wardrobe_controller.dart';
import 'package:aura_stylist_ai/features/wardrobe/presentation/providers/wardrobe_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_wardrobe_repository.dart';
import 'fakes/test_clothing_catalog.dart';

const _uid = 'uid-1';

void main() {
  late FakeWardrobeRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeWardrobeRepository();
    container = ProviderContainer(
      overrides: [wardrobeRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  WardrobeController controllerFor(String uid) =>
      container.read(wardrobeControllerProvider(uid).notifier);

  test('saveCurrentOutfit stores selected items by layer id and is favorited by default',
      () async {
    final controller = controllerFor(_uid);
    await pump();

    final selected = {
      ClothingLayer.shirt: testClothingCatalog[0],
      ClothingLayer.pant: testClothingCatalog[1],
    };

    final saved = await controller.saveCurrentOutfit(
      selectedItems: selected,
      occasion: Occasion.office,
      fashionScore: 77,
    );

    expect(saved.isFavorite, isTrue);
    expect(saved.itemIdsByLayer, {
      ClothingLayer.shirt: 'shirt-navy',
      ClothingLayer.pant: 'pant-denim',
    });
    expect(saved.occasion, Occasion.office);
    expect(saved.fashionScore, 77);

    await pump();
    expect(container.read(wardrobeControllerProvider(_uid)).outfits, contains(saved));
  });

  test('resolveItems maps stored ids back to real ClothingItems, dropping unknown ids',
      () async {
    final controller = controllerFor(_uid);
    final outfit = SavedOutfit(
      id: 'outfit-1',
      name: 'Test',
      itemIdsByLayer: const {
        ClothingLayer.shirt: 'shirt-navy',
        ClothingLayer.hat: 'no-such-item',
      },
      createdAt: DateTime.now(),
    );

    final resolved = controller.resolveItems(outfit, testClothingCatalog);

    expect(resolved.keys, [ClothingLayer.shirt]);
    expect(resolved[ClothingLayer.shirt]!.id, 'shirt-navy');
  });

  test('toggleFavorite flips isFavorite for the matching outfit only', () async {
    final controller = controllerFor(_uid);
    await pump();

    final a = await controller.saveCurrentOutfit(
      selectedItems: {ClothingLayer.shirt: testClothingCatalog[0]},
      name: 'A',
    );
    final b = await controller.saveCurrentOutfit(
      selectedItems: {ClothingLayer.pant: testClothingCatalog[1]},
      name: 'B',
    );
    await pump();

    await controller.toggleFavorite(a.id);
    await pump();

    final outfits = container.read(wardrobeControllerProvider(_uid)).outfits;
    expect(outfits.firstWhere((o) => o.id == a.id).isFavorite, isFalse);
    expect(outfits.firstWhere((o) => o.id == b.id).isFavorite, isTrue);
  });

  test('deleteOutfit removes it from state', () async {
    final controller = controllerFor(_uid);
    await pump();

    final outfit = await controller.saveCurrentOutfit(
      selectedItems: {ClothingLayer.shirt: testClothingCatalog[0]},
    );
    await pump();
    expect(container.read(wardrobeControllerProvider(_uid)).outfits, isNotEmpty);

    await controller.deleteOutfit(outfit.id);
    await pump();
    expect(container.read(wardrobeControllerProvider(_uid)).outfits, isEmpty);
  });

  test('visibleOutfits filters by occasion and search query', () async {
    final controller = controllerFor(_uid);
    await pump();

    await controller.saveCurrentOutfit(
      selectedItems: {ClothingLayer.shirt: testClothingCatalog[0]},
      name: 'Interview Blazer',
      occasion: Occasion.interview,
    );
    await controller.saveCurrentOutfit(
      selectedItems: {ClothingLayer.pant: testClothingCatalog[1]},
      name: 'Weekend Casual',
      occasion: Occasion.casual,
    );
    await pump();

    controller.setOccasionFilter(Occasion.casual);
    var visible = container.read(wardrobeControllerProvider(_uid)).visibleOutfits();
    expect(visible.map((o) => o.name), ['Weekend Casual']);

    controller.setOccasionFilter(null);
    controller.setSearchQuery('interview');
    visible = container.read(wardrobeControllerProvider(_uid)).visibleOutfits();
    expect(visible.map((o) => o.name), ['Interview Blazer']);
  });

  test('next()/previous() cycle through visibleOutfits and wrap around', () async {
    final controller = controllerFor(_uid);
    await pump();

    controller.setSort(WardrobeSort.oldestFirst);
    await controller.saveCurrentOutfit(
      selectedItems: {ClothingLayer.shirt: testClothingCatalog[0]},
      name: 'First',
    );
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await controller.saveCurrentOutfit(
      selectedItems: {ClothingLayer.pant: testClothingCatalog[1]},
      name: 'Second',
    );
    await pump();

    expect(controller.next()!.name, 'Second');
    expect(controller.next()!.name, 'First'); // wraps
    expect(controller.previous()!.name, 'Second');
  });

  test('next()/previous() return null when nothing is saved yet', () async {
    final controller = controllerFor(_uid);
    await pump();

    expect(controller.next(), isNull);
    expect(controller.previous(), isNull);
  });
}
