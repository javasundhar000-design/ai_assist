import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_role.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/role_scaffold.dart';

class MotorHistoryScreen extends StatelessWidget {
  const MotorHistoryScreen({super.key});

  static const _entries = [
    ('Message Built', '"I need help please"', 'Today, 11:02 AM'),
    ('Eye Calibration', 'Completed', 'Today, 09:00 AM'),
  ];

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      role: UserRole.motorImpaired,
      currentIndex: 1,
      title: 'History',
      body: _entries.isEmpty
          ? const EmptyState(message: 'No activity yet.')
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final (title, detail, time) = _entries[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    leading: const Icon(Icons.history_rounded, color: AppColors.motor),
                    title: Text(title),
                    subtitle: Text(detail),
                    trailing: Text(time, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                );
              },
            ),
    );
  }
}
