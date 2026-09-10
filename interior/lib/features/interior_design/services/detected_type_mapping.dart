import '../../../app/constants/app_constants.dart';

/// `detectedObjects.objectType` (Phase 8, e.g. "tv_stand", "dining_table")
/// and `FurnitureCategory` (Phase 9, e.g. `tvUnit`, `dining`) are two
/// separate, independently-evolved vocabularies — this bridges them so
/// the recommendation engine can check "does the room already have a
/// sofa?" against what Computer Vision actually detected.
FurnitureCategory? detectedTypeToCategory(String objectType) {
  const map = {
    'sofa': FurnitureCategory.sofa,
    'chair': FurnitureCategory.chair,
    'table': FurnitureCategory.table,
    'dining_table': FurnitureCategory.dining,
    'bed': FurnitureCategory.bed,
    'wardrobe': FurnitureCategory.wardrobe,
    'cupboard': FurnitureCategory.cabinet,
    'tv': FurnitureCategory.tvUnit,
    'tv_stand': FurnitureCategory.tvUnit,
    'desk': FurnitureCategory.desk,
    'lamp': FurnitureCategory.lamp,
    // 'door', 'window', 'other' intentionally unmapped — not
    // furniture-catalog categories.
  };
  return map[objectType];
}
