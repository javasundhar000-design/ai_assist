import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/local_storage_service.dart';
import '../../models/accessibility_role.dart';
import '../../models/user_profile.dart';

/// Very small local-only "auth". There is no backend (Section 1: strictly
/// offline-first Flutter), so this hashes the password with a simple,
/// reversible-free digest just to avoid storing plaintext — it is not
/// meant to be production-grade cryptography.
String _naiveHash(String input) {
  var hash = 0;
  for (final codeUnit in input.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }
  return hash.toString();
}

class SessionNotifier extends StateNotifier<UserProfile?> {
  final LocalStorageService _storage = LocalStorageService.instance;

  SessionNotifier() : super(null) {
    if (_storage.isLoggedIn) {
      state = _storage.getCurrentUser();
    }
  }

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required Set<AccessibilityRole> roles,
    required String preferredLanguage,
    required String emergencyContact,
  }) async {
    final user = UserProfile(
      id: const Uuid().v4(),
      name: name,
      email: email,
      passwordHash: _naiveHash(password),
      accessibilityProfiles: roles,
      preferredLanguage: preferredLanguage,
      emergencyContact: emergencyContact,
      createdAt: DateTime.now(),
    );
    await _storage.saveUser(user);
    state = user;
    return user;
  }

  Future<void> updateRoles(Set<AccessibilityRole> roles) async {
    final current = state;
    if (current == null) return;
    final updated = current.copyWith(accessibilityProfiles: roles);
    await _storage.saveUser(updated);
    state = updated;
  }

  Future<void> logout() async {
    await _storage.logout();
    state = null;
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, UserProfile?>(
  (ref) => SessionNotifier(),
);

final isLoggedInProvider = Provider<bool>((ref) => ref.watch(sessionProvider) != null);
