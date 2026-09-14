import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_role.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/role_scaffold.dart';

/// Same per-user history stream as BlindHistoryScreen (spec §33: scoped to
/// the logged-in user's own uid regardless of role). Currently only vision
/// tasks call recordHistory() — wire calibration/message-building into
/// RealtimeDataService.recordHistory() too if you want those to show up
/// here as well.
class MotorHistoryScreen extends ConsumerWidget {
  const MotorHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final firebaseReady = ref.watch(firebaseReadyProvider);

    return RoleScaffold(
      role: UserRole.motorImpaired,
      currentIndex: 1,
      title: 'History',
      body: !firebaseReady
          ? const EmptyState(
              icon: Icons.cloud_off_outlined,
              message: 'History needs Firebase set up — see FIREBASE_SETUP.md.',
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
                      itemBuilder: (context, i) {
                        final entry = entries[i];
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(AppSpacing.md),
                            leading: const Icon(Icons.history_rounded, color: AppColors.motor),
                            title: Text(entry.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: Text(DateFormat('MMM d, h:mm a').format(entry.createdAt),
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
