import '../../../app/constants/app_constants.dart';

/// Rough default dimensions per room type, in meters.
///
/// HONESTY NOTE: this is a *placeholder* heuristic based on typical room
/// sizes — it is not derived from measuring the user's actual room. A
/// single 2D photo (or several) cannot recover true metric dimensions
/// without depth data. Real, device-measured dimensions come from
/// ARCore/ARKit plane detection once the user opens AR Visualization
/// (Sec. 18, Phase 12) — at that point `isEstimated` should flip to
/// false and these values should be overwritten with anchor-derived
/// measurements. Sec. 11 explicitly requires labeling non-measured
/// values as "estimated", which this class's output always is.
class RoomDimensionEstimate {
  final double length;
  final double width;
  final double height;
  final double floorArea;
  final bool isEstimated;

  const RoomDimensionEstimate({
    required this.length,
    required this.width,
    required this.height,
    required this.floorArea,
    this.isEstimated = true,
  });
}

class RoomDimensionEstimator {
  RoomDimensionEstimator._();

  static const Map<RoomType, (double, double, double)> _typicalMeters = {
    RoomType.livingRoom: (4.5, 3.6, 2.8),
    RoomType.bedroom: (3.6, 3.3, 2.7),
    RoomType.kitchen: (3.0, 2.7, 2.7),
    RoomType.diningRoom: (3.6, 3.3, 2.7),
    RoomType.office: (3.0, 2.7, 2.7),
    RoomType.studyRoom: (2.7, 2.4, 2.7),
    RoomType.hall: (4.0, 2.0, 2.7),
    RoomType.other: (3.5, 3.0, 2.7),
  };

  static RoomDimensionEstimate estimate(RoomType roomType) {
    final (length, width, height) =
        _typicalMeters[roomType] ?? _typicalMeters[RoomType.other]!;
    final area = double.parse((length * width).toStringAsFixed(2));
    return RoomDimensionEstimate(
      length: length,
      width: width,
      height: height,
      floorArea: area,
      isEstimated: true,
    );
  }
}
