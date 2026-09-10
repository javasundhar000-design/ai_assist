import 'package:aura_stylist_ai/features/recommendation/domain/services/catalog_search_service.dart';
import 'package:aura_stylist_ai/features/tryon/data/local/demo_clothing_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = CatalogSearchService();

  test('filters by color', () {
    final results = service.filter(demoClothingCatalog, color: 'navy');
    expect(results, isNotEmpty);
    expect(results.every((item) => item.id == 'shirt-navy'), isTrue);
  });

  test('filters by category matching a layer label', () {
    final results = service.filter(demoClothingCatalog, category: 'shirt');
    expect(results.map((i) => i.id), containsAll(['shirt-navy', 'shirt-white']));
  });

  test('filters by category matching an occasion tag', () {
    final results = service.filter(demoClothingCatalog, category: 'casual');
    expect(results, isNotEmpty);
    for (final item in results) {
      expect(
        item.suitableOccasions.any((o) => o.name == 'casual'),
        isTrue,
        reason: '${item.name} should be tagged casual',
      );
    }
  });

  test('combines color and category filters', () {
    final results = service.filter(demoClothingCatalog, color: 'white', category: 'shirt');
    expect(results.map((i) => i.id), ['shirt-white']);
  });

  test('returns an empty list when nothing matches', () {
    final results = service.filter(demoClothingCatalog, color: 'chartreuse');
    expect(results, isEmpty);
  });

  test('no filters returns the full catalog', () {
    final results = service.filter(demoClothingCatalog);
    expect(results.length, demoClothingCatalog.length);
  });
}
