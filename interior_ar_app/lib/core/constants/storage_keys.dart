/// Hive box + key names in one place so no screen ever hard-codes a string
/// key (a classic source of silent bugs in offline-first apps).
class StorageKeys {
  StorageKeys._();

  // Boxes
  static const userBox = 'user_box';
  static const settingsBox = 'settings_box';
  static const phrasesBox = 'phrases_box';
  static const notepadBox = 'notepad_box';
  static const calibrationBox = 'calibration_box';

  // Keys
  static const currentUser = 'current_user';
  static const isOnboarded = 'is_onboarded';
  static const isLoggedIn = 'is_logged_in';

  // Settings keys
  static const fontScale = 'font_scale';
  static const themeMode = 'theme_mode'; // light | dark | highContrast
  static const hapticEnabled = 'haptic_enabled';
  static const reduceMotion = 'reduce_motion';
  static const speechRate = 'speech_rate';
  static const speechPitch = 'speech_pitch';
  static const speechLanguage = 'speech_language';
  static const dwellTimeMs = 'dwell_time_ms';
  static const gazeSensitivity = 'gaze_sensitivity';
  static const blinkSelectionEnabled = 'blink_selection_enabled';
}
