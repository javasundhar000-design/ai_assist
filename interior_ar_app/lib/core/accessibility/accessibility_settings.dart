import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/storage_keys.dart';
import '../services/local_storage_service.dart';
import '../services/text_to_speech_service.dart';
import '../theme/app_theme.dart';

/// The single source of truth for every adjustable accessibility setting
/// (Section 26). Screens read this via [accessibilitySettingsProvider]
/// instead of reading Hive directly, so a change here — e.g. font size —
/// propagates to the whole app instantly.
@immutable
class AccessibilitySettingsState {
  final AppThemeMode themeMode;
  final double fontScale; // 1.0 = default, up to 2.0
  final bool hapticEnabled;
  final bool reduceMotion;
  final double speechRate; // 0.1 - 1.0
  final double speechPitch; // 0.5 - 2.0
  final String speechLanguage;
  final int dwellTimeMs;
  final double gazeSensitivity; // 0.0 - 1.0
  final bool blinkSelectionEnabled;

  const AccessibilitySettingsState({
    this.themeMode = AppThemeMode.light,
    this.fontScale = 1.0,
    this.hapticEnabled = true,
    this.reduceMotion = false,
    this.speechRate = 0.5,
    this.speechPitch = 1.0,
    this.speechLanguage = 'en-US',
    this.dwellTimeMs = 1200,
    this.gazeSensitivity = 0.5,
    this.blinkSelectionEnabled = false,
  });

  AccessibilitySettingsState copyWith({
    AppThemeMode? themeMode,
    double? fontScale,
    bool? hapticEnabled,
    bool? reduceMotion,
    double? speechRate,
    double? speechPitch,
    String? speechLanguage,
    int? dwellTimeMs,
    double? gazeSensitivity,
    bool? blinkSelectionEnabled,
  }) {
    return AccessibilitySettingsState(
      themeMode: themeMode ?? this.themeMode,
      fontScale: fontScale ?? this.fontScale,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      speechLanguage: speechLanguage ?? this.speechLanguage,
      dwellTimeMs: dwellTimeMs ?? this.dwellTimeMs,
      gazeSensitivity: gazeSensitivity ?? this.gazeSensitivity,
      blinkSelectionEnabled: blinkSelectionEnabled ?? this.blinkSelectionEnabled,
    );
  }
}

class AccessibilitySettingsNotifier extends StateNotifier<AccessibilitySettingsState> {
  final LocalStorageService _storage = LocalStorageService.instance;

  AccessibilitySettingsNotifier() : super(const AccessibilitySettingsState()) {
    _load();
  }

  void _load() {
    final themeName = _storage.getSetting<String>(StorageKeys.themeMode);
    state = AccessibilitySettingsState(
      themeMode: AppThemeMode.values.firstWhere(
        (m) => m.name == themeName,
        orElse: () => AppThemeMode.light,
      ),
      fontScale: _storage.getSetting<double>(StorageKeys.fontScale, defaultValue: 1.0) ?? 1.0,
      hapticEnabled: _storage.getSetting<bool>(StorageKeys.hapticEnabled, defaultValue: true) ?? true,
      reduceMotion: _storage.getSetting<bool>(StorageKeys.reduceMotion, defaultValue: false) ?? false,
      speechRate: _storage.getSetting<double>(StorageKeys.speechRate, defaultValue: 0.5) ?? 0.5,
      speechPitch: _storage.getSetting<double>(StorageKeys.speechPitch, defaultValue: 1.0) ?? 1.0,
      speechLanguage: _storage.getSetting<String>(StorageKeys.speechLanguage, defaultValue: 'en-US') ?? 'en-US',
      dwellTimeMs: _storage.getSetting<int>(StorageKeys.dwellTimeMs, defaultValue: 1200) ?? 1200,
      gazeSensitivity: _storage.getSetting<double>(StorageKeys.gazeSensitivity, defaultValue: 0.5) ?? 0.5,
      blinkSelectionEnabled: _storage.getSetting<bool>(StorageKeys.blinkSelectionEnabled, defaultValue: false) ?? false,
    );
    TextToSpeechService.instance.setSpeed(state.speechRate).catchError((_) {});
    TextToSpeechService.instance.setPitch(state.speechPitch).catchError((_) {});
    TextToSpeechService.instance.setLanguage(state.speechLanguage).catchError((_) {});
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _storage.setSetting(StorageKeys.themeMode, mode.name);
  }

  Future<void> setFontScale(double scale) async {
    state = state.copyWith(fontScale: scale);
    await _storage.setSetting(StorageKeys.fontScale, scale);
  }

  Future<void> setHapticEnabled(bool enabled) async {
    state = state.copyWith(hapticEnabled: enabled);
    await _storage.setSetting(StorageKeys.hapticEnabled, enabled);
  }

  Future<void> setReduceMotion(bool enabled) async {
    state = state.copyWith(reduceMotion: enabled);
    await _storage.setSetting(StorageKeys.reduceMotion, enabled);
  }

  Future<void> setSpeechRate(double rate) async {
    state = state.copyWith(speechRate: rate);
    await _storage.setSetting(StorageKeys.speechRate, rate);
    await TextToSpeechService.instance.setSpeed(rate);
  }

  Future<void> setSpeechPitch(double pitch) async {
    state = state.copyWith(speechPitch: pitch);
    await _storage.setSetting(StorageKeys.speechPitch, pitch);
    await TextToSpeechService.instance.setPitch(pitch);
  }

  Future<void> setSpeechLanguage(String lang) async {
    state = state.copyWith(speechLanguage: lang);
    await _storage.setSetting(StorageKeys.speechLanguage, lang);
    await TextToSpeechService.instance.setLanguage(lang);
  }

  Future<void> setDwellTimeMs(int ms) async {
    state = state.copyWith(dwellTimeMs: ms);
    await _storage.setSetting(StorageKeys.dwellTimeMs, ms);
  }

  Future<void> setGazeSensitivity(double value) async {
    state = state.copyWith(gazeSensitivity: value);
    await _storage.setSetting(StorageKeys.gazeSensitivity, value);
  }

  Future<void> setBlinkSelectionEnabled(bool enabled) async {
    state = state.copyWith(blinkSelectionEnabled: enabled);
    await _storage.setSetting(StorageKeys.blinkSelectionEnabled, enabled);
  }
}

final accessibilitySettingsProvider =
    StateNotifierProvider<AccessibilitySettingsNotifier, AccessibilitySettingsState>(
  (ref) => AccessibilitySettingsNotifier(),
);
