import 'package:firebase_database/firebase_database.dart';
import '../models/realtime_models.dart';

/// All Realtime Database reads/writes for caregiver links, alerts, and AI
/// history go through this one class — no screen talks to
/// FirebaseDatabase directly, so the data shape only needs to change here
/// if it ever changes.
///
/// Database layout:
///   /users/{uid}                          — see FirebaseAuthRepository
///   /caregiver_links/{caregiverUid}/{id}   — that caregiver's linked users
///   /alerts/{caregiverUid}/{id}            — alerts visible to that caregiver
///   /ai_history/{uid}/{id}                 — that user's own AI operation history
///
/// This only works when Firebase is actually configured — callers should
/// check `firebaseReadyProvider` first (see core/providers.dart) and skip
/// calling this in local/demo mode, where there's no live data source.
class RealtimeDataService {
  final FirebaseDatabase _db;

  RealtimeDataService({FirebaseDatabase? database}) : _db = database ?? FirebaseDatabase.instance;

  // ---- Caregiver: linked users ----

  Stream<List<CaregiverLinkedUser>> linkedUsersStream(String caregiverUid) {
    return _db.ref('caregiver_links/$caregiverUid').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return <CaregiverLinkedUser>[];
      final map = Map<dynamic, dynamic>.from(value as Map);
      return map.entries
          .map((e) => CaregiverLinkedUser.fromMap(e.key as String, e.value as Map))
          .toList();
    });
  }

  // ---- Caregiver: alerts ----

  Stream<List<CaregiverAlert>> alertsStream(String caregiverUid) {
    return _db.ref('alerts/$caregiverUid').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return <CaregiverAlert>[];
      final map = Map<dynamic, dynamic>.from(value as Map);
      final alerts =
          map.entries.map((e) => CaregiverAlert.fromMap(e.key as String, e.value as Map)).toList();
      alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return alerts;
    });
  }

  // ---- Per-user: AI history ----

  Stream<List<HistoryEntry>> historyStream(String uid) {
    return _db.ref('ai_history/$uid').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return <HistoryEntry>[];
      final map = Map<dynamic, dynamic>.from(value as Map);
      final entries =
          map.entries.map((e) => HistoryEntry.fromMap(e.key as String, e.value as Map)).toList();
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    });
  }

  Future<void> recordHistory(String uid, String taskType, String summary) async {
    final entry = HistoryEntry(
      id: '',
      taskType: taskType,
      summary: summary,
      createdAt: DateTime.now(),
    );
    await _db.ref('ai_history/$uid').push().set(entry.toMap());
  }

  /// Seeds illustrative linked users + one alert for a freshly-registered
  /// caregiver, purely so the Caregiver dashboard isn't empty on first
  /// login (there's no invite/consent flow built yet — see the doc comment
  /// on CaregiverLinkedUser for why these are fictional, denormalized
  /// entries rather than real linked accounts). Idempotent: only writes if
  /// this caregiver has no links yet.
  Future<void> seedDemoCaregiverDataIfEmpty(String caregiverUid) async {
    final ref = _db.ref('caregiver_links/$caregiverUid');
    final existing = await ref.get();
    if (existing.exists) return;

    await ref.set({
      'demo1': const CaregiverLinkedUser(
              id: 'demo1', name: 'Rahul Sharma', relationship: 'Son', status: 'online')
          .toMap(),
      'demo2': const CaregiverLinkedUser(
              id: 'demo2',
              name: 'Sneha Sharma',
              relationship: 'Daughter',
              status: 'recent',
              lastActiveLabel: 'Last active 2 hours ago')
          .toMap(),
      'demo3': const CaregiverLinkedUser(
              id: 'demo3', name: 'Vikram Sharma', relationship: 'Brother', status: 'offline')
          .toMap(),
    });

    await _db.ref('alerts/$caregiverUid').push().set(
          CaregiverAlert(
            id: '',
            userName: 'Rahul Sharma',
            type: 'fallDetected',
            status: 'Open',
            createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
          ).toMap(),
        );
  }
}
