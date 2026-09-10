import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/quick_phrase.dart';

/// Local-only persistence (no login, no cloud) — appropriate for an
/// accessibility prototype. Stores:
/// - Notepad text
/// - Custom quick phrases
/// - Basic settings (speech rate, high-contrast mode, scan speed)
class StorageService {
  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  static const _kNotepadKey = 'notepad_text';
  static const _kPhrasesKey = 'quick_phrases';
  static const _kHighContrastKey = 'high_contrast';
  static const _kSpeechRateKey = 'speech_rate';
  static const _kScanSpeedKey = 'scan_speed_ms';

  Future<String> loadNotepad() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNotepadKey) ?? '';
  }

  Future<void> saveNotepad(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNotepadKey, text);
  }

  Future<List<QuickPhrase>> loadPhrases() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPhrasesKey);
    if (raw == null) return QuickPhrase.defaults();
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => QuickPhrase.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePhrases(List<QuickPhrase> phrases) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(phrases.map((p) => p.toJson()).toList());
    await prefs.setString(_kPhrasesKey, raw);
  }

  Future<bool> loadHighContrast() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHighContrastKey) ?? false;
  }

  Future<void> saveHighContrast(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHighContrastKey, value);
  }

  Future<double> loadSpeechRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kSpeechRateKey) ?? 0.5;
  }

  Future<void> saveSpeechRate(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kSpeechRateKey, value);
  }

  Future<int> loadScanSpeedMs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kScanSpeedKey) ?? 1500;
  }

  Future<void> saveScanSpeedMs(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kScanSpeedKey, value);
  }
}
