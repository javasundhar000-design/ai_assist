import '../../../app/constants/app_constants.dart';
import '../../../firebase/realtime_database/realtime_database_service.dart';
import '../../../models/room_and_design_models.dart';
import 'package:uuid/uuid.dart';
import '../services/room_dimension_estimator.dart';

class RoomAnalysisRepository {
  final RealtimeDatabaseService _db;
  final _uuid = const Uuid();
  RoomAnalysisRepository(this._db);

  /// Writes all detections in a single multi-path update rather than one
  /// write per object, per the guidance to batch related writes.
  Future<void> saveDetectedObjects(
    String roomId,
    List<DetectedObjectModel> objects,
  ) async {
    if (objects.isEmpty) return;
    final updates = <String, dynamic>{};
    for (final obj in objects) {
      final id = _uuid.v4();
      updates[id] = obj.toMap();
    }
    await _db.update('${AppConstants.dbDetectedObjects}/$roomId', updates);
  }

  Future<void> updateRoomDimensions(
    String roomId,
    RoomDimensionEstimate estimate,
  ) async {
    await _db.update('${AppConstants.dbRooms}/$roomId', {
      'length': estimate.length,
      'width': estimate.width,
      'height': estimate.height,
      'floorArea': estimate.floorArea,
      'isEstimated': estimate.isEstimated,
    });
  }
}
