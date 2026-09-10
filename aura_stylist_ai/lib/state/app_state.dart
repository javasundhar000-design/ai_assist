import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

/// Single source of truth for anything that needs to survive navigation
/// and app restarts. Screens read via `context.watch<AppState>()` /
/// `context.read<AppState>()` and call mutator methods — every mutator
/// persists immediately so the app behaves like a real product, not a
/// mockup with local setState() that resets on relaunch.
class AppState extends ChangeNotifier {
  final StorageService _storage;
  static const _uuid = Uuid();

  AppState(this._storage) {
    _load();
  }

  // --- Auth ---
  String? _email;
  bool get isLoggedIn => _email != null;
  String? get email => _email;

  // --- Wardrobe ---
  final List<WardrobeItem> _wardrobe = [];
  List<WardrobeItem> get wardrobe => List.unmodifiable(_wardrobe);

  // --- Outfits: the seed catalog (MockData.outfits) + anything the user built ---
  final List<Outfit> _customOutfits = [];
  List<Outfit> get allOutfits => [...MockData.outfits, ..._customOutfits];
  Outfit? outfitById(String id) => allOutfits.firstWhereOrNull((o) => o.id == id);

  // --- History ---
  final List<HistoryEntry> _history = [];
  List<HistoryEntry> get history => List.unmodifiable(_history);

  bool _ready = false;
  bool get isReady => _ready;

  void _load() {
    _email = _storage.loggedInEmail;

    final wardrobeJson = _storage.wardrobeJson;
    _wardrobe
      ..clear()
      ..addAll(wardrobeJson != null ? wardrobeJson.map(WardrobeItem.fromJson) : MockData.seedWardrobe());
    if (wardrobeJson == null) _persistWardrobe();

    final customOutfitsJson = _storage.customOutfitsJson;
    _customOutfits
      ..clear()
      ..addAll((customOutfitsJson ?? const []).map(Outfit.fromJson));

    final favIds = _storage.favoriteIds;
    for (final outfit in allOutfits) {
      outfit.isFavorite = favIds.contains(outfit.id);
    }

    final historyJson = _storage.historyJson;
    _history
      ..clear()
      ..addAll(historyJson != null ? historyJson.map(HistoryEntry.fromJson) : MockData.seedHistory());
    if (historyJson == null) _persistHistory();

    _ready = true;
    notifyListeners();
  }

  // ---------------- Auth ----------------

  /// Validates and "signs in". There's no real backend here, so any
  /// well-formed email/password combination succeeds — this is where a
  /// real API call would go. Returns an error string, or null on success.
  Future<String?> login({required String email, required String password}) async {
    final emailOk = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email.trim());
    if (!emailOk) return 'Enter a valid email address';
    if (password.length < 6) return 'Password must be at least 6 characters';

    await Future.delayed(const Duration(milliseconds: 600)); // simulated network round-trip
    _email = email.trim();
    await _storage.setLoggedInEmail(_email);
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _email = null;
    await _storage.setLoggedInEmail(null);
    notifyListeners();
  }

  // ---------------- Favorites ----------------

  void toggleFavorite(Outfit outfit) {
    outfit.isFavorite = !outfit.isFavorite;
    final ids = allOutfits.where((o) => o.isFavorite).map((o) => o.id).toSet();
    _storage.setFavoriteIds(ids);
    notifyListeners();
  }

  List<Outfit> get favoriteOutfits => allOutfits.where((o) => o.isFavorite).toList();

  // ---------------- Wardrobe ----------------

  Future<void> addWardrobeItem({
    required String name,
    required String category,
    required IconData icon,
    required Color color,
    String? imagePath,
  }) async {
    _wardrobe.insert(
      0,
      WardrobeItem(
        id: _uuid.v4(),
        name: name,
        category: category,
        icon: icon,
        color: color,
        imagePath: imagePath,
      ),
    );
    await _persistWardrobe();
    notifyListeners();
  }

  Future<void> removeWardrobeItem(String id) async {
    _wardrobe.removeWhere((w) => w.id == id);
    await _persistWardrobe();
    notifyListeners();
  }

  void toggleWardrobeFavorite(String id) {
    final item = _wardrobe.firstWhere((w) => w.id == id);
    item.isFavorite = !item.isFavorite;
    _persistWardrobe();
    notifyListeners();
  }

  Future<void> _persistWardrobe() => _storage.setWardrobeJson(_wardrobe.map((w) => w.toJson()).toList());

  // ---------------- Custom outfits ----------------

  /// Builds a real outfit out of the user's own wardrobe pieces. There's no
  /// vision model running here, so the fashion score is a simple, honest
  /// heuristic (more coordinated pieces → higher score) rather than a fake
  /// precise-looking AI number — swap `_scoreFor` for a real API call
  /// when one exists.
  Future<Outfit> createOutfit({
    required String name,
    required String occasion,
    required List<String> wardrobeItemIds,
    required Color accent,
  }) async {
    // Use the first selected piece that actually has a real photo as the
    // outfit's cover image, so outfits built from photographed items show
    // a real picture instead of a generic placeholder.
    String? coverImagePath;
    for (final id in wardrobeItemIds) {
      final match = _wardrobe.where((w) => w.id == id);
      if (match.isNotEmpty && match.first.imagePath != null) {
        coverImagePath = match.first.imagePath;
        break;
      }
    }

    final outfit = Outfit(
      id: 'custom_${_uuid.v4()}',
      name: name,
      occasion: occasion,
      fashionScore: _scoreFor(wardrobeItemIds.length),
      imageAsset: '',
      accent: accent,
      isCustom: true,
      wardrobeItemIds: wardrobeItemIds,
      coverImagePath: coverImagePath,
    );
    _customOutfits.insert(0, outfit);
    await _persistCustomOutfits();
    notifyListeners();
    return outfit;
  }

  Future<void> deleteCustomOutfit(String id) async {
    _customOutfits.removeWhere((o) => o.id == id);
    final ids = allOutfits.where((o) => o.isFavorite).map((o) => o.id).toSet();
    await Future.wait([_persistCustomOutfits(), _storage.setFavoriteIds(ids)]);
    notifyListeners();
  }

  int _scoreFor(int itemCount) => (78 + itemCount * 4).clamp(0, 97);

  Future<void> _persistCustomOutfits() => _storage.setCustomOutfitsJson(_customOutfits.map((o) => o.toJson()).toList());

  // ---------------- History ----------------

  Future<void> recordLookCaptured(String outfitId, {String? capturedImagePath}) async {
    _history.insert(0, HistoryEntry(outfitId: outfitId, timestamp: DateTime.now(), capturedImagePath: capturedImagePath));
    await _persistHistory();
    notifyListeners();
  }

  Future<void> _persistHistory() => _storage.setHistoryJson(_history.map((h) => h.toJson()).toList());
}
