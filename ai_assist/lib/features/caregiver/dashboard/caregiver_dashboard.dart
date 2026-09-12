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

class CaregiverDashboard extends ConsumerWidget {
  const CaregiverDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final firstName = (user?.fullName ?? 'there').split(' ').first;

    return RoleScaffold(
      role: UserRole.caregiver,
      currentIndex: 0,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          DashboardHeader(role: UserRole.caregiver, firstName: firstName),
          const SizedBox(height: AppSpacing.lg),
          Text('Stay connected', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          FeatureCard(
            title: 'Linked Users',
            subtitle: 'View people who have authorized you',
            icon: Icons.people_alt_rounded,
            permission: Permission.viewLinkedUsers,
            accentColor: AppColors.caregiver,
            onTap: () => context.push('/caregiver/users'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FeatureCard(
            title: 'Emergency Alerts',
            subtitle: 'Falls, low battery, and emergency requests',
            icon: Icons.notifications_active_rounded,
            permission: Permission.emergencyAlerts,
            accentColor: AppColors.alert,
            onTap: () => context.push('/caregiver/alerts'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FeatureCard(
            title: 'Shared Activities',
            subtitle: 'Monitor authorized recent activity',
            icon: Icons.timeline_rounded,
            permission: Permission.monitorActivities,
            accentColor: AppColors.caregiver,
            onTap: () => context.push('/caregiver/activities'),
          ),
        ],
      ),
    );
  }
}
