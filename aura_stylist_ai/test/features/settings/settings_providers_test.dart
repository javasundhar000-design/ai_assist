import 'package:aura_stylist_ai/core/l10n/app_locale.dart';
import 'package:aura_stylist_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:aura_stylist_ai/features/settings/data/settings_local_preferences.dart';
import 'package:aura_stylist_ai/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
  });

  test('gestureSettingsProvider defaults to enabled and persists changes', () async {
    expect(container.read(gestureSettingsProvider), isTrue);

    await container.read(gestureSettingsProvider.notifier).setEnabled(false);
    expect(container.read(gestureSettingsProvider), isFalse);

    // A fresh container reading the same underlying prefs sees the persisted value.
    final prefs = container.read(sharedPreferencesProvider);
    final freshContainer = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(freshContainer.dispose);
    expect(freshContainer.read(gestureSettingsProvider), isFalse);
  });

  test('voiceSettingsProvider defaults to enabled and persists changes', () async {
    expect(container.read(voiceSettingsProvider), isTrue);
    await container.read(voiceSettingsProvider.notifier).setEnabled(false);
    expect(container.read(voiceSettingsProvider), isFalse);
  });

  test('cameraSettingsProvider defaults to front and can switch to back', () async {
    expect(container.read(cameraSettingsProvider), PreferredCameraLens.front);
    await container.read(cameraSettingsProvider.notifier).setLens(PreferredCameraLens.back);
    expect(container.read(cameraSettingsProvider), PreferredCameraLens.back);
  });

  test('localeProvider persists an explicit choice across containers', () async {
    await container.read(localeProvider.notifier).setLocale(AppLocale.ta);
    expect(container.read(localeProvider), AppLocale.ta);

    final prefs = container.read(sharedPreferencesProvider);
    final freshContainer = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(freshContainer.dispose);
    expect(freshContainer.read(localeProvider), AppLocale.ta);
  });

  test('SettingsLocalPreferences.themeMode round-trips light/dark/system', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = SettingsLocalPreferences(await SharedPreferences.getInstance());

    expect(prefs.themeMode, ThemeMode.system);
    await prefs.setThemeMode(ThemeMode.dark);
    expect(prefs.themeMode, ThemeMode.dark);
    await prefs.setThemeMode(ThemeMode.light);
    expect(prefs.themeMode, ThemeMode.light);
  });
}
