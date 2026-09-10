import 'dart:io';
import 'package:camera/camera.dart';
import '../../../app/constants/app_constants.dart';
import '../../../firebase/realtime_database/realtime_database_service.dart';
import '../../../firebase/storage/storage_service.dart';
import '../../../models/project_model.dart';
import '../../../models/room_and_design_models.dart';

class RoomScanRepository {
  final RealtimeDatabaseService _db;
  final StorageService _storage;
  RoomScanRepository({
    required RealtimeDatabaseService db,
    required StorageService storage,
  })  : _db = db,
        _storage = storage;

  /// Creates the room node (dimensions start at 0 / estimated — Phase 8's
  /// Computer Vision + Room Analysis step is what fills these in), then
  /// uploads every captured photo to Storage and records it under
  /// roomImages/{roomId}. Returns the new roomId.
  ///
  /// Reports 0.0–1.0 overall progress across all images via [onProgress].
  Future<String> confirmScan({
    required ProjectModel project,
    required List<XFile> images,
    void Function(double progress)? onProgress,
  }) async {
    if (images.isEmpty) {
      throw StateError('confirmScan called with no captured images');
    }

    final roomId = _db.pushId(AppConstants.dbRooms);

    final room = RoomModel(
      id: roomId,
      projectId: project.id,
      roomType: project.roomType,
      length: 0,
      width: 0,
      height: 0,
      floorArea: 0,
      isEstimated: true,
    );
    await _db.set('${AppConstants.dbRooms}/$roomId', room.toMap());

    var completed = 0;
    for (final image in images) {
      final imageId = _db.pushId('${AppConstants.dbRoomImages}/$roomId');
      final url = await _storage.uploadFile(
        file: File(image.path),
        folder: '${AppConstants.storageRoomPhotos}/$roomId',
        fileName: '$imageId.jpg',
      );
      await _db.set('${AppConstants.dbRoomImages}/$roomId/$imageId', {
        'imageUrl': url,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      completed++;
      onProgress?.call(completed / images.length);
    }

    return roomId;
  }
}
