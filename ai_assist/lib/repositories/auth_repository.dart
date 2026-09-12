import 'dart:convert';
import 'package:ai_assist/services/secure_storage_service.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/role_permission_map.dart';
import '../core/errors/app_exception.dart';
import '../models/permission.dart';
import '../models/user.dart';
import '../models/user_role.dart';


/// Everything the app needs from "a backend" for accounts/roles/permissions,
/// done entirely on-device. There is no server anymore — see AppConfig for
/// why (this was a deliberate choice to eliminate network/deployment
/// complexity for a single-device accessibility app).
///
/// Passwords are stored as salted SHA-256 hashes, never plaintext (spec
/// §42/§52 still apply even without a server). This is adequate for an
/// on-device, single-user-per-install app; it is not a substitute for a
/// real server-side auth system if this app is ever made multi-tenant or
/// distributed with shared accounts.
abstract class AuthRepository {
  Future<AppUser> login({required String identifier, required String password});

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    DateTime? dateOfBirth,
  });

  Future<AppUser?> restoreSession();

  Future<void> logout();

  Future<void> requestPasswordReset(String identifier);
}

class _StoredAccount {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String passwordSalt;
  final String passwordHash;
  final UserRole role;
  UserStatus status;
  DateTime? lastLoginAt;

  _StoredAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.passwordSalt,
    required this.passwordHash,
    required this.role,
    required this.status,
    this.lastLoginAt,
  });

  factory _StoredAccount.fromJson(Map<String, dynamic> json) => _StoredAccount(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String? ?? '',
        passwordSalt: json['passwordSalt'] as String,
        passwordHash: json['passwordHash'] as String,
        role: UserRole.fromWireValue(json['role'] as String),
        status: (json['status'] as String?) == 'INACTIVE'
            ? UserStatus.inactive
            : UserStatus.active,
        lastLoginAt:
            json['lastLoginAt'] != null ? DateTime.tryParse(json['lastLoginAt'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'passwordSalt': passwordSalt,
        'passwordHash': passwordHash,
        'role': role.wireValue,
        'status': status == UserStatus.active ? 'ACTIVE' : 'INACTIVE',
        'lastLoginAt': lastLoginAt?.toIso8601String(),
      };

  AppUser toAppUser() => AppUser(
        id: id,
        fullName: fullName,
        email: email,
        phone: phone,
        role: role,
        status: status,
        permissions: Set<Permission>.from(kDefaultRolePermissions[role] ?? {}),
        lastLoginAt: lastLoginAt,
      );
}

class LocalAuthRepository implements AuthRepository {
  static const _usersKey = 'ai_assist_users_v1';

  final SecureStorageService _secureStorage;

  LocalAuthRepository({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService();

  String _hash(String password, String salt) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }

  String _newSalt(String seed) => sha256.convert(utf8.encode('$seed::${DateTime.now().microsecondsSinceEpoch}')).toString().substring(0, 16);

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<_StoredAccount>> _loadAccounts() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_usersKey);
    if (raw == null) {
      final seeded = _seedDemoAccounts();
      await _saveAccounts(seeded);
      return seeded;
    }
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(_StoredAccount.fromJson).toList();
  }

  Future<void> _saveAccounts(List<_StoredAccount> accounts) async {
    final prefs = await _prefs;
    await prefs.setString(_usersKey, jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }

  _StoredAccount? _byEmail(List<_StoredAccount> accounts, String email) {
    final matches = accounts.where((a) => a.email == email);
    return matches.isEmpty ? null : matches.first;
  }

  _StoredAccount? _byId(List<_StoredAccount> accounts, String id) {
    final matches = accounts.where((a) => a.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  /// Seeds the same demo accounts documented in the README, so the app is
  /// explorable immediately on first launch. Password for all: password123.
  List<_StoredAccount> _seedDemoAccounts() {
    _StoredAccount seed(String email, String name, UserRole role) {
      final salt = _newSalt(email);
      return _StoredAccount(
        id: email.hashCode.toString(),
        fullName: name,
        email: email,
        phone: '+91 90000 00000',
        passwordSalt: salt,
        passwordHash: _hash('password123', salt),
        role: role,
        status: UserStatus.active,
      );
    }

    return [
      seed('alex@example.com', 'Alex Johnson', UserRole.blind),
      seed('sam@example.com', 'Sam Rivera', UserRole.nonSpeaking),
      seed('taylor@example.com', 'Taylor Kim', UserRole.motorImpaired),
      seed('priya@example.com', 'Priya Nair', UserRole.caregiver),
      seed('admin@example.com', 'System Admin', UserRole.admin),
    ];
  }

  @override
  Future<AppUser> login({required String identifier, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final accounts = await _loadAccounts();
    final email = identifier.trim().toLowerCase();
    final account = _byEmail(accounts, email);
    if (account == null) {
      throw const AppException('Invalid email/phone or password.');
    }
    if (_hash(password, account.passwordSalt) != account.passwordHash) {
      throw const AppException('Invalid email/phone or password.');
    }
    if (account.status == UserStatus.inactive) {
      throw const AppException('This account has been deactivated.');
    }
    account.lastLoginAt = DateTime.now();
    await _saveAccounts(accounts);
    await _secureStorage.saveSessionUserId(account.id);
    return account.toAppUser();
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
    await Future.delayed(const Duration(milliseconds: 300));

    // Defense in depth: even though the Register screen never offers ADMIN
    // as an option, this repository refuses it too (spec §3/§52) — no code
    // path, UI bug, or crafted call can create an admin this way.
    if (role == UserRole.admin) {
      throw const AppException(
          'Admin accounts cannot be self-registered. An existing admin must create one from Manage Users.');
    }

    final accounts = await _loadAccounts();
    final normalizedEmail = email.trim().toLowerCase();
    if (_byEmail(accounts, normalizedEmail) != null) {
      throw const AppException('An account with this email already exists.');
    }

    final salt = _newSalt(normalizedEmail);
    final account = _StoredAccount(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      fullName: fullName,
      email: normalizedEmail,
      phone: phone,
      passwordSalt: salt,
      passwordHash: _hash(password, salt),
      role: role,
      status: UserStatus.active,
      lastLoginAt: DateTime.now(),
    );
    accounts.add(account);
    await _saveAccounts(accounts);
    await _secureStorage.saveSessionUserId(account.id);
    return account.toAppUser();
  }

  @override
  Future<AppUser?> restoreSession() async {
    final sessionId = await _secureStorage.getSessionUserId();
    if (sessionId == null) return null;
    final accounts = await _loadAccounts();
    final account = _byId(accounts, sessionId);
    if (account == null || account.status == UserStatus.inactive) {
      await _secureStorage.clearSession();
      return null;
    }
    return account.toAppUser();
  }

  @override
  Future<void> logout() => _secureStorage.clearSession();

  @override
  Future<void> requestPasswordReset(String identifier) async {
    // No email/SMS provider without a backend. This is a placeholder that
    // keeps the UI flow intact; wire up a transactional email service (or
    // point this repository back at a real backend) if you need this to
    // actually deliver a reset link.
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Admin-only local user management, used by the Manage Users screen
  /// instead of an /admin/users API call.
  Future<List<AppUser>> allUsers() async {
    final accounts = await _loadAccounts();
    return accounts.map((a) => a.toAppUser()).toList();
  }

  Future<void> setStatus(String userId, UserStatus status) async {
    final accounts = await _loadAccounts();
    final account = _byId(accounts, userId);
    if (account != null) {
      account.status = status;
      await _saveAccounts(accounts);
    }
  }
}
