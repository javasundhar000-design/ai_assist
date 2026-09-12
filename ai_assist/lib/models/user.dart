import 'permission.dart';
import 'user_role.dart';

enum UserStatus { active, inactive }

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final UserStatus status;
  final Set<Permission> permissions;
  final DateTime? lastLoginAt;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.permissions,
    this.lastLoginAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      role: UserRole.fromWireValue(json['role'] as String),
      status: (json['status'] as String?)?.toUpperCase() == 'INACTIVE'
          ? UserStatus.inactive
          : UserStatus.active,
      // Permissions ALWAYS come from the backend response — the client
      // never invents its own permission set for a logged-in user.
      permissions: (json['permissions'] as List<dynamic>? ?? [])
          .map((p) => Permission.fromWireValue(p as String))
          .toSet(),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role.wireValue,
        'status': status == UserStatus.active ? 'ACTIVE' : 'INACTIVE',
        'permissions': permissions.map((p) => p.wireValue).toList(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
      };
}
