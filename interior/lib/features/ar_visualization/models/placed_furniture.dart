import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import '../../../models/room_and_design_models.dart';

/// One piece of furniture currently placed in the AR scene.
///
/// SIMPLIFICATION (documented deliberately): rotation is yaw-only
/// (rotation around the vertical Y axis) and scale is uniform — a
/// reasonable simplification for furniture standing on a floor plane,
/// and one that sidesteps decoding uncertain native gesture-rotation
/// callbacks (see ar_session_service.dart). This still maps cleanly
/// onto the full rotationX/Y/Z + scaleX/Y/Z schema (Sec. 24) when
/// saving — X/Z rotation and non-uniform scale are simply left at
/// their defaults (0 and 1).
class PlacedFurniture {
  final String instanceId;
  final FurnitureModel furniture;
  final ARNode node;
  final ARPlaneAnchor anchor;

  double positionX;
  double positionY;
  double positionZ;
  double rotationYDegrees;
  double scale;

  PlacedFurniture({
    required this.instanceId,
    required this.furniture,
    required this.node,
    required this.anchor,
    required this.positionX,
    required this.positionY,
    required this.positionZ,
    this.rotationYDegrees = 0,
    this.scale = 1,
  });

  /// Converts to the persisted schema (Sec. 21, 24) for Save Design.
  DesignFurnitureInstance toDesignFurnitureInstance() {
    return DesignFurnitureInstance(
      instanceId: instanceId,
      furnitureId: furniture.id,
      positionX: positionX,
      positionY: positionY,
      positionZ: positionZ,
      rotationX: 0,
      rotationY: rotationYDegrees,
      rotationZ: 0,
      scaleX: scale,
      scaleY: scale,
      scaleZ: scale,
    );
  }
}
