// ============================================================================
// VERIFY AGAINST YOUR RESOLVED PACKAGE VERSION BEFORE RELYING ON THIS FILE.
//
// This was written against ar_flutter_plugin's documented/example API as of
// its ~0.7.x line, without the ability to run `flutter pub get` or inspect
// the actual resolved package source in this sandbox (no pub.dev network
// access here, and AR fundamentally requires a physical ARCore/ARKit device
// to test at all — there is no headless or simulator path). Treat the
// method names below (onInitialize, onPlaneOrPointTap, addNode, addAnchor,
// removeNode, removeAnchor, onPanEnd) as a best-effort, carefully-reasoned
// mapping to the plugin's public API, not a verified one. If
// `flutter pub get` resolves a version with different signatures, this is
// the only file that should need changes — nothing outside
// ar_visualization/ imports ar_flutter_plugin directly.
// ============================================================================

import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../../../core/errors/app_exception.dart';
import '../../../models/room_and_design_models.dart';

/// Everything this app needs from the AR plugin, behind a small surface
/// so the rest of the feature never touches ar_flutter_plugin types
/// directly (Sec. 4/5 architecture: keep third-party integrations
/// confined to one layer).
class ArSessionService {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  ARAnchorManager? _anchorManager;

  bool get isReady => _sessionManager != null && _objectManager != null;

  /// Called from the ARView's onARViewCreated callback.
  Future<void> attach({
    required ARSessionManager sessionManager,
    required ARObjectManager objectManager,
    required ARAnchorManager anchorManager,
    required ARLocationManager locationManager,
    required void Function(String nodeName, vm.Matrix4 newTransform)
        onNodeMoved,
    required void Function(String? nodeName) onNodeSelected,
    required void Function(List<ARHitTestResult> hits) onPlaneOrPointTap,
  }) async {
    _sessionManager = sessionManager;
    _objectManager = objectManager;
    _anchorManager = anchorManager;

    try {
      await _sessionManager!.onInitialize(
        showFeaturePoints: false,
        showPlanes: true,
        showWorldOrigin: false,
        handleTaps: true,
        handlePans: true,
        // Rotation is done via toolbar buttons, not a native gesture —
        // see PlacedFurniture's doc comment for why.
        handleRotation: false,
      );
      await _objectManager!.onInitialize();
    } catch (e) {
      throw const ArException(
        'AR could not start on this device. It may not support AR, or '
        'Google Play Services for AR / ARKit may be unavailable.',
      );
    }

    // Fires when the user drags a placed node and releases — used to
    // persist its new position (Sec. 18 "Move: Drag furniture").
    _sessionManager!.onPanEnd = (nodeName, newTransform) {
      onNodeMoved(nodeName, newTransform);
    };

    // Fires when the user taps a placed node — used to select it for the
    // manipulation toolbar (rotate/scale/delete/replace).
    _objectManager!.onNodeTap = (nodeNames) {
      onNodeSelected(nodeNames.isNotEmpty ? nodeNames.first : null);
    };

    // Fires when the user taps a detected plane/feature point — this is
    // the "tap to place" moment (Sec. 18: "Detect horizontal plane ->
    // ... -> Place furniture").
    _sessionManager!.onPlaneOrPointTap = onPlaneOrPointTap;
  }

  /// Places a new node for [furniture] at the given hit-test result
  /// (Sec. 18: "Detect horizontal plane -> Create anchor -> Load 3D
  /// model -> Place furniture"). Returns the created node + anchor, or
  /// throws if placement failed.
  Future<({ARNode node, ARPlaneAnchor anchor})> placeFurniture({
    required FurnitureModel furniture,
    required ARHitTestResult hitTestResult,
    double scale = 1.0,
    double rotationYDegrees = 0,
  }) async {
    if (!isReady) {
      throw const ArException('AR session is not ready yet.');
    }
    if (furniture.modelUrl.isEmpty) {
      // Sec. 29: "3D model unavailable" — handled gracefully.
      throw ArException(
          '${furniture.name} doesn\'t have a 3D model to place in AR.');
    }

    final anchor = ARPlaneAnchor(transformation: hitTestResult.worldTransform);
    final didAddAnchor = await _anchorManager!.addAnchor(anchor);
    if (didAddAnchor != true) {
      throw const ArException(
          'Could not anchor furniture to that surface. Try another spot.');
    }

    final node = ARNode(
      type: NodeType.webGLB,
      uri: furniture.modelUrl,
      scale: vm.Vector3(scale, scale, scale),
      position: vm.Vector3.zero(),
      rotation: vm.Vector4(0, 1, 0, _degToRad(rotationYDegrees)),
    );
    final didAddNode =
        await _objectManager!.addNode(node, planeAnchor: anchor);
    if (didAddNode != true) {
      await _anchorManager!.removeAnchor(anchor);
      throw const ArException('Could not place that item here.');
    }

    return (node: node, anchor: anchor);
  }

  /// Removes a node and its anchor (Sec. 18: "Delete: Select object ->
  /// Delete").
  Future<void> removeFurniture({
    required ARNode node,
    required ARPlaneAnchor anchor,
  }) async {
    if (!isReady) return;
    await _objectManager!.removeNode(node);
    await _anchorManager!.removeAnchor(anchor);
  }

  /// Rotates/scales are applied by removing the current node and adding
  /// a replacement at the same anchor with new scale/rotation — chosen
  /// over trying to mutate a placed node's transform in place, since
  /// that in-place-update API isn't something this implementation could
  /// verify with confidence. Functionally equivalent from the user's
  /// perspective; each recreated node has a new internal identity but
  /// the same anchor.
  Future<ARNode> recreateWithTransform({
    required ARNode oldNode,
    required ARPlaneAnchor anchor,
    required FurnitureModel furniture,
    required double scale,
    required double rotationYDegrees,
  }) async {
    if (!isReady) {
      throw const ArException('AR session is not ready yet.');
    }
    await _objectManager!.removeNode(oldNode);
    final node = ARNode(
      type: NodeType.webGLB,
      uri: furniture.modelUrl,
      scale: vm.Vector3(scale, scale, scale),
      position: vm.Vector3.zero(),
      rotation: vm.Vector4(0, 1, 0, _degToRad(rotationYDegrees)),
    );
    final didAddNode =
        await _objectManager!.addNode(node, planeAnchor: anchor);
    if (didAddNode != true) {
      throw const ArException('Could not update that item.');
    }
    return node;
  }

  double _degToRad(double degrees) => degrees * 3.141592653589793 / 180.0;

  void dispose() {
    _sessionManager?.dispose();
    _sessionManager = null;
    _objectManager = null;
    _anchorManager = null;
  }
}
