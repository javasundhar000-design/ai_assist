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

class NonSpeakingDashboard extends ConsumerWidget {
  const NonSpeakingDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final firstName = (user?.fullName ?? 'there').split(' ').first;

    return RoleScaffold(
      role: UserRole.nonSpeaking,
      currentIndex: 0,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          DashboardHeader(role: UserRole.nonSpeaking, firstName: firstName),
          const SizedBox(height: AppSpacing.lg),
          Text('Communicate your way', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          FeatureCard(
            title: 'Smart Notepad',
            subtitle: 'Type, get suggestions, and speak your message',
            icon: Icons.edit_note_rounded,
            permission: Permission.smartNotepad,
            accentColor: AppColors.communication,
            onTap: () => context.push('/non-speaking/notepad'),
          ),
        ],
      ),
    );
  }
}
