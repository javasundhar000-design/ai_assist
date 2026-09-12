/// The five accessibility roles supported by AI Assist.
///
/// This is the ONLY place role identity is defined. Every other part of the
/// app (routing, dashboards, permissions) derives behavior from this enum —
/// never from raw strings.
enum UserRole {
  blind,
  nonSpeaking,
  motorImpaired,
  caregiver,
  admin;

  /// Value sent to / received from the backend API.
  String get wireValue {
    switch (this) {
      case UserRole.blind:
        return 'BLIND';
      case UserRole.nonSpeaking:
        return 'NON_SPEAKING';
      case UserRole.motorImpaired:
        return 'MOTOR_IMPAIRED';
      case UserRole.caregiver:
        return 'CAREGIVER';
      case UserRole.admin:
        return 'ADMIN';
    }
  }

  static UserRole fromWireValue(String value) {
    switch (value.toUpperCase()) {
      case 'BLIND':
        return UserRole.blind;
      case 'NON_SPEAKING':
        return UserRole.nonSpeaking;
      case 'MOTOR_IMPAIRED':
        return UserRole.motorImpaired;
      case 'CAREGIVER':
        return UserRole.caregiver;
      case 'ADMIN':
        return UserRole.admin;
      default:
        throw ArgumentError('Unknown role from backend: $value');
    }
  }

  /// Human-readable label used in UI.
  String get label {
    switch (this) {
      case UserRole.blind:
        return 'Blind';
      case UserRole.nonSpeaking:
        return 'Non-Speaking';
      case UserRole.motorImpaired:
        return 'Motor-Impaired';
      case UserRole.caregiver:
        return 'Caregiver';
      case UserRole.admin:
        return 'Admin';
    }
  }

  /// Dashboard "mode" title shown under the app name.
  String get modeTitle {
    switch (this) {
      case UserRole.blind:
        return 'Blind Mode';
      case UserRole.nonSpeaking:
        return 'Non-Speaking Mode';
      case UserRole.motorImpaired:
        return 'Motor-Impaired Mode';
      case UserRole.caregiver:
        return 'Caregiver Mode';
      case UserRole.admin:
        return 'Admin Mode';
    }
  }

  /// Role-specific welcome line (section 50 of the spec).
  String get welcomeMessage {
    switch (this) {
      case UserRole.blind:
        return 'Your accessibility companion.';
      case UserRole.nonSpeaking:
        return 'Your voice matters.';
      case UserRole.motorImpaired:
        return 'Control your device with your eyes.';
      case UserRole.caregiver:
        return 'Supporting your loved ones.';
      case UserRole.admin:
        return 'Manage the AI Assist system.';
    }
  }

  /// Roles a user is allowed to self-select at registration.
  /// ADMIN is deliberately excluded — admin accounts are provisioned only by
  /// an existing admin or backend configuration (spec section 3 & 52).
  static List<UserRole> get selectableAtRegistration => [
        UserRole.blind,
        UserRole.nonSpeaking,
        UserRole.motorImpaired,
        UserRole.caregiver,
      ];

  /// Root path each role lands on immediately after login.
  String get homeRoute {
    switch (this) {
      case UserRole.blind:
        return '/blind/home';
      case UserRole.nonSpeaking:
        return '/non-speaking/home';
      case UserRole.motorImpaired:
        return '/motor/home';
      case UserRole.caregiver:
        return '/caregiver/home';
      case UserRole.admin:
        return '/admin/home';
    }
  }
}
