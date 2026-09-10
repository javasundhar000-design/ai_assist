import 'dart:math';
import '../../../models/room_and_design_models.dart';
import '../models/placed_furniture.dart';

/// A single space-validation finding (Sec. 20). All issues are advisory
/// warnings, not hard blocks — placement is never prevented, matching
/// the "SPACE WARNING" framing in Sec. 20's own example.
enum SpaceIssueSeverity { warning, info }

enum SpaceIssueType {
  tooLargeForRoom,
  collision,
  walkingSpace,
  doorWindowReminder,
}

class SpaceValidationIssue {
  final SpaceIssueType type;
  final SpaceIssueSeverity severity;
  final String title;
  final String message;
  final List<String> involvedInstanceIds;

  const SpaceValidationIssue({
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.involvedInstanceIds = const [],
  });
}

/// Internal 2D point in the AR ground plane (x, z — AR "up" is y).
typedef _Pt = (double x, double z);

/// Space validation engine (Sec. 20).
///
/// HONESTY NOTE — read before extending this: only two of the checks
/// here are genuine, computed geometry. Room-boundary and door/window
/// clearance checking as described in Sec. 20 would require the room's
/// physical perimeter and openings to be known in the *same* coordinate
/// space as placed furniture. Placed furniture lives in AR-world meters
/// (relative to wherever the AR session happened to start — Phase 12).
/// Detected doors/windows (Phase 8) live in normalized 2D *photo*
/// coordinates (0.0-1.0 within a single scan image). Nothing in this
/// pipeline currently calibrates one coordinate space onto the other —
/// that would need an explicit step (e.g. the user tapping "this is the
/// door" during the AR session to anchor it in AR space), which doesn't
/// exist yet. Rather than fabricate a plausible-looking but meaningless
/// number, door/window checking here is a plain reminder, not computed
/// clearance.
class SpaceValidationService {
  SpaceValidationService._();

  /// Beyond this fraction of the room's estimated floor area occupied by
  /// furniture footprints, warn that there may not be enough room left
  /// to walk through. A heuristic, not a real pathfinding/clearance
  /// analysis — it only looks at total area, not layout.
  static const double _maxOccupiedFraction = 0.55;

  /// Runs every available check and returns all current issues.
  static List<SpaceValidationIssue> validateAll({
    required List<PlacedFurniture> placed,
    required RoomModel? room,
    required List<DetectedObjectModel> detectedObjects,
  }) {
    final issues = <SpaceValidationIssue>[];

    if (room != null) {
      issues.addAll(_checkItemsFitRoom(placed, room));
    }
    issues.addAll(_checkCollisions(placed));
    if (room != null) {
      final walking = _checkWalkingSpace(placed, room);
      if (walking != null) issues.add(walking);
    }
    final doorWindow = _doorWindowReminder(detectedObjects);
    if (doorWindow != null) issues.add(doorWindow);

    return issues;
  }

  // --- Real check: does each item's footprint fit the room at all? ---
  // Matches Sec. 20's own example format almost exactly.
  static List<SpaceValidationIssue> _checkItemsFitRoom(
    List<PlacedFurniture> placed,
    RoomModel room,
  ) {
    if (room.width <= 0 || room.length <= 0) return const [];
    // Conservative stand-in for "available width": the room's smaller
    // dimension. We don't know which wall an item is against, so this
    // is deliberately cautious rather than precise.
    final availableWidth = min(room.width, room.length);

    final issues = <SpaceValidationIssue>[];
    for (final item in placed) {
      final footprintWidth =
          (item.furniture.width / 100.0) * item.scale; // cm -> m
      final footprintDepth = (item.furniture.depth / 100.0) * item.scale;
      final largest = max(footprintWidth, footprintDepth);
      if (largest > availableWidth) {
        issues.add(SpaceValidationIssue(
          type: SpaceIssueType.tooLargeForRoom,
          severity: SpaceIssueSeverity.warning,
          title: 'May not fit this room',
          message: 'The ${item.furniture.name} is about '
              '${largest.toStringAsFixed(1)} m, larger than the '
              '${availableWidth.toStringAsFixed(1)} m available in this '
              'room. Consider a smaller item.',
          involvedInstanceIds: [item.instanceId],
        ));
      }
    }
    return issues;
  }

  // --- Real check: 2D oriented-bounding-box collision in AR space ---
  static List<SpaceValidationIssue> _checkCollisions(
    List<PlacedFurniture> placed,
  ) {
    final issues = <SpaceValidationIssue>[];
    for (var i = 0; i < placed.length; i++) {
      for (var j = i + 1; j < placed.length; j++) {
        if (_obbOverlap(placed[i], placed[j])) {
          issues.add(SpaceValidationIssue(
            type: SpaceIssueType.collision,
            severity: SpaceIssueSeverity.warning,
            title: 'Furniture overlapping',
            message:
                '${placed[i].furniture.name} and ${placed[j].furniture.name} '
                'appear to overlap. Try moving one of them apart.',
            involvedInstanceIds: [
              placed[i].instanceId,
              placed[j].instanceId,
            ],
          ));
        }
      }
    }
    return issues;
  }

  // --- Heuristic: total footprint area vs room floor area ---
  static SpaceValidationIssue? _checkWalkingSpace(
    List<PlacedFurniture> placed,
    RoomModel room,
  ) {
    if (room.floorArea <= 0 || placed.isEmpty) return null;
    final occupied = placed.fold<double>(0, (sum, p) {
      final w = (p.furniture.width / 100.0) * p.scale;
      final d = (p.furniture.depth / 100.0) * p.scale;
      return sum + (w * d);
    });
    final fraction = occupied / room.floorArea;
    if (fraction > _maxOccupiedFraction) {
      return SpaceValidationIssue(
        type: SpaceIssueType.walkingSpace,
        severity: SpaceIssueSeverity.warning,
        title: 'Limited walking space',
        message: 'Placed furniture covers about '
            '${(fraction * 100).round()}% of this room\'s estimated floor '
            'area, which may not leave enough space to walk through. '
            'Consider removing or resizing an item.',
      );
    }
    return null;
  }

  // --- Reminder, not a computed check — see class doc comment ---
  static SpaceValidationIssue? _doorWindowReminder(
    List<DetectedObjectModel> detectedObjects,
  ) {
    final hasDoor = detectedObjects.any((o) => o.objectType == 'door');
    final hasWindow = detectedObjects.any((o) => o.objectType == 'window');
    if (!hasDoor && !hasWindow) return null;

    final parts = [
      if (hasDoor) 'a door',
      if (hasWindow) 'window(s)',
    ];
    return SpaceValidationIssue(
      type: SpaceIssueType.doorWindowReminder,
      severity: SpaceIssueSeverity.info,
      title: 'Check clearance manually',
      message: 'Your room scan detected ${parts.join(' and ')}. '
          'Automatic clearance checking isn\'t available yet — double-check '
          'your placed furniture doesn\'t block ${parts.length > 1 ? 'them' : 'it'}.',
    );
  }

  // --- 2D SAT (separating axis theorem) for oriented rectangles ---

  static List<_Pt> _obbCorners(PlacedFurniture p) {
    final halfW = (p.furniture.width / 100.0 * p.scale) / 2;
    final halfD = (p.furniture.depth / 100.0 * p.scale) / 2;
    final rad = p.rotationYDegrees * pi / 180.0;
    final cosA = cos(rad), sinA = sin(rad);
    final axisX = (cosA, sinA);
    final axisZ = (-sinA, cosA);

    _Pt corner(double sx, double sz) => (
          p.positionX + axisX.$1 * sx * halfW + axisZ.$1 * sz * halfD,
          p.positionZ + axisX.$2 * sx * halfW + axisZ.$2 * sz * halfD,
        );

    return [corner(1, 1), corner(-1, 1), corner(-1, -1), corner(1, -1)];
  }

  static List<_Pt> _axesFor(PlacedFurniture p) {
    final rad = p.rotationYDegrees * pi / 180.0;
    return [(cos(rad), sin(rad)), (-sin(rad), cos(rad))];
  }

  static bool _obbOverlap(PlacedFurniture a, PlacedFurniture b) {
    final cornersA = _obbCorners(a);
    final cornersB = _obbCorners(b);
    final axes = [..._axesFor(a), ..._axesFor(b)];

    for (final axis in axes) {
      final projA =
          cornersA.map((c) => c.$1 * axis.$1 + c.$2 * axis.$2).toList();
      final projB =
          cornersB.map((c) => c.$1 * axis.$1 + c.$2 * axis.$2).toList();
      final aMin = projA.reduce(min), aMax = projA.reduce(max);
      final bMin = projB.reduce(min), bMax = projB.reduce(max);
      if (aMax < bMin || bMax < aMin) {
        return false; // separating axis found -> no overlap
      }
    }
    return true; // no separating axis on any tested axis -> overlap
  }
}
