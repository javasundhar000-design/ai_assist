import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/constants/app_constants.dart';
import '../../../models/room_and_design_models.dart';
import '../../authentication/providers/auth_provider.dart';
import '../repositories/room_analysis_repository.dart';
import '../services/room_vision_service.dart';

final roomVisionServiceProvider = Provider<RoomVisionService>((ref) {
  return RoomVisionService();
});

final roomAnalysisRepositoryProvider = Provider<RoomAnalysisRepository>((ref) {
  return RoomAnalysisRepository(ref.watch(realtimeDatabaseServiceProvider));
});

/// Live view of a room's stored dimensions/floor area — reflects real
/// values the moment AR-based measurement (Phase 12) overwrites the
/// current heuristic estimate.
final roomStreamProvider =
    StreamProvider.family<RoomModel?, String>((ref, roomId) {
  final db = ref.watch(realtimeDatabaseServiceProvider);
  return db.watch('${AppConstants.dbRooms}/$roomId').map((event) {
    final value = event.snapshot.value;
    if (value == null) return null;
    return RoomModel.fromMap(roomId, value as Map<dynamic, dynamic>);
  });
});

/// Live view of a room's detected objects.
final detectedObjectsStreamProvider =
    StreamProvider.family<List<DetectedObjectModel>, String>((ref, roomId) {
  final db = ref.watch(realtimeDatabaseServiceProvider);
  return db.watch('${AppConstants.dbDetectedObjects}/$roomId').map((event) {
    final value = event.snapshot.value;
    if (value == null) return <DetectedObjectModel>[];
    final map = Map<dynamic, dynamic>.from(value as Map);
    return map.entries
        .map((e) =>
            DetectedObjectModel.fromMap(e.key as String, e.value as Map))
        .toList();
  });
});
