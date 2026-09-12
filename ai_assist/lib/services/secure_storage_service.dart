import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps platform secure storage (Keychain on iOS, Keystore-backed
/// EncryptedSharedPreferences on Android).
///
/// With no backend, there's no JWT to store. This now holds two things:
///  - the id of whoever is currently logged in (so the app can restore a
///    session on relaunch without re-prompting for a password)
///  - the OpenRouter API key the person enters in Settings -> AI
///    Configuration, which is what lets AI features call OpenRouter
///    directly from the device without a key ever being baked into the
///    compiled app (see app_config.dart for why that distinction matters).
class SecureStorageService {
  static const _sessionUserIdKey = 'ai_assist_session_user_id';
  static const _openRouterKeyKey = 'ai_assist_openrouter_key';
  static const _openRouterModelKey = 'ai_assist_openrouter_model';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<void> saveSessionUserId(String userId) =>
      _storage.write(key: _sessionUserIdKey, value: userId);

  Future<String?> getSessionUserId() => _storage.read(key: _sessionUserIdKey);

  Future<void> clearSession() => _storage.delete(key: _sessionUserIdKey);

  Future<void> saveOpenRouterKey(String key) =>
      _storage.write(key: _openRouterKeyKey, value: key);

  Future<String?> getOpenRouterKey() => _storage.read(key: _openRouterKeyKey);

  Future<void> clearOpenRouterKey() => _storage.delete(key: _openRouterKeyKey);

  /// Optional model override (e.g. "anthropic/claude-3.5-sonnet",
  /// "google/gemini-2.0-flash-001"). If unset, callers fall back to
  /// AppConfig.defaultOpenRouterModel ("openrouter/auto"), which lets
  /// OpenRouter pick a suitable model automatically — no model is hardcoded.
  Future<void> saveOpenRouterModel(String model) =>
      _storage.write(key: _openRouterModelKey, value: model);

  Future<String?> getOpenRouterModel() => _storage.read(key: _openRouterModelKey);

  Future<void> clearOpenRouterModel() => _storage.delete(key: _openRouterModelKey);
}
