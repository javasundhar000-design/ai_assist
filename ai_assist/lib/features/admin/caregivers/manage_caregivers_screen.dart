import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/permission.dart';
import '../../../models/user_role.dart';
import '../../../widgets/permission_guard.dart';
import '../../../widgets/role_scaffold.dart';

/// Spec §20/§23: admin oversight of caregiver-user relationships.
class ManageCaregiversScreen extends StatelessWidget {
  const ManageCaregiversScreen({super.key});

  static const _links = [
    ('Priya Nair', 'Rahul Sharma', 'Son', 'Authorized'),
    ('Priya Nair', 'Sneha Sharma', 'Daughter', 'Authorized'),
    ('Arjun Verma', 'Vikram Sharma', 'Brother', 'Pending'),
  ];

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      required: Permission.manageCaregivers,
      child: RoleScaffold(
        role: UserRole.admin,
        currentIndex: 0,
        title: 'Manage Caregivers',
        body: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: _links.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final (caregiver, user, relation, status) = _links[i];
            final pending = status == 'Pending';
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                leading: const Icon(Icons.link_rounded, color: AppColors.caregiver),
                title: Text('$caregiver → $user'),
                subtitle: Text('Relationship: $relation'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (pending ? AppColors.warning : AppColors.success).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          color: pending ? AppColors.warning : AppColors.success, fontSize: 12)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
