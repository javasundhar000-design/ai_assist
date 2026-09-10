import 'emergency_contact.dart';
import 'user_role.dart';

/// A registered member of a family/household — always role Blind,
/// Non-Speaking, or Motor. Admin/Caregiver is a real Firebase Auth
/// account (see CaregiverAuthService), not a member profile, since
/// caregivers need actual account security while members (who may not
/// be able to type a password) log in by picking their name on a
/// trusted family device instead — see FamilyService for how that works.
class UserProfile {
  final String id;
  final String name;
  final UserRole role;
  final List<EmergencyContact> emergencyContacts;

  const UserProfile({
    required this.id,
    required this.name,
    required this.role,
    this.emergencyContacts = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        role: UserRole.fromName(json['role'] as String),
        emergencyContacts: _parseContacts(json['emergencyContacts']),
      );

  // Firebase Realtime Database can return a stored array back as either a
  // List (the common case) or a Map with numeric string keys (this
  // happens when the array has gaps, or in some edge cases with the REST
  // fallback) — handle both so a display quirk never turns into a crash.
  static List<EmergencyContact> _parseContacts(dynamic raw) {
    if (raw == null) return [];
    final Iterable<dynamic> items = raw is Map ? raw.values : (raw as List);
    return items
        .whereType<Object>()
        .map((e) => EmergencyContact.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'emergencyContacts': emergencyContacts.map((c) => c.toJson()).toList(),
      };
}
