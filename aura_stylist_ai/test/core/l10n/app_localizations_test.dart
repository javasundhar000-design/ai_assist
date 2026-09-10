import 'package:aura_stylist_ai/core/l10n/app_locale.dart';
import 'package:aura_stylist_ai/core/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('t() returns the localized string for each supported locale', () {
    expect(
      const AppLocalizations(AppLocale.en).t(AppL10nKeys.settingsTitle),
      'Settings',
    );
    expect(
      const AppLocalizations(AppLocale.ta).t(AppL10nKeys.settingsTitle),
      'அமைப்புகள்',
    );
    expect(
      const AppLocalizations(AppLocale.hi).t(AppL10nKeys.settingsTitle),
      'सेटिंग्स',
    );
  });

  test('every key defined in AppL10nKeys has a translation in all three locales', () {
    final keys = [
      AppL10nKeys.dashboardSubtitleReady,
      AppL10nKeys.dashboardSubtitleGuest,
      AppL10nKeys.navSmartMirror,
      AppL10nKeys.navAiRecommendations,
      AppL10nKeys.navWardrobe,
      AppL10nKeys.navFavorites,
      AppL10nKeys.navOutfitHistory,
      AppL10nKeys.navSettings,
      AppL10nKeys.logout,
      AppL10nKeys.wardrobeTitle,
      AppL10nKeys.wardrobeTabAll,
      AppL10nKeys.wardrobeTabFavorites,
      AppL10nKeys.wardrobeTabHistory,
      AppL10nKeys.wardrobeSearchHint,
      AppL10nKeys.wardrobeEmptyAll,
      AppL10nKeys.wardrobeEmptyFavorites,
      AppL10nKeys.wardrobeEmptyHistory,
      AppL10nKeys.wardrobeOccasionAll,
      AppL10nKeys.wardrobeOccasionLabel,
      AppL10nKeys.wardrobeSortLabel,
      AppL10nKeys.wearThisButton,
      AppL10nKeys.settingsTitle,
      AppL10nKeys.settingsAppearance,
      AppL10nKeys.settingsThemeLight,
      AppL10nKeys.settingsThemeDark,
      AppL10nKeys.settingsThemeSystem,
      AppL10nKeys.settingsLanguage,
      AppL10nKeys.settingsSmartMirror,
      AppL10nKeys.settingsGestureRecognition,
      AppL10nKeys.settingsGestureRecognitionSubtitle,
      AppL10nKeys.settingsVoiceConfirmation,
      AppL10nKeys.settingsVoiceConfirmationSubtitle,
      AppL10nKeys.settingsDefaultCamera,
      AppL10nKeys.settingsCameraFront,
      AppL10nKeys.settingsCameraBack,
      AppL10nKeys.settingsAccount,
      AppL10nKeys.settingsSignOut,
      AppL10nKeys.settingsAbout,
      AppL10nKeys.save,
      AppL10nKeys.cancel,
    ];

    for (final locale in AppLocale.values) {
      final l10n = AppLocalizations(locale);
      for (final key in keys) {
        // t() falls back to the key itself when missing — a real
        // translation should never equal its own key.
        expect(l10n.t(key), isNot(equals(key)), reason: '$locale missing "$key"');
      }
    }
  });

  test('AppLocaleMeta.fromLanguageCode resolves supported codes and rejects others', () {
    expect(AppLocaleMeta.fromLanguageCode('ta'), AppLocale.ta);
    expect(AppLocaleMeta.fromLanguageCode('hi'), AppLocale.hi);
    expect(AppLocaleMeta.fromLanguageCode('en'), AppLocale.en);
    expect(AppLocaleMeta.fromLanguageCode('fr'), isNull);
    expect(AppLocaleMeta.fromLanguageCode(null), isNull);
  });
}
