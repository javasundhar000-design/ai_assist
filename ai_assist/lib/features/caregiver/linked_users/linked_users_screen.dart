import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/permission.dart';
import '../../../models/realtime_models.dart';
import '../../../models/user_role.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/permission_guard.dart';
import '../../../widgets/role_scaffold.dart';

/// Spec §21: a caregiver only ever sees users linked to *them*. Now backed
/// by a live stream from `/caregiver_links/{caregiverUid}` — updates appear
/// automatically the moment the underlying data changes, no manual refresh.
/// Falls back to an explanatory empty state if Firebase isn't configured
/// (see linkedUsersProvider in core/providers.dart).
class LinkedUsersScreen extends ConsumerWidget {
  const LinkedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedUsersAsync = ref.watch(linkedUsersProvider);
    final firebaseReady = ref.watch(firebaseReadyProvider);

    return PermissionGuard(
      required: Permission.viewLinkedUsers,
      child: RoleScaffold(
        role: UserRole.caregiver,
        currentIndex: 1,
        title: 'Linked Users',
        body: !firebaseReady
            ? const EmptyState(
                icon: Icons.cloud_off_outlined,
                message: 'Live caregiver data needs Firebase set up — see FIREBASE_SETUP.md. '
                    'Running in local demo mode, so this list is empty for now.',
              )
            : linkedUsersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ErrorView(
                  message: 'Could not load linked users.',
                  onRetry: () => ref.invalidate(linkedUsersProvider),
                ),
                data: (users) => users.isEmpty
                    ? const EmptyState(message: 'No linked users yet.')
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) => _LinkedUserCard(user: users[i]),
                      ),
              ),
      ),
    );
  }
}

class _LinkedUserCard extends StatelessWidget {
  final CaregiverLinkedUser user;
  const _LinkedUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.caregiver.withValues(alpha: 0.15),
          child: Text(user.name.isNotEmpty ? user.name[0] : '?',
              style: const TextStyle(color: AppColors.caregiver)),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(user.relationship),
        trailing: _PresenceBadge(status: user.status, label: user.lastActiveLabel),
      ),
    );
  }
}

class _PresenceBadge extends StatelessWidget {
  final String status;
  final String? label;
  const _PresenceBadge({required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String text;
    late final IconData icon;
    switch (status) {
      case 'online':
        color = AppColors.success;
        text = 'Online';
        icon = Icons.circle;
        break;
      case 'recent':
        color = AppColors.warning;
        text = label ?? 'Recently active';
        icon = Icons.schedule;
        break;
      default:
        color = AppColors.textSecondary;
        text = 'Offline';
        icon = Icons.circle_outlined;
    }
    // Never rely on color alone (spec §31) — icon + text label always pair
    // with the color.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(height: 2),
        Text(text, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
