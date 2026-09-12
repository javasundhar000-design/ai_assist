import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/permission.dart';
import '../../../models/user_role.dart';
import '../../../widgets/permission_guard.dart';
import '../../../widgets/role_scaffold.dart';

enum _Presence { online, offline, recentlyActive }

class _LinkedUser {
  final String name;
  final String relationship;
  final _Presence presence;
  final String? lastActiveLabel;
  const _LinkedUser(this.name, this.relationship, this.presence, [this.lastActiveLabel]);
}

/// Spec §21: a caregiver only ever sees users who explicitly authorized the
/// relationship. This list is what the backend's
/// `GET /caregiver/users` returns after verifying the caregiver_links table
/// — this screen never accepts or displays arbitrary user IDs.
class LinkedUsersScreen extends StatelessWidget {
  const LinkedUsersScreen({super.key});

  static const _users = [
    _LinkedUser('Rahul Sharma', 'Son', _Presence.online),
    _LinkedUser('Sneha Sharma', 'Daughter', _Presence.recentlyActive, 'Last active 2 hours ago'),
    _LinkedUser('Vikram Sharma', 'Brother', _Presence.offline),
  ];

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      required: Permission.viewLinkedUsers,
      child: RoleScaffold(
        role: UserRole.caregiver,
        currentIndex: 1,
        title: 'Linked Users',
        body: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: _users.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final u = _users[i];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.caregiver.withValues(alpha: 0.15),
                  child: Text(u.name[0], style: const TextStyle(color: AppColors.caregiver)),
                ),
                title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(u.relationship),
                trailing: _PresenceBadge(presence: u.presence, label: u.lastActiveLabel),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PresenceBadge extends StatelessWidget {
  final _Presence presence;
  final String? label;
  const _PresenceBadge({required this.presence, this.label});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String text;
    late final IconData icon;
    switch (presence) {
      case _Presence.online:
        color = AppColors.success;
        text = 'Online';
        icon = Icons.circle;
        break;
      case _Presence.recentlyActive:
        color = AppColors.warning;
        text = label ?? 'Recently active';
        icon = Icons.schedule;
        break;
      case _Presence.offline:
        color = AppColors.textSecondary;
        text = 'Offline';
        icon = Icons.circle_outlined;
        break;
    }
    // Never rely on color alone (spec §31) — icon + text label always pair
    // with the color.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(height: 2),
        Text(text, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
