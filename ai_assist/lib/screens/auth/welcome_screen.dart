import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'caregiver_auth_screen.dart';
import 'join_family_screen.dart';

/// First screen a new device sees. Two clearly different entry points,
/// distinguished by icon + role color rather than by repeating the same
/// card shape twice — a caregiver sets accounts up, a member's device
/// just needs to join with a code someone else already generated.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Container(
                height: 84,
                width: 84,
                decoration: BoxDecoration(
                  color: AppColors.signal,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.accessibility_new, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 28),
              Text('AI Assist', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 10),
              Text(
                'One app, set up the right way for the person using it — '
                'reading, speaking, and getting help, made simple.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.65),
                    ),
              ),
              const Spacer(flex: 3),
              _EntryRow(
                icon: Icons.admin_panel_settings,
                color: AppColors.roleAdmin,
                title: 'I\'m a caregiver',
                subtitle: 'Set up members, watch for emergency alerts.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CaregiverAuthScreen()),
                ),
              ),
              const SizedBox(height: 14),
              _EntryRow(
                icon: Icons.groups,
                color: AppColors.signal,
                title: 'I\'m joining a family',
                subtitle: 'Someone gave you a 6-character code to enter.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JoinFamilyScreen()),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EntryRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.mist),
          ),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 3),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}
