import 'package:shared_preferences/shared_preferences.dart';

/// Caches which family (by caregiver UID) and which member profile is
/// "active" on THIS device, so a member device only has to enter the
/// family join code once — after that, reopening the app goes straight
/// back to that person's mode.
///
/// Caregiver devices don't use this at all: their identity comes from
/// Firebase Auth (CaregiverAuthService.currentUser), which already
/// persists its own session.
class SessionService {
  SessionService._internal();
  static final SessionService instance = SessionService._internal();

  static const _kFamilyUidKey = 'session_family_uid';
  static const _kMemberIdKey = 'session_member_id';

  Future<void> saveMemberSession({
    required String familyUid,
    required String memberId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFamilyUidKey, familyUid);
    await prefs.setString(_kMemberIdKey, memberId);
  }

  /// Just remembers the family (after entering a join code) without yet
  /// picking a specific member — used on the "pick your name" screen.
  Future<void> saveFamilyUid(String familyUid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFamilyUidKey, familyUid);
  }

  Future<({String familyUid, String memberId})?> loadMemberSession() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_kFamilyUidKey);
    final memberId = prefs.getString(_kMemberIdKey);
    if (uid == null || memberId == null) return null;
    return (familyUid: uid, memberId: memberId);
  }

  Future<String?> loadFamilyUidOnly() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kFamilyUidKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kFamilyUidKey);
    await prefs.remove(_kMemberIdKey);
  }
}
