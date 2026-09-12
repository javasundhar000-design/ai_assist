import 'package:flutter/material.dart';
import '../../../core/constants/role_permission_map.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/permission.dart';
import '../../../models/user_role.dart';
import '../../../widgets/permission_guard.dart';
import '../../../widgets/role_scaffold.dart';

/// Spec §25/§26: read-only view of the role -> permission map used to build
/// dynamic dashboards. In production this reads/writes the backend's
/// role_permissions table; the client always re-derives dashboards from
/// whatever it returns rather than this local constant.
class ManageRolesScreen extends StatelessWidget {
  const ManageRolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      required: Permission.manageRoles,
      child: RoleScaffold(
        role: UserRole.admin,
        currentIndex: 0,
        title: 'Manage Roles',
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            for (final role in UserRole.values)
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.forRole(role).withValues(alpha: 0.15),
                    child: Icon(Icons.badge_rounded, color: AppColors.forRole(role)),
                  ),
                  title: Text(role.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${kDefaultRolePermissions[role]?.length ?? 0} permissions'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final p in kDefaultRolePermissions[role] ?? <Permission>{})
                            Chip(label: Text(p.name)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
