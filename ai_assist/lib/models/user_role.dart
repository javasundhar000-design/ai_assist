import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Every registered person in AI Assist has exactly one role.
/// The role determines which mode(s) they see after logging in —
/// this is the core of the role-based access control (RBAC) for the app.
enum UserRole {
  blind,
  nonSpeaking,
  motor,
  admin;

  String get label {
    switch (this) {
      case UserRole.blind:
        return 'Blind';
      case UserRole.nonSpeaking:
        return 'Non-Speaking';
      case UserRole.motor:
        return 'Motor-Impaired';
      case UserRole.admin:
        return 'Admin / Caregiver';
    }
  }

  String get description {
    switch (this) {
      case UserRole.blind:
        return 'Gets Blind Mode only: camera-based reading, object and scene description.';
      case UserRole.nonSpeaking:
        return 'Gets Non-Speaking Mode only: notepad, quick phrases, text-to-speech.';
      case UserRole.motor:
        return 'Gets Motor Mode only: single-switch scanning grid.';
      case UserRole.admin:
        return 'Manages registered members and monitors emergency alerts. Requires a PIN.';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.blind:
        return Icons.remove_red_eye;
      case UserRole.nonSpeaking:
        return Icons.chat_bubble;
      case UserRole.motor:
        return Icons.touch_app;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  Color get color {
    switch (this) {
      case UserRole.blind:
        return AppColors.roleBlind;
      case UserRole.nonSpeaking:
        return AppColors.roleNonSpeaking;
      case UserRole.motor:
        return AppColors.roleMotor;
      case UserRole.admin:
        return AppColors.roleAdmin;
    }
  }

  static UserRole fromName(String name) =>
      UserRole.values.firstWhere((r) => r.name == name, orElse: () => UserRole.blind);
}
