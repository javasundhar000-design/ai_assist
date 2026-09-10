import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../../../core/errors/app_exception.dart';
import '../../../models/room_and_design_models.dart';
import '../models/placed_furniture.dart';
import '../services/ar_session_service.dart';
import '../services/space_validation_service.dart';

final arSessionServiceProvider = Provider.autoDispose<ArSessionService>((ref) {
  final service = ArSessionService();
  ref.onDispose(service.dispose);
  return service;
});

extension FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class ArVisualizationState {
  final List<PlacedFurniture> placed;
  final String? selectedInstanceId;
  final FurnitureModel? pendingFurniture; // awaiting a tap-to-place
  final bool sessionReady;
  final String? error;
  final RoomModel? room;
  final List<DetectedObjectModel> detectedObjects;
  final List<SpaceValidationIssue> issues;
  // Edit-flow queue (Phase 14 "Continue in AR"): items still waiting to
  // be re-placed, and which design they came from (for the banner).
  final List<FurnitureModel> editQueue;
  final int editQueueIndex;
  final String? editingDesignName;

  const ArVisualizationState({
    this.placed = const [],
    this.selectedInstanceId,
    this.pendingFurniture,
    this.sessionReady = false,
    this.error,
    this.room,
    this.detectedObjects = const [],
    this.issues = const [],
    this.editQueue = const [],
    this.editQueueIndex = 0,
    this.editingDesignName,
  });

  bool get hasEditQueue => editQueue.isNotEmpty && editQueueIndex < editQueue.length;
  int get editQueueRemaining =>
      hasEditQueue ? editQueue.length - editQueueIndex : 0;

  PlacedFurniture? get selected {
    if (selectedInstanceId == null) return null;
    return placed.where((p) => p.instanceId == selectedInstanceId).firstOrNull;
  }

  ArVisualizationState copyWith({
    List<PlacedFurniture>? placed,
    String? selectedInstanceId,
    bool clearSelection = false,
    FurnitureModel? pendingFurniture,
    bool clearPending = false,
    bool? sessionReady,
    String? error,
    RoomModel? room,
    List<DetectedObjectModel>? detectedObjects,
    List<SpaceValidationIssue>? issues,
    List<FurnitureModel>? editQueue,
    int? editQueueIndex,
    String? editingDesignName,
  }) {
    return ArVisualizationState(
      placed: placed ?? this.placed,
      selectedInstanceId:
          clearSelection ? null : (selectedInstanceId ?? this.selectedInstanceId),
      pendingFurniture:
          clearPending ? null : (pendingFurniture ?? this.pendingFurniture),
      sessionReady: sessionReady ?? this.sessionReady,
      error: error,
      room: room ?? this.room,
      detectedObjects: detectedObjects ?? this.detectedObjects,
      issues: issues ?? this.issues,
      editQueue: editQueue ?? this.editQueue,
      editQueueIndex: editQueueIndex ?? this.editQueueIndex,
      editingDesignName: editingDesignName ?? this.editingDesignName,
    );
  }
}

class ArVisualizationController extends StateNotifier<ArVisualizationState> {
  final ArSessionService _service;
  final _uuid = const Uuid();

  ArVisualizationController(this._service) : super(const ArVisualizationState());

  Future<void> onViewCreated({
    required ARSessionManager sessionManager,
    required ARObjectManager objectManager,
    required ARAnchorManager anchorManager,
    required ARLocationManager locationManager,
  }) async {
    try {
      await _service.attach(
        sessionManager: sessionManager,
        objectManager: objectManager,
        anchorManager: anchorManager,
        locationManager: locationManager,
        onNodeMoved: _handleNodeMoved,
        onNodeSelected: _handleNodeSelected,
        onPlaneOrPointTap: _handlePlaneTap,
      );
      state = state.copyWith(sessionReady: true);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  void _handleNodeSelected(String? nodeName) {
    final match = nodeName == null
        ? null
        : state.placed.where((p) => p.node.name == nodeName).map((p) => p.instanceId).firstOrNull;
    state = state.copyWith(selectedInstanceId: match, clearSelection: match == null);
  }

  void _handleNodeMoved(String nodeName, vm.Matrix4 newTransform) {
    final translation = newTransform.getTranslation();
    final updated = state.placed.map((p) {
      if (p.node.name != nodeName) return p;
      p.positionX = translation.x;
      p.positionY = translation.y;
      p.positionZ = translation.z;
      return p;
    }).toList();
    state = state.copyWith(placed: updated);
    _revalidate();
  }

  /// Handles a tap on a detected plane. If the user has picked a
  /// furniture item from the picker (pendingFurniture), this is the
  /// "tap to place" moment; otherwise the tap is ignored (Sec. 18 flow:
  /// select furniture *then* tap to place, not the other way around).
  Future<void> _handlePlaneTap(List<ARHitTestResult> hits) async {
    final furniture = state.pendingFurniture;
    if (furniture == null || hits.isEmpty) return;
    final planeHit = hits
        .where((h) => h.type == ARHitTestResultType.plane)
        .firstOrNull;
    if (planeHit == null) {
      // Sec. 29: "AR plane not detected" — surfaced, not silently ignored.
      state = state.copyWith(
        error: 'No surface detected there yet. Move your phone slowly '
            'over the floor and try again.',
      );
      return;
    }
    await placeFurniture(furniture: furniture, hitTestResult: planeHit);
    state = state.copyWith(clearPending: true);
    _advanceEditQueueIfActive();
  }

  void setPendingFurniture(FurnitureModel furniture) {
    state = state.copyWith(pendingFurniture: furniture);
  }

  void cancelPendingFurniture() {
    state = state.copyWith(clearPending: true);
  }

  /// Starts (or replaces) the edit-flow requeue (Phase 14 "Continue in
  /// AR" / Edit). Positions are NOT restored — see the doc comment on
  /// [ArVisualizationScreen]'s edit-queue handling for why — this only
  /// queues the same catalog items for re-placement one at a time.
  void startEditQueue(String designName, List<FurnitureModel> items) {
    if (items.isEmpty) return;
    state = state.copyWith(
      editQueue: items,
      editQueueIndex: 0,
      editingDesignName: designName,
      pendingFurniture: items.first,
    );
  }

  void _advanceEditQueueIfActive() {
    if (!state.hasEditQueue) return;
    final nextIndex = state.editQueueIndex + 1;
    if (nextIndex < state.editQueue.length) {
      state = state.copyWith(
        editQueueIndex: nextIndex,
        pendingFurniture: state.editQueue[nextIndex],
        clearPending: false,
      );
    } else {
      // Queue finished — clear it, leave pendingFurniture as-is (none,
      // since it was just placed) so the user returns to free placement.
      state = state.copyWith(editQueueIndex: nextIndex, editQueue: const []);
    }
  }

  Future<void> placeFurniture({
    required FurnitureModel furniture,
    required ARHitTestResult hitTestResult,
  }) async {
    try {
      final result = await _service.placeFurniture(
        furniture: furniture,
        hitTestResult: hitTestResult,
      );
      final translation = hitTestResult.worldTransform.getTranslation();
      final placed = PlacedFurniture(
        instanceId: _uuid.v4(),
        furniture: furniture,
        node: result.node,
        anchor: result.anchor,
        positionX: translation.x,
        positionY: translation.y,
        positionZ: translation.z,
      );
      state = state.copyWith(placed: [...state.placed, placed]);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
    }
    _revalidate();
  }

  void select(String? instanceId) {
    state = state.copyWith(selectedInstanceId: instanceId, clearSelection: instanceId == null);
  }

  Future<void> deleteSelected() async {
    final selected = state.selected;
    if (selected == null) return;
    await _service.removeFurniture(node: selected.node, anchor: selected.anchor);
    state = state.copyWith(
      placed: state.placed.where((p) => p.instanceId != selected.instanceId).toList(),
      clearSelection: true,
    );
    _revalidate();
  }

  Future<void> rotateSelected(double deltaDegrees) async {
    final selected = state.selected;
    if (selected == null) return;
    final newRotation = selected.rotationYDegrees + deltaDegrees;
    try {
      final newNode = await _service.recreateWithTransform(
        oldNode: selected.node,
        anchor: selected.anchor,
        furniture: selected.furniture,
        scale: selected.scale,
        rotationYDegrees: newRotation,
      );
      _replaceNode(selected.instanceId, newNode, rotationYDegrees: newRotation);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> scaleSelected(double factor) async {
    final selected = state.selected;
    if (selected == null) return;
    final newScale = (selected.scale * factor).clamp(0.3, 3.0);
    try {
      final newNode = await _service.recreateWithTransform(
        oldNode: selected.node,
        anchor: selected.anchor,
        furniture: selected.furniture,
        scale: newScale,
        rotationYDegrees: selected.rotationYDegrees,
      );
      _replaceNode(selected.instanceId, newNode, scale: newScale);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> replaceSelected(FurnitureModel newFurniture) async {
    final selected = state.selected;
    if (selected == null) return;
    try {
      final newNode = await _service.recreateWithTransform(
        oldNode: selected.node,
        anchor: selected.anchor,
        furniture: newFurniture,
        scale: selected.scale,
        rotationYDegrees: selected.rotationYDegrees,
      );
      final updated = state.placed.map((p) {
        if (p.instanceId != selected.instanceId) return p;
        return PlacedFurniture(
          instanceId: p.instanceId,
          furniture: newFurniture,
          node: newNode,
          anchor: p.anchor,
          positionX: p.positionX,
          positionY: p.positionY,
          positionZ: p.positionZ,
          rotationYDegrees: p.rotationYDegrees,
          scale: p.scale,
        );
      }).toList();
      state = state.copyWith(placed: updated);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
    }
    _revalidate();
  }

  void _replaceNode(
    String instanceId,
    ARNode newNode, {
    double? rotationYDegrees,
    double? scale,
  }) {
    final updated = state.placed.map((p) {
      if (p.instanceId != instanceId) return p;
      return PlacedFurniture(
        instanceId: p.instanceId,
        furniture: p.furniture,
        node: newNode,
        anchor: p.anchor,
        positionX: p.positionX,
        positionY: p.positionY,
        positionZ: p.positionZ,
        rotationYDegrees: rotationYDegrees ?? p.rotationYDegrees,
        scale: scale ?? p.scale,
      );
    }).toList();
    state = state.copyWith(placed: updated);
    _revalidate();
  }

  void dismissError() => state = state.copyWith(error: null);

  /// Called from the screen once the room/detected-objects streams
  /// (Phase 8) have data, so validation has real room dimensions to
  /// check against.
  void setRoomContext(RoomModel room) {
    state = state.copyWith(room: room);
    _revalidate();
  }

  void setDetectedObjects(List<DetectedObjectModel> objects) {
    state = state.copyWith(detectedObjects: objects);
    _revalidate();
  }

  void _revalidate() {
    final issues = SpaceValidationService.validateAll(
      placed: state.placed,
      room: state.room,
      detectedObjects: state.detectedObjects,
    );
    state = state.copyWith(issues: issues);
  }
}

final arVisualizationControllerProvider = StateNotifierProvider.autoDispose<
    ArVisualizationController, ArVisualizationState>((ref) {
  return ArVisualizationController(ref.watch(arSessionServiceProvider));
});
