import 'package:firebase_database/firebase_database.dart';
import '../../core/errors/app_exception.dart';

/// Generic wrapper over Firebase Realtime Database.
///
/// Firebase Realtime Database is the ONLY database used by this app —
/// no Firestore, no SQL (Sec. 3, 24). Every repository should go through
/// this service instead of touching FirebaseDatabase directly, so the
/// data layer stays swappable/testable.
class RealtimeDatabaseService {
  final FirebaseDatabase _db;
  RealtimeDatabaseService({FirebaseDatabase? db})
      : _db = db ?? FirebaseDatabase.instance;

  DatabaseReference _ref(String path) => _db.ref(path);

  /// Generates a Firebase push ID without writing data yet — useful when
  /// you need the id up front (e.g. to also upload a file to Storage
  /// under that id before writing the DB record).
  String pushId(String path) => _ref(path).push().key!;

  Future<void> set(String path, Map<String, dynamic> data) async {
    try {
      await _ref(path).set(data);
    } catch (e) {
      throw DatabaseException('Could not save data. Please try again.',
          cause: e);
    }
  }

  Future<void> update(String path, Map<String, dynamic> data) async {
    try {
      await _ref(path).update(data);
    } catch (e) {
      throw DatabaseException('Could not update data. Please try again.',
          cause: e);
    }
  }

  Future<void> remove(String path) async {
    try {
      await _ref(path).remove();
    } catch (e) {
      throw DatabaseException('Could not delete data. Please try again.',
          cause: e);
    }
  }

  Future<DataSnapshot> readOnce(String path) async {
    try {
      return await _ref(path).get();
    } catch (e) {
      throw DatabaseException('Could not load data. Please try again.',
          cause: e);
    }
  }

  /// Live stream of a node — use for screens that should reflect changes
  /// in real time (e.g. design history, project list).
  Stream<DatabaseEvent> watch(String path) {
    return _ref(path).onValue.handleError((e) {
      throw DatabaseException('Lost connection to the database.', cause: e);
    });
  }

  /// Query helper: get all children of [path] where [childKey] == [value].
  /// Requires an index on childKey for production use
  /// (see database.rules.json ".indexOn").
  Stream<DatabaseEvent> watchWhereEquals(
    String path,
    String childKey,
    Object value,
  ) {
    return _ref(path).orderByChild(childKey).equalTo(value).onValue;
  }
}
