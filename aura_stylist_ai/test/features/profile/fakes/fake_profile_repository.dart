import 'dart:io';

import 'package:aura_stylist_ai/core/errors/failure.dart';
import 'package:aura_stylist_ai/core/utils/result.dart';
import 'package:aura_stylist_ai/features/profile/domain/entities/user_profile.dart';
import 'package:aura_stylist_ai/features/profile/domain/repositories/profile_repository.dart';

/// In-memory fake used across profile/dashboard tests.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({Map<String, UserProfile>? seed})
      : _profiles = seed ?? {};

  final Map<String, UserProfile> _profiles;
  final _controllers = <String, List<void Function(UserProfile?)>>{};

  /// Set by tests to force the next write to fail.
  Failure? failureToReturn;

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return Stream.multi((controller) {
      controller.add(_profiles[uid]);
      final listeners = _controllers.putIfAbsent(uid, () => []);
      void listener(UserProfile? p) => controller.add(p);
      listeners.add(listener);
      controller.onCancel = () => listeners.remove(listener);
    });
  }

  void _notify(String uid) {
    final listeners = _controllers[uid];
    if (listeners == null) return;
    for (final l in List.of(listeners)) {
      l(_profiles[uid]);
    }
  }

  @override
  Future<Result<UserProfile>> ensureProfileExists({
    required String uid,
    String? email,
    String? displayName,
  }) async {
    final existing = _profiles[uid];
    if (existing != null) return Success(existing);

    final profile = UserProfile(
      uid: uid,
      name: displayName ?? email?.split('@').first ?? 'Stylist',
      email: email,
      createdAt: DateTime.now(),
    );
    _profiles[uid] = profile;
    _notify(uid);
    return Success(profile);
  }

  @override
  Future<Result<UserProfile>> updateProfile(UserProfile profile) async {
    if (failureToReturn != null) return Err(failureToReturn!);
    _profiles[profile.uid] = profile;
    _notify(profile.uid);
    return Success(profile);
  }

  @override
  Future<Result<String>> uploadProfileImage({
    required String uid,
    required File file,
  }) async {
    if (failureToReturn != null) return Err(failureToReturn!);
    const url = 'https://example.com/fake-photo.jpg';
    final existing = _profiles[uid];
    if (existing != null) {
      _profiles[uid] = existing.copyWith(photoUrl: url);
      _notify(uid);
    }
    return const Success(url);
  }
}
