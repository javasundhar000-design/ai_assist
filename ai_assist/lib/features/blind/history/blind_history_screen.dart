import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/realtime_models.dart';
import '../../../models/user_role.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/role_scaffold.dart';

IconData _iconFor(String taskType) {
  switch (taskType) {
    case 'ocr':
      return Icons.menu_book_rounded;
    case 'medicine':
      return Icons.medication_rounded;
    case 'object':
      return Icons.category_rounded;
    case 'currency':
      return Icons.payments_rounded;
    case 'scene':
      return Icons.explore_rounded;
    default:
      return Icons.history_rounded;
  }
}

/// Spec §33: users only ever see their OWN history, scoped by the Realtime
/// Database rules to `/ai_history/{their own uid}`. Live-updates the moment
/// a new AI operation is recorded (see vision_capture_screen.dart).
class BlindHistoryScreen extends ConsumerWidget {
  const BlindHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final firebaseReady = ref.watch(firebaseReadyProvider);

    return RoleScaffold(
      role: UserRole.blind,
      currentIndex: 1,
      title: 'History',
      body: !firebaseReady
          ? const EmptyState(
              icon: Icons.cloud_off_outlined,
              message: 'History needs Firebase set up — see FIREBASE_SETUP.md. Running in local '
                  'demo mode, so nothing is saved between sessions yet.',
            )
          : historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorView(
                message: 'Could not load history.',
                onRetry: () => ref.invalidate(historyProvider),
              ),
              data: (entries) => entries.isEmpty
                  ? const EmptyState(message: 'No activity yet.')
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) => _HistoryCard(entry: entries[i]),
                    ),
            ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(_iconFor(entry.taskType), color: AppColors.primary),
        ),
        title: Text(entry.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text(DateFormat('MMM d, h:mm a').format(entry.createdAt),
            style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
