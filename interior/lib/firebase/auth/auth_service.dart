import 'package:firebase_auth/firebase_auth.dart';
import '../../core/errors/app_exception.dart';

/// Thin wrapper around FirebaseAuth. Nothing above this layer should ever
/// import `package:firebase_auth` directly — that keeps Firebase confined
/// to lib/firebase/ per the architecture in Sec. 4/5.
class AuthService {
  final FirebaseAuth _auth;
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw const AuthException('Registration failed. Please try again.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthMessage(e.code), cause: e);
    }
  }

  Future<User> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw const AuthException('Login failed. Please try again.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthMessage(e.code), cause: e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthMessage(e.code), cause: e);
    }
  }

  Future<void> updateDisplayName(String name) async {
    try {
      await _auth.currentUser?.updateDisplayName(name);
    } on FirebaseAuthException catch (e) {
      throw AuthException(friendlyAuthMessage(e.code), cause: e);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
