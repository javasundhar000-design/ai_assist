import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_role.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/role_scaffold.dart';

class _HistoryEntry {
  final String title;
  final String detail;
  final String when;
  final IconData icon;
  const _HistoryEntry(this.title, this.detail, this.when, this.icon);
}

/// Spec §33: users only ever see their OWN history. The backend enforces
/// this by scoping the `/history` query to the authenticated user's id —
/// this screen simply renders whatever it's given.
class BlindHistoryScreen extends StatelessWidget {
  const BlindHistoryScreen({super.key});

  static const _entries = [
    _HistoryEntry('Medicine Recognition', 'Paracetamol 500 mg', 'Today, 10:24 AM',
        Icons.medication_rounded),
    _HistoryEntry('Text Recognition', 'SATHYABAMA UNIVERSITY', 'Today, 09:15 AM',
        Icons.menu_book_rounded),
    _HistoryEntry('Object Recognition', 'Chair', 'Yesterday, 02:22 PM',
        Icons.category_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      role: UserRole.blind,
      currentIndex: 1,
      title: 'History',
      body: _entries.isEmpty
          ? const ErrorView(message: 'No activity yet.')
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final e = _entries[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(e.icon, color: AppColors.primary),
                    ),
                    title: Text(e.title),
                    subtitle: Text(e.detail),
                    trailing: Text(e.when, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                );
              },
            ),
    );
  }
}
