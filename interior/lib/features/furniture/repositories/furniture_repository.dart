import '../../../app/constants/app_constants.dart';
import '../../../firebase/realtime_database/realtime_database_service.dart';
import '../../../models/room_and_design_models.dart';

/// Read-only access to root/furniture (Sec. 15, 24). The catalog is
/// intentionally not writable from the app (Sec. 26: "Furniture catalog
/// can be read-only for normal users") — populating it is an
/// out-of-band admin task. See README "Seeding the furniture catalog".
class FurnitureRepository {
  final RealtimeDatabaseService _db;
  FurnitureRepository(this._db);

  Stream<List<FurnitureModel>> watchAll() {
    return _db.watch(AppConstants.dbFurniture).map((event) {
      final value = event.snapshot.value;
      if (value == null) return <FurnitureModel>[];
      final map = Map<dynamic, dynamic>.from(value as Map);
      return map.entries
          .map((e) =>
              FurnitureModel.fromMap(e.key as String, e.value as Map))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  Future<FurnitureModel?> getById(String id) async {
    final snap = await _db.readOnce('${AppConstants.dbFurniture}/$id');
    if (!snap.exists || snap.value == null) return null;
    return FurnitureModel.fromMap(id, snap.value as Map<dynamic, dynamic>);
  }
}
