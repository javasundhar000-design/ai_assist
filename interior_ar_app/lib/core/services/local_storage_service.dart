import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/storage_keys.dart';
import '../../models/user_profile.dart';

/// Single entry point for all on-device persistence. The whole app is
/// offline-first (Section 27/35 of the spec), so every feature — profile,
/// settings, saved phrases, calibration — goes through this service
/// instead of touching Hive boxes directly.
///
/// Section 29 (privacy-first) — the boxes holding data that's sensitive
/// on its own (password hash, emergency contact phone number, biometric
/// gaze-calibration parameters) are AES-encrypted at rest. The encryption
/// key itself lives in the platform keystore/keychain via
/// flutter_secure_storage, not in the Hive file, so a copied .hive file
/// alone is useless without the device it was created on.
class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  static const _secureStorage = FlutterSecureStorage();
  static const _encryptionKeyStorageKey = 'ai_assist_hive_encryption_key';

  late Box _userBox;
  late Box _settingsBox;
  late Box _phrasesBox;
  late Box _notepadBox;
  late Box _calibrationBox;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();

    final cipher = HiveAesCipher(await _getOrCreateEncryptionKey());

    // Sensitive boxes: encrypted. Non-sensitive (settings, saved
    // communication phrases meant to be quickly reusable) stay
    // unencrypted for simplicity/performance — nothing in them
    // identifies or endangers the user on its own.
    _userBox = await Hive.openBox(StorageKeys.userBox, encryptionCipher: cipher);
    _calibrationBox = await Hive.openBox(StorageKeys.calibrationBox, encryptionCipher: cipher);
    _settingsBox = await Hive.openBox(StorageKeys.settingsBox);
    _phrasesBox = await Hive.openBox(StorageKeys.phrasesBox);
    _notepadBox = await Hive.openBox(StorageKeys.notepadBox);
    _initialized = true;
  }

  Future<List<int>> _getOrCreateEncryptionKey() async {
    final existing = await _secureStorage.read(key: _encryptionKeyStorageKey);
    if (existing != null) {
      return base64Url.decode(existing);
    }
    final key = Hive.generateSecureKey();
    await _secureStorage.write(key: _encryptionKeyStorageKey, value: base64UrlEncode(key));
    return key;
  }

  // ---------------- Optional cloud AI API key ----------------

  static const _aiApiKeyStorageKey = 'ai_assist_ai_vision_api_key';

  /// Stored via the platform keystore/keychain (flutter_secure_storage),
  /// never in Hive — an API key is a credential, not app data, and
  /// Section 29's privacy-first principle applies doubly to secrets.
  Future<void> saveAiApiKey(String apiKey) =>
      _secureStorage.write(key: _aiApiKeyStorageKey, value: apiKey);

  Future<String?> getAiApiKey() => _secureStorage.read(key: _aiApiKeyStorageKey);

  Future<void> clearAiApiKey() => _secureStorage.delete(key: _aiApiKeyStorageKey);

  // ---------------- User / session ----------------

  Future<void> saveUser(UserProfile user) async {
    await _userBox.put(StorageKeys.currentUser, user.toJson());
    await _userBox.put(StorageKeys.isLoggedIn, true);
  }

  UserProfile? getCurrentUser() {
    final raw = _userBox.get(StorageKeys.currentUser);
    if (raw == null) return null;
    return UserProfile.fromJson(Map<dynamic, dynamic>.from(raw));
  }

  bool get isLoggedIn => _userBox.get(StorageKeys.isLoggedIn, defaultValue: false);

  Future<void> logout() async {
    await _userBox.put(StorageKeys.isLoggedIn, false);
  }

  bool get isOnboarded =>
      _settingsBox.get(StorageKeys.isOnboarded, defaultValue: false);

  Future<void> setOnboarded() =>
      _settingsBox.put(StorageKeys.isOnboarded, true);

  /// Deletes everything for this device (Section 29 — "allow users to
  /// delete stored data"). Box content is cleared but the underlying
  /// encryption key is intentionally left alone — swapping it while a
  /// box is already open would break Hive's stored checksum for that
  /// box, and clearing the entries already satisfies "no data remains."
  Future<void> clearAllData() async {
    await _userBox.clear();
    await _settingsBox.clear();
    await _phrasesBox.clear();
    await _notepadBox.clear();
    await _calibrationBox.clear();
    await _secureStorage.delete(key: _aiApiKeyStorageKey);
  }

  // ---------------- Settings (generic get/set) ----------------

  T? getSetting<T>(String key, {T? defaultValue}) {
    if (!_initialized) return defaultValue;
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> setSetting<T>(String key, T value) async {
    if (!_initialized) return;
    await _settingsBox.put(key, value);
  }

  // ---------------- Phrases ----------------

  List<Map> getPhrases(String category) {
    final raw = _phrasesBox.get(category, defaultValue: <Map>[]);
    return List<Map>.from(raw as List);
  }

  Future<void> addPhrase(String category, Map phrase) async {
    final list = getPhrases(category);
    list.add(phrase);
    await _phrasesBox.put(category, list);
  }

  // ---------------- Notepad ----------------

  List<String> getRecentMessages() =>
      List<String>.from(_notepadBox.get('recent', defaultValue: <String>[]));

  Future<void> addRecentMessage(String message) async {
    final list = getRecentMessages();
    list.insert(0, message);
    if (list.length > 50) list.removeRange(50, list.length);
    await _notepadBox.put('recent', list);
  }

  // ---------------- Eye calibration ----------------

  Future<void> saveCalibration(Map<String, dynamic> calibrationData) =>
      _calibrationBox.put('calibration', calibrationData);

  Map? getCalibration() => _calibrationBox.get('calibration');

  bool get hasCalibration => _calibrationBox.containsKey('calibration');
}
