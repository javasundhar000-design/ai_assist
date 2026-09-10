/// Maps a raw ML Kit Image Labeling result (free-text label, e.g. "Couch",
/// "Chair", "Coffee table") onto the fixed vocabulary this app stores in
/// `detectedObjects.objectType` (Sec. 10/24).
///
/// ML Kit's on-device label set (~400 general-purpose labels) was not
/// designed specifically for interior design, so this mapping is a
/// best-effort approximation, not a guarantee. In particular:
///   - "Wardrobe" vs "Cupboard" vs "Cabinetry" often collapse to the same
///     ML Kit label ("Cabinetry" / "Furniture") — we map those to the
///     closest category and accept the imprecision for this prototype.
///   - "TV" vs "TV Stand" are frequently not distinguished by the model;
///     a plain "Television" label maps to `tv`, and only an explicit
///     "furniture"-adjacent label near a TV (e.g. "Shelf") would ever
///     map to `tv_stand`, so tv_stand detections will be rare.
///   - Room-scale elements (wall, ceiling, floor) are not part of ML
///     Kit's label set at all — see the comment in RoomVisionService for
///     how those are handled.
///
/// Returns null when a label doesn't confidently map to anything in our
/// taxonomy — callers should skip it rather than guessing.
String? mapLabelToObjectType(String rawLabel) {
  final label = rawLabel.toLowerCase().trim();

  const table = <String, List<String>>{
    'sofa': ['sofa', 'couch', 'loveseat'],
    'chair': ['chair', 'armchair', 'recliner', 'stool'],
    'table': ['table', 'coffee table', 'side table', 'end table'],
    'dining_table': ['dining table', 'kitchen table'],
    'bed': ['bed', 'mattress', 'bunk bed'],
    'wardrobe': ['wardrobe', 'closet'],
    'cupboard': ['cupboard', 'cabinetry', 'cabinet', 'drawer'],
    'tv': ['television', 'tv', 'monitor', 'computer monitor'],
    'tv_stand': ['tv stand', 'entertainment center'],
    'desk': ['desk', 'writing desk'],
    'lamp': ['lamp', 'lighting', 'light fixture', 'lampshade'],
    'door': ['door'],
    'window': ['window', 'window blind', 'curtain'],
  };

  for (final entry in table.entries) {
    for (final keyword in entry.value) {
      if (label == keyword || label.contains(keyword)) {
        return entry.key;
      }
    }
  }

  // Broad "there's some furniture here, we just don't know exactly what"
  // fallback — still useful for the "existing furniture present" signal
  // used by the Phase 10 recommendation engine, without overclaiming
  // precision.
  const genericFurnitureHints = ['furniture', 'shelf', 'shelving', 'plant'];
  if (genericFurnitureHints.any((h) => label.contains(h))) {
    return 'other';
  }

  return null;
}

/// Human-readable display name for a stored objectType, used in the
/// Room Analysis checklist (Sec. 11).
String displayNameForObjectType(String objectType) {
  const names = {
    'sofa': 'Sofa',
    'chair': 'Chair',
    'table': 'Table',
    'dining_table': 'Dining Table',
    'bed': 'Bed',
    'wardrobe': 'Wardrobe',
    'cupboard': 'Cupboard',
    'tv': 'TV',
    'tv_stand': 'TV Stand',
    'desk': 'Desk',
    'lamp': 'Lamp',
    'door': 'Door',
    'window': 'Window',
    'wall': 'Wall',
    'floor': 'Floor',
    'ceiling': 'Ceiling',
    'other': 'Other Furniture',
  };
  return names[objectType] ?? objectType;
}

/// Whether this objectType belongs on the "room component" side of the
/// Sec. 11 checklist vs. the "furniture" side.
bool isRoomComponent(String objectType) =>
    const {'wall', 'floor', 'ceiling', 'door', 'window'}.contains(objectType);
