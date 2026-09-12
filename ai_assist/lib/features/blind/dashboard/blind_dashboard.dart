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

class BlindDashboard extends ConsumerWidget {
  const BlindDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final firstName = (user?.fullName ?? 'there').split(' ').first;
    const accent = AppColors.primary;

    return RoleScaffold(
      role: UserRole.blind,
      currentIndex: 0,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          DashboardHeader(role: UserRole.blind, firstName: firstName),
          const SizedBox(height: AppSpacing.lg),
          Text('What would you like to do?',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          FeatureCard(
            title: 'Read Book / Document',
            subtitle: 'Capture text and have it read aloud',
            icon: Icons.menu_book_rounded,
            permission: Permission.readDocument,
            accentColor: accent,
            onTap: () => context.push('/blind/read-document'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FeatureCard(
            title: 'Read Medicine',
            subtitle: 'Identify medicine name, strength, and expiry',
            icon: Icons.medication_rounded,
            permission: Permission.readMedicine,
            accentColor: accent,
            onTap: () => context.push('/blind/read-medicine'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FeatureCard(
            title: 'Recognize Object',
            subtitle: 'Identify objects around you',
            icon: Icons.category_rounded,
            permission: Permission.recognizeObject,
            accentColor: accent,
            onTap: () => context.push('/blind/object-recognition'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FeatureCard(
            title: 'Recognize Currency',
            subtitle: 'Identify currency notes and denomination',
            icon: Icons.payments_rounded,
            permission: Permission.recognizeCurrency,
            accentColor: accent,
            onTap: () => context.push('/blind/currency-recognition'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FeatureCard(
            title: 'Understand Surroundings',
            subtitle: 'Describe your environment and obstacles',
            icon: Icons.explore_rounded,
            permission: Permission.sceneUnderstanding,
            accentColor: accent,
            onTap: () => context.push('/blind/scene-understanding'),
          ),
        ],
      ),
    );
  }
}
