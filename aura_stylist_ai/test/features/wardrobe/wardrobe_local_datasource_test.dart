import 'package:aura_stylist_ai/features/tryon/domain/entities/clothing_layer.dart';
import 'package:aura_stylist_ai/features/wardrobe/data/datasources/wardrobe_local_datasource.dart';
import 'package:aura_stylist_ai/features/wardrobe/domain/entities/saved_outfit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WardrobeLocalDataSource dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    dataSource = WardrobeLocalDataSource(prefs);
  });

  test('readAll returns empty list when nothing has been written yet', () {
    expect(dataSource.readAll('uid-1'), isEmpty);
  });

  test('writeAll then readAll round-trips outfits for a given uid', () async {
    final outfits = [
      SavedOutfit(
        id: 'outfit-1',
        name: 'Look A',
        itemIdsByLayer: const {ClothingLayer.shirt: 'shirt-navy'},
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        isFavorite: true,
      ),
    ];

    await dataSource.writeAll('uid-1', outfits);
    final restored = dataSource.readAll('uid-1');

    expect(restored, outfits);
  });

  test('data for different uids is stored separately', () async {
    await dataSource.writeAll('uid-1', [
      SavedOutfit(
        id: 'a',
        name: 'A',
        itemIdsByLayer: const {},
        createdAt: DateTime.now(),
      ),
    ]);

    expect(dataSource.readAll('uid-2'), isEmpty);
    expect(dataSource.readAll('uid-1'), hasLength(1));
  });
}
