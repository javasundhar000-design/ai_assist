import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/permission.dart';
import '../../../models/user.dart';
import '../../../models/user_role.dart';
import '../../../widgets/permission_guard.dart';
import '../../../widgets/role_scaffold.dart';

class _AdminUserRow {
  final String name;
  final String email;
  final UserRole role;
  UserStatus status;
  final String lastActive;

  _AdminUserRow(this.name, this.email, this.role, this.status, this.lastActive);
}

/// Spec §24: searchable list, with role changes and deactivation requiring
/// explicit confirmation. Never displays a password or token — the backend
/// response for this endpoint doesn't include them in the first place.
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _search = TextEditingController();

  final List<_AdminUserRow> _users = [
    _AdminUserRow('Alex Johnson', 'alex@example.com', UserRole.blind, UserStatus.active, '5m ago'),
    _AdminUserRow('Sam Rivera', 'sam@example.com', UserRole.nonSpeaking, UserStatus.active,
        '1h ago'),
    _AdminUserRow(
        'Taylor Kim', 'taylor@example.com', UserRole.motorImpaired, UserStatus.active, '3h ago'),
    _AdminUserRow(
        'Priya Nair', 'priya@example.com', UserRole.caregiver, UserStatus.active, 'Yesterday'),
  ];

  List<_AdminUserRow> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _users;
    return _users
        .where((u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _confirmToggleStatus(_AdminUserRow user) async {
    final activate = user.status == UserStatus.inactive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activate ? 'Activate user?' : 'Deactivate user?'),
        content: Text(
            '${activate ? 'Activate' : 'Deactivate'} ${user.name}\'s account? '
            '${activate ? 'They will regain access immediately.' : 'They will lose access immediately.'}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(activate ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // In production this calls PATCH /admin/users/{id}/status, which the
      // backend re-validates against the caller's own manageUsers
      // permission (spec §43) regardless of what this button shows.
      setState(() {
        user.status = activate ? UserStatus.active : UserStatus.inactive;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      required: Permission.manageUsers,
      child: RoleScaffold(
        role: UserRole.admin,
        currentIndex: 1,
        title: 'Manage Users',
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search by name or email',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final u = _filtered[i];
                    final active = u.status == UserStatus.active;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(u.name,
                                          style:
                                              const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                      Text(u.email, style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.forRole(u.role).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppRadius.chip),
                                  ),
                                  child: Text(u.role.label,
                                      style: TextStyle(
                                          color: AppColors.forRole(u.role),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Icon(active ? Icons.check_circle : Icons.pause_circle,
                                    size: 16, color: active ? AppColors.success : AppColors.warning),
                                const SizedBox(width: 4),
                                Text(active ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                        color: active ? AppColors.success : AppColors.warning,
                                        fontSize: 13)),
                                const Spacer(),
                                Text('Last active: ${u.lastActive}',
                                    style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(onPressed: () {}, child: const Text('View')),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: OutlinedButton(onPressed: () {}, child: const Text('Edit')),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: FilledButton.tonal(
                                    onPressed: () => _confirmToggleStatus(u),
                                    child: Text(active ? 'Deactivate' : 'Activate'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
