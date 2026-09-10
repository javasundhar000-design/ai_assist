/// Centralized copy so screens never hard-code user-facing strings.
/// Swap this out later for a full localization (intl) setup — the
/// architecture already isolates strings behind a single import.
class AppStrings {
  AppStrings._();

  // Splash
  static const appName = 'AI ASSIST';
  static const appTagline = 'Technology that understands how you communicate.';

  // Onboarding
  static const onboardTitle1 = 'SEE THE WORLD THROUGH AI';
  static const onboardDesc1 =
      'Read and understand the world around you using your phone camera and intelligent assistance.';
  static const onboardTitle2 = 'EXPRESS YOURSELF';
  static const onboardDesc2 =
      'Type what you want to say and let your phone speak for you.';
  static const onboardTitle3 = 'CONTROL WITH YOUR EYES';
  static const onboardDesc3 =
      'Use gaze-based interaction when traditional touch input is difficult.';
  static const getStarted = 'GET STARTED';

  // Errors (user-safe, never technical)
  static const errOcrGeneric =
      "I couldn't read the text. Please move the camera closer and try again.";
  static const errEyeTracking =
      "I can't detect your eyes clearly. Try improving the lighting.";
  static const errCameraPermission =
      'Camera access is required for this feature.';
  static const errGeneric =
      'Something went wrong. Please try again.';

  // Safety
  static const medicineDisclaimer =
      'Always verify medicine information with a doctor or pharmacist.';
}
