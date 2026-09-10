import 'package:uuid/uuid.dart';
import '../../../app/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../firebase/realtime_database/realtime_database_service.dart';
import '../../../models/room_and_design_models.dart';

/// CRUD for saved designs (Sec. 21, 22, 24): create (Phase 12), and the
/// full list/open/duplicate/delete/restore set (Phase 14). Delete is a
/// soft-delete (`deletedAt` timestamp) so Restore is just clearing that
/// field — no separate trash structure needed.
class DesignRepository {
  final RealtimeDatabaseService _db;
  final _uuid = const Uuid();
  DesignRepository(this._db);

  /// Creates root/designs/{designId} and root/designFurniture/{designId}/*
  /// (Sec. 21, 24) in one pass. Returns the new designId.
  Future<String> saveDesign({
    required String userId,
    required String projectId,
    required String roomId,
    required String name,
    required InteriorStyle style,
    required List<DesignFurnitureInstance> furniture,
  }) async {
    final designId = _db.pushId(AppConstants.dbDesigns);
    final now = DateTime.now().millisecondsSinceEpoch;

    final design = DesignModel(
      id: designId,
      userId: userId,
      projectId: projectId,
      roomId: roomId,
      name: name,
      style: style,
      createdAt: now,
      updatedAt: now,
    );
    await _db.set('${AppConstants.dbDesigns}/$designId', design.toMap());

    if (furniture.isNotEmpty) {
      final updates = <String, dynamic>{};
      for (final instance in furniture) {
        updates[instance.instanceId] = instance.toMap();
      }
      await _db.update(
          '${AppConstants.dbDesignFurniture}/$designId', updates);
    }

    return designId;
  }

  /// Live list of every design (active and soft-deleted) belonging to a
  /// project, newest-updated first. The History screen splits active vs.
  /// deleted client-side.
  Stream<List<DesignModel>> watchDesignsForProject(String projectId) {
    return _db
        .watchWhereEquals(AppConstants.dbDesigns, 'projectId', projectId)
        .map((event) {
      final value = event.snapshot.value;
      if (value == null) return <DesignModel>[];
      final map = Map<dynamic, dynamic>.from(value as Map);
      final designs = map.entries
          .map((e) =>
              DesignModel.fromMap(e.key as String, e.value as Map<dynamic, dynamic>))
          .toList();
      designs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return designs;
    });
  }

  Future<DesignModel?> getDesign(String designId) async {
    final snap = await _db.readOnce('${AppConstants.dbDesigns}/$designId');
    if (!snap.exists || snap.value == null) return null;
    return DesignModel.fromMap(designId, snap.value as Map<dynamic, dynamic>);
  }

  Future<List<DesignFurnitureInstance>> getDesignFurniture(
      String designId) async {
    final snap =
        await _db.readOnce('${AppConstants.dbDesignFurniture}/$designId');
    if (!snap.exists || snap.value == null) return [];
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    return map.entries
        .map((e) => DesignFurnitureInstance.fromMap(
            e.key as String, e.value as Map<dynamic, dynamic>))
        .toList();
  }

  /// Duplicate (Sec. 22): copies the design record and every placed
  /// furniture instance under a new designId. Positions/rotations/scales
  /// carry over exactly since this stays within the same AR-world
  /// coordinate space semantics as the original (it's just a data copy,
  /// not a re-placement).
  Future<String> duplicateDesign({
    required String designId,
    required String userId,
  }) async {
    final original = await getDesign(designId);
    if (original == null) {
      throw const DatabaseException('Design not found.');
    }
    final furniture = await getDesignFurniture(designId);

    final newId = _db.pushId(AppConstants.dbDesigns);
    final now = DateTime.now().millisecondsSinceEpoch;
    final copy = DesignModel(
      id: newId,
      userId: userId,
      projectId: original.projectId,
      roomId: original.roomId,
      name: '${original.name} (Copy)',
      style: original.style,
      createdAt: now,
      updatedAt: now,
    );
    await _db.set('${AppConstants.dbDesigns}/$newId', copy.toMap());

    if (furniture.isNotEmpty) {
      final updates = <String, dynamic>{};
      for (final instance in furniture) {
        // Fresh instance ids even though the designId differs, to avoid
        // any accidental key collisions if this logic is ever reused
        // across designs sharing an id namespace.
        updates[_uuid.v4()] = instance.toMap();
      }
      await _db.update('${AppConstants.dbDesignFurniture}/$newId', updates);
    }
    return newId;
  }

  /// Delete (Sec. 22): soft-delete via `deletedAt`, so Restore just
  /// clears it — no data is actually removed until
  /// [permanentlyDeleteDesign] is called.
  Future<void> softDeleteDesign(String designId) {
    return _db.update('${AppConstants.dbDesigns}/$designId', {
      'deletedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Restore (Sec. 22): clears the soft-delete marker. Setting a field
  /// to null in a Realtime Database update() removes that field.
  Future<void> restoreDesign(String designId) {
    return _db.update(
        '${AppConstants.dbDesigns}/$designId', {'deletedAt': null});
  }

  Future<void> permanentlyDeleteDesign(String designId) async {
    await _db.remove('${AppConstants.dbDesigns}/$designId');
    await _db.remove('${AppConstants.dbDesignFurniture}/$designId');
  }
}
