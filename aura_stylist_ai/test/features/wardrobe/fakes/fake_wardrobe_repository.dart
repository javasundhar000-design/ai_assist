import 'dart:async';

import 'package:aura_stylist_ai/core/errors/failure.dart';
import 'package:aura_stylist_ai/core/utils/result.dart';
import 'package:aura_stylist_ai/features/wardrobe/domain/entities/saved_outfit.dart';
import 'package:aura_stylist_ai/features/wardrobe/domain/repositories/wardrobe_repository.dart';

/// In-memory `WardrobeRepository` fake — no shared_preferences, no
/// Firebase — same pattern as `FakeProfileRepository`/`FakeAuthRepository`.
class FakeWardrobeRepository implements WardrobeRepository {
  FakeWardrobeRepository({Map<String, List<SavedOutfit>>? seed})
      : _byUid = seed ?? {};

  final Map<String, List<SavedOutfit>> _byUid;
  final _controllers = <String, StreamController<List<SavedOutfit>>>{};

  StreamController<List<SavedOutfit>> _controllerFor(String uid) {
    return _controllers.putIfAbsent(uid, () {
      final controller = StreamController<List<SavedOutfit>>.broadcast();
      scheduleMicrotask(() => controller.add(_byUid[uid] ?? const []));
      return controller;
    });
  }

  void _emit(String uid) => _controllerFor(uid).add(List.of(_byUid[uid] ?? const []));

  @override
  Stream<List<SavedOutfit>> watchOutfits(String uid) => _controllerFor(uid).stream;

  @override
  Future<void> refreshFromRemote(String uid) async {}

  @override
  Future<Result<SavedOutfit>> saveOutfit(String uid, SavedOutfit outfit) async {
    final list = _byUid.putIfAbsent(uid, () => []);
    list.removeWhere((o) => o.id == outfit.id);
    list.add(outfit);
    _emit(uid);
    return Success(outfit);
  }

  @override
  Future<Result<SavedOutfit>> toggleFavorite(String uid, String outfitId) async {
    final list = _byUid[uid] ?? [];
    final index = list.indexWhere((o) => o.id == outfitId);
    if (index == -1) {
      return const Err(UnknownFailure('That outfit no longer exists.'));
    }
    final toggled = list[index].copyWith(isFavorite: !list[index].isFavorite);
    list[index] = toggled;
    _emit(uid);
    return Success(toggled);
  }

  @override
  Future<Result<void>> deleteOutfit(String uid, String outfitId) async {
    _byUid[uid]?.removeWhere((o) => o.id == outfitId);
    _emit(uid);
    return const Success(null);
  }
}
