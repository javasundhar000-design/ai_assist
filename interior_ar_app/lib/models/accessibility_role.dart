/// The set of accessibility profiles a user can select at registration.
/// A user may hold multiple roles at once (e.g. BLIND + NON_SPEAKING),
/// which is why [UserProfile.accessibilityProfiles] is a Set, not a
/// single value, and why the dashboard router can mount more than one
/// module simultaneously.
enum AccessibilityRole {
  blind,
  lowVision,
  nonSpeaking,
  motorImpaired;

  String get storageValue => name;

  static AccessibilityRole fromStorage(String value) {
    return AccessibilityRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => AccessibilityRole.blind,
    );
  }

  String get label {
    switch (this) {
      case AccessibilityRole.blind:
        return 'Blind';
      case AccessibilityRole.lowVision:
        return 'Low Vision';
      case AccessibilityRole.nonSpeaking:
        return 'Non-Speaking';
      case AccessibilityRole.motorImpaired:
        return 'Motor Impairment';
    }
  }

  String get groupLabel {
    switch (this) {
      case AccessibilityRole.blind:
      case AccessibilityRole.lowVision:
        return 'Vision Support';
      case AccessibilityRole.nonSpeaking:
        return 'Communication Support';
      case AccessibilityRole.motorImpaired:
        return 'Motor Support';
    }
  }

  /// Which top-level module this role activates. Vision-family roles both
  /// map to the Vision Assistant; multiple roles can map to the same
  /// module without duplicating it on the dashboard.
  AppModule get module {
    switch (this) {
      case AccessibilityRole.blind:
      case AccessibilityRole.lowVision:
        return AppModule.vision;
      case AccessibilityRole.nonSpeaking:
        return AppModule.communication;
      case AccessibilityRole.motorImpaired:
        return AppModule.eyeControl;
    }
  }
}

enum AppModule { vision, communication, eyeControl }

extension AccessibilityRoleSet on Set<AccessibilityRole> {
  Set<AppModule> get activeModules => map((r) => r.module).toSet();

  bool get hasVision =>
      contains(AccessibilityRole.blind) || contains(AccessibilityRole.lowVision);
  bool get hasCommunication => contains(AccessibilityRole.nonSpeaking);
  bool get hasEyeControl => contains(AccessibilityRole.motorImpaired);
}
