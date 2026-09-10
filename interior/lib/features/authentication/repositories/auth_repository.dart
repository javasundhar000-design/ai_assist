import '../../../app/constants/app_constants.dart';
import '../../../firebase/auth/auth_service.dart';
import '../../../firebase/realtime_database/realtime_database_service.dart';
import '../../../models/user_model.dart';

class AuthRepository {
  final AuthService _authService;
  final RealtimeDatabaseService _db;

  AuthRepository({
    required AuthService authService,
    required RealtimeDatabaseService db,
  })  : _authService = authService,
        _db = db;

  Stream<UserModel?> authState() {
    return _authService.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return getUserProfile(user.uid, fallbackEmail: user.email ?? '');
    });
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final firebaseUser = await _authService.registerWithEmail(
      email: email,
      password: password,
    );
    await _authService.updateDisplayName(name);

    final profile = UserModel(
      uid: firebaseUser.uid,
      name: name,
      email: email.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.set('${AppConstants.dbUsers}/${firebaseUser.uid}', profile.toMap());
    return profile;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final firebaseUser =
        await _authService.loginWithEmail(email: email, password: password);
    return getUserProfile(firebaseUser.uid, fallbackEmail: email);
  }

  Future<UserModel> getUserProfile(String uid,
      {required String fallbackEmail}) async {
    final snapshot = await _db.readOnce('${AppConstants.dbUsers}/$uid');
    if (snapshot.exists && snapshot.value != null) {
      return UserModel.fromMap(uid, snapshot.value as Map<dynamic, dynamic>);
    }
    // Profile node missing (e.g. legacy account) — synthesize a minimal one.
    return UserModel(
      uid: uid,
      name: '',
      email: fallbackEmail,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _authService.sendPasswordResetEmail(email);
  }

  Future<void> logout() => _authService.logout();
}
