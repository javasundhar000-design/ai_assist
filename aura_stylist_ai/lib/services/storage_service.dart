import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Small persistence helper. Everything the app needs to survive a restart
/// (auth session, favorites, wardrobe, history) goes through here as JSON,
/// so there's exactly one place that talks to disk.
class StorageService {
  static const _kLoggedInEmail = 'aura.auth.email';
  static const _kFavoriteIds = 'aura.favorites';
  static const _kWardrobe = 'aura.wardrobe';
  static const _kHistory = 'aura.history';
  static const _kCustomOutfits = 'aura.custom_outfits';

  final SharedPreferences _prefs;
  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Auth session ---
  String? get loggedInEmail => _prefs.getString(_kLoggedInEmail);
  Future<void> setLoggedInEmail(String? email) async {
    if (email == null) {
      await _prefs.remove(_kLoggedInEmail);
    } else {
      await _prefs.setString(_kLoggedInEmail, email);
    }
  }

  // --- Favorites (set of outfit ids) ---
  Set<String> get favoriteIds => (_prefs.getStringList(_kFavoriteIds) ?? const []).toSet();
  Future<void> setFavoriteIds(Set<String> ids) => _prefs.setStringList(_kFavoriteIds, ids.toList());

  // --- Wardrobe (list of JSON-encoded items) ---
  List<Map<String, dynamic>>? get wardrobeJson {
    final raw = _prefs.getString(_kWardrobe);
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> setWardrobeJson(List<Map<String, dynamic>> items) => _prefs.setString(_kWardrobe, jsonEncode(items));

  // --- History (list of JSON-encoded entries) ---
  List<Map<String, dynamic>>? get historyJson {
    final raw = _prefs.getString(_kHistory);
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> setHistoryJson(List<Map<String, dynamic>> items) => _prefs.setString(_kHistory, jsonEncode(items));

  // --- Custom outfits (list of JSON-encoded outfits built from wardrobe items) ---
  List<Map<String, dynamic>>? get customOutfitsJson {
    final raw = _prefs.getString(_kCustomOutfits);
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> setCustomOutfitsJson(List<Map<String, dynamic>> items) =>
      _prefs.setString(_kCustomOutfits, jsonEncode(items));
}
