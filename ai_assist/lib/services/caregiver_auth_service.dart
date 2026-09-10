import 'package:firebase_auth/firebase_auth.dart';

/// Real account security for caregivers/admins, via Firebase Auth
/// (email + password). Members (Blind/Non-Speaking/Motor) deliberately do
/// NOT get individual accounts here — typing an email and password is not
/// realistic for a lot of this app's members, so they join a caregiver's
/// family by a short code and pick their name instead. See FamilyService
/// for that flow. The caregiver's Firebase UID is the root key for all of
/// that family's data in Realtime Database.
class CaregiverAuthService {
  CaregiverAuthService._internal();
  static final CaregiverAuthService instance = CaregiverAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _auth.signOut();

  /// Turns a raw FirebaseAuthException into a short, plain-language
  /// message suitable for display — Firebase's default messages are
  /// technical and inconsistent in tone across error codes.
  String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address doesn\'t look right.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
          return 'No account found with that email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists with that email.';
        case 'weak-password':
          return 'Choose a password with at least 6 characters.';
        case 'network-request-failed':
          return 'No internet connection. Please try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
