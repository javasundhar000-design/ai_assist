/// Base class for all handled application errors. UI layers should catch
/// this type and show `message` directly — it is always user-friendly.
/// Never let a raw platform/plugin exception reach a widget.
sealed class AppException implements Exception {
  final String message;
  final Object? cause;
  const AppException(this.message, {this.cause});

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.cause});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

class CameraException extends AppException {
  const CameraException(super.message, {super.cause});
}

class VisionException extends AppException {
  const VisionException(super.message, {super.cause});
}

class ArException extends AppException {
  const ArException(super.message, {super.cause});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause});
}

/// Maps common FirebaseAuth error codes to friendly copy.
/// Called from AuthRepository — keeps UI free of Firebase-specific strings.
String friendlyAuthMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return 'That email address looks invalid.';
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
      return 'Please choose a stronger password (6+ characters).';
    case 'network-request-failed':
      return 'Network unavailable. Please check your connection.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
