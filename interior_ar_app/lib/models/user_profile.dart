import 'accessibility_role.dart';

/// The local user model. Everything lives on-device (this is an
/// offline-first app with no backend) so this model is stored as a JSON
/// map inside a Hive box rather than via hive type adapters — that keeps
/// the schema easy to evolve without codegen churn.
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final Set<AccessibilityRole> accessibilityProfiles;
  final String preferredLanguage;
  final String emergencyContact;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.accessibilityProfiles,
    required this.preferredLanguage,
    required this.emergencyContact,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    Set<AccessibilityRole>? accessibilityProfiles,
    String? preferredLanguage,
    String? emergencyContact,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash,
      accessibilityProfiles: accessibilityProfiles ?? this.accessibilityProfiles,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'accessibilityProfiles':
            accessibilityProfiles.map((r) => r.storageValue).toList(),
        'preferredLanguage': preferredLanguage,
        'emergencyContact': emergencyContact,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<dynamic, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      accessibilityProfiles: (json['accessibilityProfiles'] as List)
          .map((v) => AccessibilityRole.fromStorage(v as String))
          .toSet(),
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
      emergencyContact: json['emergencyContact'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
