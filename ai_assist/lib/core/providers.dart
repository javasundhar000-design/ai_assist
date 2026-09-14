import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/realtime_models.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../repositories/auth_repository.dart';
import '../repositories/firebase_auth_repository.dart';
import '../services/ai_service.dart';
import '../services/permission_service.dart';
import '../services/realtime_data_service.dart';
import '../services/secure_storage_service.dart';
import '../services/tts_service.dart';

/// Set once at app startup (see main.dart) based on whether
/// Firebase.initializeApp() actually succeeded. Overridden via
/// ProviderScope(overrides: [...]) — this default value is only what's used
/// if something reads it before main.dart's override applies, which
/// shouldn't normally happen.
final firebaseReadyProvider = Provider<bool>((ref) => false);

final secureStorageProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

/// Firebase when it's configured and initialized successfully; otherwise
/// the on-device LocalAuthRepository. This means a fresh checkout that
/// hasn't run `flutterfire configure` yet still works end-to-end in local
/// demo mode, same as the AI service's OpenRouter-key-optional fallback.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(firebaseReadyProvider)) {
    return FirebaseAuthRepository();
  }
  // Assigned to a local variable rather than passed inline: passing
  // ref.watch(...) directly as an argument to a constructor parameter that
  // is itself nullable (SecureStorageService?) confuses Dart's generic type
  // inference for ref.watch<T>() — it infers T as SecureStorageService?
  // instead of SecureStorageService, which then fails to match the
  // provider's actual ProviderListenable<SecureStorageService>. Resolving
  // the value first, with its natural non-nullable type, avoids the issue.
  final SecureStorageService storage = ref.watch(secureStorageProvider);
  return LocalAuthRepository(secureStorage: storage);
});

final realtimeDataServiceProvider = Provider<RealtimeDataService?>((ref) {
  return ref.watch(firebaseReadyProvider) ? RealtimeDataService() : null;
});

/// Falls back to on-device demo responses until the person adds their own
/// OpenRouter key in Settings.
final aiServiceProvider = Provider<AiService>((ref) {
  final SecureStorageService storage = ref.watch(secureStorageProvider);
  return HybridAiService(secureStorage: storage);
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
  final RealtimeDataService? _realtimeData;

  AuthController(this._repository, this._realtimeData) : super(const AuthState.unknown()) {
    _restore();
  }

  Future<void> _restore() async {
    final user = await _repository.restoreSession();
    state = user != null
        ? AuthState.authenticated(user)
        : const AuthState.unauthenticated();
  }

  Future<void> _seedCaregiverDemoDataIfNeeded(AppUser user) async {
    if (_realtimeData == null || user.role != UserRole.caregiver) return;
    try {
      await _realtimeData.seedDemoCaregiverDataIfEmpty(user.id);
    } catch (_) {
      // Non-critical — the dashboard just shows an empty state if this
      // fails (e.g. rules not deployed yet), rather than blocking login.
    }
  }

  Future<void> login({required String identifier, required String password}) async {
    final user = await _repository.login(identifier: identifier, password: password);
    state = AuthState.authenticated(user);
    await _seedCaregiverDemoDataIfNeeded(user);
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
    await _seedCaregiverDemoDataIfNeeded(user);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState.unauthenticated();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref.watch(realtimeDataServiceProvider));
});

/// Derives a PermissionService from whoever is currently logged in.
final permissionServiceProvider = Provider<PermissionService>((ref) {
  final auth = ref.watch(authControllerProvider);
  return PermissionService(auth.user);
});

// ---- Live data streams (Firebase-only; empty when running in local mode) ----

final linkedUsersProvider = StreamProvider<List<CaregiverLinkedUser>>((ref) {
  final service = ref.watch(realtimeDataServiceProvider);
  final uid = ref.watch(authControllerProvider).user?.id;
  if (service == null || uid == null) return const Stream.empty();
  return service.linkedUsersStream(uid);
});

final alertsProvider = StreamProvider<List<CaregiverAlert>>((ref) {
  final service = ref.watch(realtimeDataServiceProvider);
  final uid = ref.watch(authControllerProvider).user?.id;
  if (service == null || uid == null) return const Stream.empty();
  return service.alertsStream(uid);
});

final historyProvider = StreamProvider<List<HistoryEntry>>((ref) {
  final service = ref.watch(realtimeDataServiceProvider);
  final uid = ref.watch(authControllerProvider).user?.id;
  if (service == null || uid == null) return const Stream.empty();
  return service.historyStream(uid);
});
