import 'dart:async';

import 'package:aura_stylist_ai/core/errors/failure.dart';
import 'package:aura_stylist_ai/core/utils/result.dart';
import 'package:aura_stylist_ai/features/auth/domain/entities/app_user.dart';
import 'package:aura_stylist_ai/features/auth/domain/repositories/auth_repository.dart';

/// In-memory fake used across auth tests so controllers/pages/router logic
/// can be verified without touching Firebase at all.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initialUser}) : _currentUser = initialUser {
    _controller = StreamController<AppUser?>.broadcast();
  }

  AppUser? _currentUser;
  late final StreamController<AppUser?> _controller;
  bool _rememberMe = true;

  /// Set by tests to force the next sign-in/register/etc. call to fail.
  Failure? failureToReturn;

  static const _testUser = AppUser(
    uid: 'test-uid',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: null,
    isGuest: false,
    emailVerified: true,
  );

  @override
  Stream<AppUser?> get authStateChanges =>
      Stream.multi((controller) {
        controller.add(_currentUser);
        final sub = _controller.stream.listen(controller.add);
        controller.onCancel = sub.cancel;
      });

  @override
  AppUser? get currentUser => _currentUser;

  void _signIn(AppUser user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Future<Result<AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (failureToReturn != null) return Err(failureToReturn!);
    final user = _testUser;
    _signIn(user);
    return Success(user);
  }

  @override
  Future<Result<AppUser>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (failureToReturn != null) return Err(failureToReturn!);
    final user = AppUser(
      uid: 'test-uid',
      email: email,
      displayName: displayName,
      photoUrl: null,
      isGuest: false,
      emailVerified: false,
    );
    _signIn(user);
    return Success(user);
  }

  @override
  Future<Result<AppUser>> signInWithGoogle() async {
    if (failureToReturn != null) return Err(failureToReturn!);
    _signIn(_testUser);
    return Success(_testUser);
  }

  @override
  Future<Result<AppUser>> signInAsGuest() async {
    if (failureToReturn != null) return Err(failureToReturn!);
    const guest = AppUser(
      uid: 'guest-uid',
      isGuest: true,
      emailVerified: false,
    );
    _signIn(guest);
    return const Success(guest);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    if (failureToReturn != null) return Err(failureToReturn!);
    return const Success(null);
  }

  @override
  Future<Result<void>> signOut() async {
    _currentUser = null;
    _controller.add(null);
    return const Success(null);
  }

  @override
  bool get rememberMe => _rememberMe;

  @override
  Future<void> setRememberMe(bool value) async => _rememberMe = value;

  @override
  Future<void> applyRememberMePreference() async {
    if (!_rememberMe && _currentUser != null) {
      await signOut();
      _rememberMe = true;
    }
  }
}
