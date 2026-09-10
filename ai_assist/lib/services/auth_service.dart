import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../models/user_role.dart';

/// LOCAL-ONLY auth for the prototype: profiles live in this device's
/// storage, not a server. That's enough to demonstrate real role-based
/// access control (a Blind-role user genuinely cannot reach Motor Mode
/// screens, etc), but it means:
///  - "Members" are per-device, not shared across a family's phones.
///  - Admin can only see alerts/profiles created on THIS device.
///
/// To make this multi-device (e.g. one caregiver's phone as Admin,
/// watching several members' separate phones), swap this service's
/// storage calls for a backend (Firebase Auth + Firestore is a common,
/// fast path) — the rest of the app (screens, role gating) doesn't need
/// to change, since everything already goes through this one service.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  static const _kProfilesKey = 'user_profiles';
  static const _kCurrentProfileIdKey = 'current_profile_id';

  final _rand = Random();

  String _newId() =>
      '${DateTime.now().millisecondsSinceEpoch}_${_rand.nextInt(99999)}';

  Future<List<UserProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProfilesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveProfiles(List<UserProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_kProfilesKey, raw);
  }

  /// Registers a new profile and returns it. Caller is responsible for
  /// enforcing uniqueness rules (e.g. don't let just anyone add an admin
  /// without a PIN — see RegisterScreen).
  Future<UserProfile> register({
    required String name,
    required UserRole role,
    List<dynamic> emergencyContacts = const [],
    String? adminPin,
  }) async {
    final profiles = await loadProfiles();
    final profile = UserProfile(
      id: _newId(),
      name: name.trim(),
      role: role,
      emergencyContacts: emergencyContacts.cast(),
    );
    profiles.add(profile);
    await _saveProfiles(profiles);
    return profile;
  }

  Future<void> deleteProfile(String id) async {
    final profiles = await loadProfiles();
    profiles.removeWhere((p) => p.id == id);
    await _saveProfiles(profiles);
    final current = await getCurrentProfileId();
    if (current == id) await logout();
  }

  Future<String?> getCurrentProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrentProfileIdKey);
  }

  /// Logs a profile in. For admin profiles, verify the PIN BEFORE calling
  /// this (see verifyAdminPin) — this method itself does not check it, to
  /// keep it reusable for the non-admin "just tap your name" flow.
  Future<void> login(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrentProfileIdKey, profileId);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrentProfileIdKey);
  }

  Future<UserProfile?> getCurrentProfile() async {
    final id = await getCurrentProfileId();
    if (id == null) return null;
    final profiles = await loadProfiles();
    try {
      return profiles.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  bool verifyAdminPin(UserProfile profile, String enteredPin) {
    return false;
  }
}
