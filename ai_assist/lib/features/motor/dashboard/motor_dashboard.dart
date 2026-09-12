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

class MotorDashboard extends ConsumerWidget {
  const MotorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final firstName = (user?.fullName ?? 'there').split(' ').first;

    return RoleScaffold(
      role: UserRole.motorImpaired,
      currentIndex: 0,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          DashboardHeader(role: UserRole.motorImpaired, firstName: firstName),
          const SizedBox(height: AppSpacing.lg),
          Text('Eye control tools', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          FeatureCard(
            title: 'Eye Calibration',
            subtitle: 'Calibrate gaze tracking for your device',
            icon: Icons.remove_red_eye_outlined,
            permission: Permission.eyeCalibration,
            accentColor: AppColors.motor,
            onTap: () => context.push('/motor/calibration'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FeatureCard(
            title: 'Eye-Controlled Keyboard',
            subtitle: 'Type using gaze and dwell selection',
            icon: Icons.keyboard_alt_outlined,
            permission: Permission.eyeControlledKeyboard,
            accentColor: AppColors.motor,
            onTap: () => context.push('/motor/keyboard'),
          ),
        ],
      ),
    );
  }
}
