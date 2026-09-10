import '../../../app/constants/app_constants.dart';

/// Color + material palette for one interior style. Deliberately plain
/// data (not logic) so non-engineers can tune it without touching the
/// engine — this is the "keep this recommendation engine modular" ask
/// from Sec. 14.
class StylePalette {
  final List<String> colors;
  final List<String> materials;
  const StylePalette({required this.colors, required this.materials});
}

/// One furniture "slot" in a room type's default plan.
class RoomFurniturePlanItem {
  final FurnitureCategory category;
  final String label;
  final String? compactLabel; // used when floor area is small
  final String placement;
  final String rationale;

  const RoomFurniturePlanItem({
    required this.category,
    required this.label,
    this.compactLabel,
    required this.placement,
    required this.rationale,
  });
}

class StyleCatalog {
  StyleCatalog._();

  static const Map<InteriorStyle, StylePalette> _palettes = {
    InteriorStyle.modern: StylePalette(
      colors: ['White', 'Charcoal', 'Black'],
      materials: ['Metal', 'Glass', 'Lacquered Wood'],
    ),
    InteriorStyle.minimalist: StylePalette(
      colors: ['White', 'Beige', 'Light Grey'],
      materials: ['Engineered Wood', 'Matte Finishes'],
    ),
    InteriorStyle.luxury: StylePalette(
      colors: ['Gold', 'Emerald', 'Black'],
      materials: ['Velvet', 'Marble', 'Brass'],
    ),
    InteriorStyle.scandinavian: StylePalette(
      colors: ['White', 'Light Wood', 'Pale Blue'],
      materials: ['Ash Wood', 'Linen', 'Wool'],
    ),
    InteriorStyle.industrial: StylePalette(
      colors: ['Charcoal', 'Rust', 'Raw Wood'],
      materials: ['Steel', 'Reclaimed Wood', 'Concrete'],
    ),
    InteriorStyle.traditional: StylePalette(
      colors: ['Burgundy', 'Navy', 'Gold'],
      materials: ['Solid Oak', 'Leather', 'Brocade Fabric'],
    ),
    InteriorStyle.contemporary: StylePalette(
      colors: ['Grey', 'Taupe', 'Black'],
      materials: ['Mixed Metals', 'Engineered Wood', 'Glass'],
    ),
    InteriorStyle.rustic: StylePalette(
      colors: ['Terracotta', 'Warm Brown', 'Cream'],
      materials: ['Reclaimed Wood', 'Wool', 'Wrought Iron'],
    ),
  };

  static StylePalette paletteFor(InteriorStyle style) =>
      _palettes[style] ?? _palettes[InteriorStyle.contemporary]!;

  static final Map<RoomType, List<RoomFurniturePlanItem>> _plans = {
    RoomType.livingRoom: const [
      RoomFurniturePlanItem(
        category: FurnitureCategory.sofa,
        label: '3-Seater Sofa',
        compactLabel: 'Compact Loveseat',
        placement: 'Facing the room\'s main wall',
        rationale: 'Anchors the seating area and the main sightline.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.table,
        label: 'Coffee Table',
        compactLabel: 'Small Side Table',
        placement: 'Center, in front of the sofa',
        rationale: 'Keeps everyday items within reach of the seating.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.tvUnit,
        label: 'TV Console',
        placement: 'Opposite the sofa',
        rationale: 'Puts the main screen on-axis with seating.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.lamp,
        label: 'Floor Lamp',
        placement: 'Beside the sofa',
        rationale: 'Adds ambient lighting for evening use.',
      ),
    ],
    RoomType.bedroom: const [
      RoomFurniturePlanItem(
        category: FurnitureCategory.bed,
        label: 'Queen Bed',
        compactLabel: 'Full/Double Bed',
        placement: 'Against the wall opposite the door',
        rationale: 'Standard placement for the room\'s focal point.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.wardrobe,
        label: 'Wardrobe',
        placement: 'Along the longest wall',
        rationale: 'Maximizes storage without blocking circulation.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.lamp,
        label: 'Table Lamp',
        placement: 'On a nightstand beside the bed',
        rationale: 'Bedside lighting for reading.',
      ),
    ],
    RoomType.kitchen: const [
      RoomFurniturePlanItem(
        category: FurnitureCategory.cabinet,
        label: 'Storage Cabinet',
        placement: 'Along the kitchen wall',
        rationale: 'Adds storage close to the work area.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.dining,
        label: 'Breakfast Table',
        compactLabel: 'Breakfast Bar',
        placement: 'Near the window, out of the main walkway',
        rationale: 'Casual dining space close to natural light.',
      ),
    ],
    RoomType.diningRoom: const [
      RoomFurniturePlanItem(
        category: FurnitureCategory.dining,
        label: 'Dining Table',
        compactLabel: 'Compact Dining Table',
        placement: 'Center of the room',
        rationale: 'Central focal point for the room\'s primary use.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.chair,
        label: 'Dining Chairs',
        placement: 'Around the table',
        rationale: 'Seating scaled to the table.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.cabinet,
        label: 'Sideboard Cabinet',
        placement: 'Against the wall',
        rationale: 'Storage for tableware close to the table.',
      ),
    ],
    RoomType.office: const [
      RoomFurniturePlanItem(
        category: FurnitureCategory.desk,
        label: 'Office Desk',
        placement: 'Facing the window',
        rationale: 'Natural light reduces eye strain while working.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.chair,
        label: 'Office Chair',
        placement: 'At the desk',
        rationale: 'Ergonomic seating for extended work sessions.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.cabinet,
        label: 'Storage Cabinet',
        placement: 'Against the wall',
        rationale: 'Keeps documents and supplies organized.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.lamp,
        label: 'Desk Lamp',
        placement: 'On the desk',
        rationale: 'Task lighting for close work.',
      ),
    ],
    RoomType.studyRoom: const [
      RoomFurniturePlanItem(
        category: FurnitureCategory.desk,
        label: 'Study Desk',
        placement: 'Near natural light',
        rationale: 'Supports focused reading and writing.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.chair,
        label: 'Study Chair',
        placement: 'At the desk',
        rationale: 'Comfortable seating for study sessions.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.cabinet,
        label: 'Bookshelf',
        placement: 'Against the wall',
        rationale: 'Keeps books and materials within reach.',
      ),
    ],
    RoomType.hall: const [
      RoomFurniturePlanItem(
        category: FurnitureCategory.cabinet,
        label: 'Console Table',
        placement: 'Along the entry wall',
        rationale: 'A drop zone for keys and mail near the entrance.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.decoration,
        label: 'Wall Mirror',
        placement: 'Above the console',
        rationale: 'Makes the entryway feel larger and brighter.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.lamp,
        label: 'Wall Sconce',
        placement: 'Beside the mirror',
        rationale: 'Welcoming light at the entrance.',
      ),
    ],
    RoomType.other: const [
      RoomFurniturePlanItem(
        category: FurnitureCategory.sofa,
        label: 'Seating',
        compactLabel: 'Compact Seating',
        placement: 'Wherever fits best against a wall',
        rationale: 'General-purpose seating for a flexible space.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.table,
        label: 'Table',
        placement: 'Center of the room',
        rationale: 'A flexible surface for the room\'s main use.',
      ),
      RoomFurniturePlanItem(
        category: FurnitureCategory.lamp,
        label: 'Lamp',
        placement: 'In a corner',
        rationale: 'General ambient lighting.',
      ),
    ],
  };

  static List<RoomFurniturePlanItem> planFor(RoomType roomType) =>
      _plans[roomType] ?? _plans[RoomType.other]!;
}
