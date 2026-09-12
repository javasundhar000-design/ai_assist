import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/permission.dart';
import '../../../models/user_role.dart';
import '../../../widgets/dashboard_header.dart';
import '../../../widgets/feature_card.dart';
import '../../../widgets/role_scaffold.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final firstName = (user?.fullName ?? 'there').split(' ').first;

    return RoleScaffold(
      role: UserRole.admin,
      currentIndex: 0,
      title: 'AI Assist Admin',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          DashboardHeader(role: UserRole.admin, firstName: firstName),
          const SizedBox(height: AppSpacing.lg),
          Text('System management', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          FeatureCard(
            title: 'Manage Users',
            subtitle: 'Create, activate, deactivate, and edit users',
            icon: Icons.manage_accounts_rounded,
            permission: Permission.manageUsers,
            onTap: () => context.push('/admin/users'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FeatureCard(
            title: 'Manage Caregivers',
            subtitle: 'Review and manage caregiver-user relationships',
            icon: Icons.diversity_3_rounded,
            permission: Permission.manageCaregivers,
            onTap: () => context.push('/admin/caregivers'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FeatureCard(
            title: 'Manage Roles',
            subtitle: 'Configure role permissions',
            icon: Icons.admin_panel_settings_rounded,
            permission: Permission.manageRoles,
            onTap: () => context.push('/admin/roles'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FeatureCard(
            title: 'Monitor System',
            subtitle: 'System health, AI service status, uptime',
            icon: Icons.monitor_heart_rounded,
            permission: Permission.monitorSystem,
            onTap: () => context.push('/admin/system'),
          ),
        ],
      ),
    );
  }
}
