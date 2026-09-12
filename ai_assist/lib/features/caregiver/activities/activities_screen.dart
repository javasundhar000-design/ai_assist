import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/permission.dart';
import '../../../models/user_role.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/permission_guard.dart';
import '../../../widgets/role_scaffold.dart';

/// Spec §20/§33: caregivers only see activity explicitly shared/authorized
/// by the linked user — the backend scopes this to caregiver_links, this
/// screen just renders the (already-authorized) feed.
class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  static const _activities = [
    ('Rahul Sharma', 'Completed medicine recognition', 'Today, 08:10 AM'),
    ('Sneha Sharma', 'Used Smart Notepad', 'Today, 07:40 AM'),
  ];

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      required: Permission.monitorActivities,
      child: RoleScaffold(
        role: UserRole.caregiver,
        currentIndex: 0,
        title: 'Shared Activities',
        body: _activities.isEmpty
            ? const EmptyState(message: 'No shared activity yet.')
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _activities.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final (name, action, time) = _activities[i];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                      leading: const Icon(Icons.timeline_rounded, color: AppColors.caregiver),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(action),
                      trailing: Text(time, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
