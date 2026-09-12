/// Central runtime configuration.
///
/// AI Assist is fully self-contained on-device now — there is no backend
/// server. Two consequences of that:
///
/// 1. User accounts, roles, and permissions are persisted locally (see
///    LocalAuthRepository) instead of behind a REST API.
/// 2. AI features (OCR, object/medicine/currency recognition, scene
///    understanding, text suggestions) call OpenRouter directly from the
///    device, using a key the person enters themselves in
///    Settings -> AI Configuration, stored via flutter_secure_storage
///    (Keystore/Keychain-backed).
///
/// SECURITY NOTE: embedding a shared OpenRouter key at build time (e.g. via
/// --dart-define) would expose it to anyone who decompiles a distributed
/// APK. Letting each person supply and store their own key on their own
/// device avoids that — the key never ships inside the binary. If you later
/// need to distribute this app widely without asking each user for their
/// own key, put a thin proxy (even a single serverless function) back in
/// front of OpenRouter; don't bake a shared key into the app.
class AppConfig {
  AppConfig._();

  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';

  /// No specific model is hardcoded. "openrouter/auto" is OpenRouter's own
  /// meta-router — it picks a suitable underlying model per request (vision
  /// or text) automatically. The person can override this with any model
  /// slug they want in Settings -> AI Configuration.
  static const String defaultOpenRouterModel = 'openrouter/auto';

  /// Simulated "thinking" delay for the built-in demo responses used when no
  /// OpenRouter key has been configured yet, so loading states are visible.
  static const Duration mockLatency = Duration(milliseconds: 700);
}
