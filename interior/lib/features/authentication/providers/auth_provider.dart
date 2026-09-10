import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../firebase/auth/auth_service.dart';
import '../../../firebase/realtime_database/realtime_database_service.dart';
import '../../../models/user_model.dart';
import '../repositories/auth_repository.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final realtimeDatabaseServiceProvider =
    Provider<RealtimeDatabaseService>((ref) => RealtimeDatabaseService());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authService: ref.watch(authServiceProvider),
    db: ref.watch(realtimeDatabaseServiceProvider),
  );
});

/// Emits the current signed-in user's profile, or null when signed out.
/// The whole app (router redirect, dashboard, etc.) watches this.
final authStateProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).authState();
});

/// Drives the Login screen: holds submit-in-progress / error state without
/// polluting the widget with local setState calls.
class AuthFormController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;
  AuthFormController(this._repo) : super(const AsyncData(null));

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _repo.login(email: email, password: password);
      state = const AsyncData(null);
      return true;
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = const AsyncLoading();
    try {
      await _repo.register(name: name, email: email, password: password);
      state = const AsyncData(null);
      return true;
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    try {
      await _repo.sendPasswordReset(email);
      state = const AsyncData(null);
      return true;
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final authFormControllerProvider =
    StateNotifierProvider<AuthFormController, AsyncValue<void>>((ref) {
  return AuthFormController(ref.watch(authRepositoryProvider));
});
