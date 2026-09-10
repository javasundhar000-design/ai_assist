import 'dart:math';

import 'package:firebase_database/firebase_database.dart';

import '../models/emergency_alert.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

/// All shared, multi-device data lives here, keyed by the caregiver's
/// Firebase Auth UID:
///
///   /families/{uid}/code               "7F3KQ9"  — human-typeable join code
///   /families/{uid}/members/{memberId} { name, role, emergencyContacts }
///   /families/{uid}/alerts/{alertId}   { profileId, profileName, roleLabel,
///                                         timestamp, resolved }
///   /codes/{code}                      uid        — reverse index so a
///                                                    member device can
///                                                    resolve a typed code
///                                                    to a family without
///                                                    scanning every family
///
/// A member device never signs in — it looks up the family by code, reads
/// that family's member list, and the person taps their own name. The
/// code + chosen member id are then cached locally (see SessionService)
/// so they don't have to repeat this each app launch.
///
/// IMPORTANT: this only works once you've set Realtime Database security
/// rules that match this structure — see FIREBASE_SETUP.md. Without
/// rules, Firebase denies all reads/writes by default.
class FamilyService {
  FamilyService._internal();
  static final FamilyService instance = FamilyService._internal();

  final _db = FirebaseDatabase.instance;
  final _rand = Random();

  static const _codeChars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; // no 0/O/1/I/L

  String _generateCode() =>
      List.generate(6, (_) => _codeChars[_rand.nextInt(_codeChars.length)]).join();

  /// Call once, right after a caregiver signs up, to give their family a
  /// join code. Safe to call again — it's a no-op if a code already exists.
  Future<String> ensureFamilyCode(String uid) async {
    final codeRef = _db.ref('families/$uid/code');
    final existing = await codeRef.get();
    if (existing.exists && existing.value != null) {
      return existing.value as String;
    }

    String code = _generateCode();
    // Extremely unlikely to collide at this scale, but check anyway.
    while ((await _db.ref('codes/$code').get()).exists) {
      code = _generateCode();
    }

    await codeRef.set(code);
    await _db.ref('codes/$code').set(uid);
    return code;
  }

  Stream<String?> familyCodeStream(String uid) {
    return _db.ref('families/$uid/code').onValue.map((event) {
      final value = event.snapshot.value;
      return value == null ? null : value.toString();
    });
  }

  /// Resolves a typed join code to a family's caregiver UID, or null if
  /// the code doesn't exist.
  Future<String?> resolveCode(String code) async {
    final snapshot = await _db.ref('codes/${code.toUpperCase()}').get();
    if (!snapshot.exists) return null;
    return snapshot.value as String?;
  }

  // ---------------- Members ----------------

  Stream<List<UserProfile>> membersStream(String familyUid) {
    return _db.ref('families/$familyUid/members').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null) return <UserProfile>[];
      final map = Map<String, dynamic>.from(raw as Map);
      return map.entries
          .map((e) => UserProfile.fromJson({
                'id': e.key,
                ...Map<String, dynamic>.from(e.value as Map),
              }))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  Future<UserProfile?> getMember(String familyUid, String memberId) async {
    final snapshot = await _db.ref('families/$familyUid/members/$memberId').get();
    if (!snapshot.exists) return null;
    return UserProfile.fromJson({
      'id': memberId,
      ...Map<String, dynamic>.from(snapshot.value as Map),
    });
  }

  Future<String> addMember({
    required String familyUid,
    required String name,
    required UserRole role,
    required List<Map<String, dynamic>> emergencyContacts,
  }) async {
    final ref = _db.ref('families/$familyUid/members').push();
    await ref.set({
      'name': name,
      'role': role.name,
      'emergencyContacts': emergencyContacts,
    });
    return ref.key!;
  }

  Future<void> deleteMember(String familyUid, String memberId) {
    return _db.ref('families/$familyUid/members/$memberId').remove();
  }

  // ---------------- Emergency alerts ----------------

  Stream<List<EmergencyAlert>> alertsStream(String familyUid) {
    return _db.ref('families/$familyUid/alerts').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null) return <EmergencyAlert>[];
      final map = Map<String, dynamic>.from(raw as Map);
      final alerts = map.entries
          .map((e) => EmergencyAlert.fromJson({
                'id': e.key,
                ...Map<String, dynamic>.from(e.value as Map),
              }))
          .toList();
      alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return alerts;
    });
  }

  Future<void> pushAlert({
    required String familyUid,
    required UserProfile profile,
  }) async {
    final ref = _db.ref('families/$familyUid/alerts').push();
    await ref.set({
      'profileId': profile.id,
      'profileName': profile.name,
      'roleLabel': profile.role.label,
      'timestamp': DateTime.now().toIso8601String(),
      'resolved': false,
    });
  }

  Future<void> resolveAlert(String familyUid, String alertId) {
    return _db.ref('families/$familyUid/alerts/$alertId/resolved').set(true);
  }
}
