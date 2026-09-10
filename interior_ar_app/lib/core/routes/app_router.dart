import 'package:flutter/material.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/authentication/registration_screen.dart';
import '../../features/authentication/login_screen.dart';
import '../../features/home/dashboard_router_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/accessibility_settings_screen.dart';
import '../../features/vision/vision_home_screen.dart';
import '../../features/vision/book_reader/book_reader_screen.dart';
import '../../features/vision/medicine/medicine_reader_screen.dart';
import '../../features/vision/camera/vision_reader_screen.dart';
import '../../features/vision/object_detection/object_assistant_screen.dart';
import '../../features/vision/currency/currency_assistant_screen.dart';
import '../../features/vision/scene/scene_assistant_screen.dart';
import '../../features/communication/communication_home_screen.dart';
import '../../features/communication/notepad/smart_notepad_screen.dart';
import '../../features/communication/phrases/quick_phrases_screen.dart';
import '../../features/eye_control/eye_control_home_screen.dart';
import '../../features/eye_control/calibration/eye_calibration_screen.dart';

/// All named routes in one place (Section 30). Every screen the spec
/// calls out is reachable by name, so `Navigator.pushNamed` calls stay
/// readable and the dashboard router can jump straight to a module.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const registration = '/registration';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const profile = '/profile';
  static const settings = '/settings';

  // Vision
  static const visionHome = '/vision';
  static const visionReader = '/vision/reader';
  static const medicineReader = '/vision/medicine';
  static const bookReader = '/vision/book-reader';
  static const objectAssistant = '/vision/objects';
  static const currencyAssistant = '/vision/currency';
  static const sceneAssistant = '/vision/scene';

  // Communication
  static const communicationHome = '/communication';
  static const smartNotepad = '/communication/notepad';
  static const quickPhrases = '/communication/phrases';

  // Eye control
  static const eyeControlHome = '/eye-control';
  static const eyeCalibration = '/eye-control/calibration';

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    registration: (_) => const RegistrationScreen(),
    login: (_) => const LoginScreen(),
    dashboard: (_) => const DashboardRouterScreen(),
    profile: (_) => const ProfileScreen(),
    settings: (_) => const AccessibilitySettingsScreen(),
    visionHome: (_) => const VisionHomeScreen(),
    visionReader: (_) => const VisionReaderScreen(),
    medicineReader: (_) => const MedicineReaderScreen(),
    bookReader: (_) => const BookReaderScreen(),
    objectAssistant: (_) => const ObjectAssistantScreen(),
    currencyAssistant: (_) => const CurrencyAssistantScreen(),
    sceneAssistant: (_) => const SceneAssistantScreen(),
    communicationHome: (_) => const CommunicationHomeScreen(),
    smartNotepad: (_) => const SmartNotepadScreen(),
    quickPhrases: (_) => const QuickPhrasesScreen(),
    eyeControlHome: (_) => const EyeControlHomeScreen(),
    eyeCalibration: (_) => const EyeCalibrationScreen(),
  };
}
