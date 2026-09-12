import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../repositories/auth_repository.dart';
import '../services/ai_service.dart';
import '../services/permission_service.dart';
import '../services/secure_storage_service.dart';
import '../services/tts_service.dart';

/// Single instance shared across the app — holds the session id and the
/// person's own OpenRouter key.
final secureStorageProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

/// On-device auth/user store. There is no backend to swap in here anymore
/// by design (see app_config.dart) — this is the one and only
/// implementation.
final authRepositoryProvider = Provider<LocalAuthRepository>((ref) {
  return LocalAuthRepository(secureStorage: ref.watch(secureStorageProvider));
});

/// Falls back to on-device demo responses until the person adds their own
/// OpenRouter key in Settings.
final aiServiceProvider = Provider<AiService>((ref) {
  return HybridAiService(secureStorage: ref.watch(secureStorageProvider));
});

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;

  const AuthState({required this.status, this.user});

  const AuthState.unknown() : this(status: AuthStatus.unknown);
  const AuthState.authenticated(AppUser user)
      : this(status: AuthStatus.authenticated, user: user);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
}

/// The single source of truth for "who is logged in and what can they do".
/// GoRouter's redirect logic, dashboards, and feature gating all read from
/// this notifier — never from a locally cached role string.
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthState.unknown()) {
    _restore();
  }

  Future<void> _restore() async {
    final user = await _repository.restoreSession();
    state = user != null
        ? AuthState.authenticated(user)
        : const AuthState.unauthenticated();
  }

  Future<void> login({required String identifier, required String password}) async {
    final user = await _repository.login(identifier: identifier, password: password);
    state = AuthState.authenticated(user);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    DateTime? dateOfBirth,
  }) async {
    final user = await _repository.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      role: role,
      dateOfBirth: dateOfBirth,
    );
    state = AuthState.authenticated(user);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState.unauthenticated();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

/// Derives a PermissionService from whoever is currently logged in.
final permissionServiceProvider = Provider<PermissionService>((ref) {
  final auth = ref.watch(authControllerProvider);
  return PermissionService(auth.user);
});
