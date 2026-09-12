import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/user_role.dart';

/// Renders the "WHO AM I / WHAT MODE / WHAT CAN I DO" header required by
/// spec §51 — every dashboard opens with this so the user immediately
/// understands their context.
class DashboardHeader extends StatelessWidget {
  final UserRole role;
  final String firstName;

  const DashboardHeader({super.key, required this.role, required this.firstName});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forRole(role);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'AI Assist · ${role.modeTitle}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: accent, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Hello, $firstName!', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(role.welcomeMessage, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
