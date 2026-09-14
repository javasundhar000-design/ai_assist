import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_database/firebase_database.dart';
import '../core/constants/role_permission_map.dart';
import '../core/errors/app_exception.dart';
import '../models/permission.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import 'auth_repository.dart' show AuthRepository;

/// Accounts and roles backed by Firebase: Firebase Authentication owns
/// credentials (email/password, password reset emails), and the Realtime
/// Database stores the profile (name, phone, role, status) at
/// `/users/{uid}`.
///
/// SECURITY: this class enforces the same rules the on-device version did
/// (e.g. no self-registering as ADMIN) — but since there's no server
/// anymore, that client-side check alone isn't real security. The actual
/// enforcement layer is the Realtime Database Security Rules in
/// `database.rules.json`, which independently reject a client trying to
/// write role: "ADMIN" to their own profile, or trying to modify another
/// user's `role`/`status` field at all unless they're already an admin.
/// Treat the rules file as at least as important as this code.
class FirebaseAuthRepository implements AuthRepository {
  final fb_auth.FirebaseAuth _auth;
  final DatabaseReference _usersRef;

  FirebaseAuthRepository({fb_auth.FirebaseAuth? auth, FirebaseDatabase? database})
      : _auth = auth ?? fb_auth.FirebaseAuth.instance,
        _usersRef = (database ?? FirebaseDatabase.instance).ref('users');

  AppUser _fromSnapshot(String uid, Map<dynamic, dynamic> data) {
    final role = UserRole.fromWireValue(data['role'] as String);
    return AppUser(
      id: uid,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: role,
      status: (data['status'] as String?) == 'INACTIVE' ? UserStatus.inactive : UserStatus.active,
      // Permissions are derived from role client-side, same as before — the
      // database only ever needs to store the role, not a duplicated
      // permission list that could drift out of sync with
      // role_permission_map.dart.
      permissions: Set<Permission>.from(kDefaultRolePermissions[role] ?? {}),
      lastLoginAt:
          data['lastLoginAt'] != null ? DateTime.tryParse(data['lastLoginAt'] as String) : null,
    );
  }

  AppException _mapAuthError(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const AppException('Invalid email/phone or password.');
      case 'email-already-in-use':
        return const AppException('An account with this email already exists.');
      case 'weak-password':
        return const AppException('Password must be at least 8 characters.');
      case 'user-disabled':
        return const AppException('This account has been deactivated.');
      case 'network-request-failed':
        return const AppException('No internet connection.');
      case 'too-many-requests':
        return const AppException('Too many attempts. Please wait a moment and try again.');
      default:
        return AppException('Something went wrong. Please try again.', debugDetail: e.message);
    }
  }

  @override
  Future<AppUser> login({required String identifier, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: identifier.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      final snapshot = await _usersRef.child(uid).get();
      if (!snapshot.exists) {
        throw const AppException('Account profile not found. Contact your administrator.');
      }
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      if ((data['status'] as String?) == 'INACTIVE') {
        throw const AppException('This account has been deactivated.');
      }
      await _usersRef.child(uid).update({'lastLoginAt': DateTime.now().toIso8601String()});
      data['lastLoginAt'] = DateTime.now().toIso8601String();
      return _fromSnapshot(uid, data);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    DateTime? dateOfBirth,
  }) async {
    // Defense in depth: refused here in code AND independently refused by
    // database.rules.json even if this check were ever bypassed.
    if (role == UserRole.admin) {
      throw const AppException(
          'Admin accounts cannot be self-registered. An existing admin must create one from Manage Users.');
    }
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      final now = DateTime.now().toIso8601String();
      final profile = {
        'fullName': fullName,
        'email': email.trim().toLowerCase(),
        'phone': phone,
        'role': role.wireValue,
        'status': 'ACTIVE',
        'createdAt': now,
        'lastLoginAt': now,
      };
      await _usersRef.child(uid).set(profile);
      return _fromSnapshot(uid, profile);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  @override
  Future<AppUser?> restoreSession() async {
    final current = _auth.currentUser;
    if (current == null) return null;
    try {
      final snapshot = await _usersRef.child(current.uid).get();
      if (!snapshot.exists) return null;
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      if ((data['status'] as String?) == 'INACTIVE') return null;
      return _fromSnapshot(current.uid, data);
    } catch (_) {
      // Offline or a transient DB error on launch shouldn't force a logout
      // — treat it as "couldn't verify right now" rather than "signed out".
      return null;
    }
  }

  @override
  Future<void> logout() => _auth.signOut();

  @override
  Future<void> requestPasswordReset(String identifier) async {
    try {
      // This one actually sends a real email now — a genuine improvement
      // over the on-device version, which had no email provider to call.
      await _auth.sendPasswordResetEmail(email: identifier.trim());
    } on fb_auth.FirebaseAuthException catch (e) {
      // Don't reveal whether the account exists (spec-consistent with the
      // old backend's forgot-password behavior) — only surface real
      // connectivity/config problems.
      if (e.code == 'network-request-failed') {
        throw _mapAuthError(e);
      }
    }
  }
}
