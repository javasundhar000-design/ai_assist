import 'dart:math';
import '../../../app/constants/app_constants.dart';
import '../../../models/room_and_design_models.dart';
import 'design_comparison_repository_deps.dart';

/// Everything needed to render one side of a comparison (Sec. 23).
class DesignComparisonBundle {
  final DesignModel design;
  final List<DesignFurnitureInstance> instances;
  final List<FurnitureModel> matchedFurniture; // aligned with instances
  final RoomModel? room;

  const DesignComparisonBundle({
    required this.design,
    required this.instances,
    required this.matchedFurniture,
    required this.room,
  });

  List<String> get furnitureNames =>
      matchedFurniture.map((f) => f.name).toList();

  List<String> get colors => matchedFurniture
      .map((f) => f.color)
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList();

  List<String> get materials => matchedFurniture
      .map((f) => f.material)
      .where((m) => m.isNotEmpty)
      .toSet()
      .toList();

  /// Genuine geometry from the saved AR positions: the bounding-box
  /// footprint of all placed items, in meters. Not a fabricated
  /// description — this is computed from real positionX/Z data.
  String get layoutSummary {
    if (instances.isEmpty) return 'No furniture placed';
    if (instances.length == 1) return 'Single item placed';
    final xs = instances.map((i) => i.positionX);
    final zs = instances.map((i) => i.positionZ);
    final spanX = xs.reduce(max) - xs.reduce(min);
    final spanZ = zs.reduce(max) - zs.reduce(min);
    return 'Furniture spans about ${spanX.toStringAsFixed(1)} × '
        '${spanZ.toStringAsFixed(1)} m';
  }

  /// Fraction of the room's estimated floor area covered by furniture
  /// footprints — same computation approach as Phase 13's walking-space
  /// heuristic, applied statically to saved data instead of a live AR
  /// session. Null when room floor area isn't known.
  double? get spaceUsageFraction {
    if (room == null || room!.floorArea <= 0) return null;
    var occupied = 0.0;
    final count = min(instances.length, matchedFurniture.length);
    for (var i = 0; i < count; i++) {
      final f = matchedFurniture[i];
      final w = (f.width / 100.0) * instances[i].scaleX;
      final d = (f.depth / 100.0) * instances[i].scaleZ;
      occupied += w * d;
    }
    return occupied / room!.floorArea;
  }
}

/// Loads a full comparison bundle for one designId. Kept as a plain
/// async function (not a Riverpod provider) since it's a one-shot fetch
/// used from a FutureBuilder, matching the pattern already used by
/// Design Details (Phase 14).
Future<DesignComparisonBundle> loadDesignComparisonBundle({
  required DesignComparisonDeps deps,
  required String designId,
}) async {
  final design = await deps.designRepo.getDesign(designId);
  if (design == null) {
    throw StateError('Design not found: $designId');
  }
  final instances = await deps.designRepo.getDesignFurniture(designId);

  final matched = <FurnitureModel>[];
  final matchedInstances = <DesignFurnitureInstance>[];
  for (final instance in instances) {
    final item = await deps.furnitureRepo.getById(instance.furnitureId);
    if (item != null) {
      matched.add(item);
      matchedInstances.add(instance);
    }
  }

  final roomSnap =
      await deps.db.readOnce('${AppConstants.dbRooms}/${design.roomId}');
  final room = roomSnap.exists && roomSnap.value != null
      ? RoomModel.fromMap(
          design.roomId, roomSnap.value as Map<dynamic, dynamic>)
      : null;

  return DesignComparisonBundle(
    design: design,
    instances: matchedInstances,
    matchedFurniture: matched,
    room: room,
  );
}
