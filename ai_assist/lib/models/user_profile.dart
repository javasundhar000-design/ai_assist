import 'emergency_contact.dart';
import 'user_role.dart';

class UserProfile {
  final String id;
  final String name;
  final UserRole role;
  final List<EmergencyContact> emergencyContacts;

  /// Only set for role == admin. Plaintext local storage is acceptable
  /// for a prototype ONLY — see README security note before shipping.
  final String? adminPin;

  const UserProfile({
    required this.id,
    required this.name,
    required this.role,
    this.emergencyContacts = const [],
    this.adminPin,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        role: UserRole.fromName(json['role'] as String),
        emergencyContacts: (json['emergencyContacts'] as List<dynamic>? ?? [])
            .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
            .toList(),
        adminPin: json['adminPin'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'emergencyContacts': emergencyContacts.map((c) => c.toJson()).toList(),
        'adminPin': adminPin,
      };
}
