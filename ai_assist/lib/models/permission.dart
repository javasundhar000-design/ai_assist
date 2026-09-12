/// Every capability in the app is gated behind one of these permissions.
///
/// Screens and widgets must NEVER check `role == UserRole.blind` directly.
/// They check `permissionService.has(Permission.readDocument)` instead. This
/// keeps role -> feature mapping in exactly one place
/// (see role_permission_map.dart) and lets the backend and frontend agree on
/// the same vocabulary.
enum Permission {
  // Blind / vision assistance
  readDocument,
  readMedicine,
  recognizeObject,
  recognizeCurrency,
  sceneUnderstanding,

  // Non-speaking / communication
  smartNotepad,
  wordSuggestions,
  sentenceSuggestions,

  // Motor-impaired / eye control
  eyeCalibration,
  eyeGaze,
  eyeControlledKeyboard,
  dwellSelection,
  wordPrediction,

  // Shared
  textToSpeech,

  // Caregiver
  viewLinkedUsers,
  viewAuthorizedInformation,
  monitorActivities,
  caregiverMonitoring,
  emergencyAlerts,
  communicateWithUser,

  // Admin
  manageUsers,
  manageCaregivers,
  manageRoles,
  monitorSystem;

  String get wireValue => name;

  static Permission fromWireValue(String value) =>
      Permission.values.firstWhere(
        (p) => p.name.toLowerCase() == value.toLowerCase(),
        orElse: () => throw ArgumentError('Unknown permission: $value'),
      );
}
