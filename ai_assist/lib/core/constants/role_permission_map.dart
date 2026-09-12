import '../../models/permission.dart';
import '../../models/user_role.dart';

/// The default permission set for each role.
///
/// IMPORTANT: this map is a client-side convenience/default only (e.g. to
/// render a dashboard optimistically before the network responds). The
/// user's *actual* permissions always come from the backend's JWT/profile
/// response after login (see AuthRepository), because the backend is the
/// only trusted source of authorization. Never grant access based solely on
/// this map — see PermissionService.
const Map<UserRole, Set<Permission>> kDefaultRolePermissions = {
  UserRole.blind: {
    Permission.readDocument,
    Permission.readMedicine,
    Permission.recognizeObject,
    Permission.recognizeCurrency,
    Permission.sceneUnderstanding,
    Permission.textToSpeech,
  },
  UserRole.nonSpeaking: {
    Permission.smartNotepad,
    Permission.wordSuggestions,
    Permission.sentenceSuggestions,
    Permission.textToSpeech,
  },
  UserRole.motorImpaired: {
    Permission.eyeCalibration,
    Permission.eyeGaze,
    Permission.eyeControlledKeyboard,
    Permission.dwellSelection,
    Permission.wordPrediction,
    Permission.textToSpeech,
  },
  UserRole.caregiver: {
    Permission.viewLinkedUsers,
    Permission.viewAuthorizedInformation,
    Permission.monitorActivities,
    Permission.caregiverMonitoring,
    Permission.emergencyAlerts,
    Permission.communicateWithUser,
  },
  UserRole.admin: {
    Permission.manageUsers,
    Permission.manageCaregivers,
    Permission.manageRoles,
    Permission.monitorSystem,
  },
};
