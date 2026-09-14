import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/permission.dart';
import '../../../models/realtime_models.dart';
import '../../../models/user_role.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/permission_guard.dart';
import '../../../widgets/role_scaffold.dart';

String _label(String type) {
  switch (type) {
    case 'fallDetected':
      return 'Fall Detected';
    case 'lowBattery':
      return 'Low Battery';
    case 'emergencyRequest':
      return 'Emergency Request';
    case 'deviceOffline':
      return 'Device Offline';
    default:
      return type;
  }
}

IconData _icon(String type) {
  switch (type) {
    case 'fallDetected':
      return Icons.warning_amber_rounded;
    case 'lowBattery':
      return Icons.battery_alert_rounded;
    case 'emergencyRequest':
      return Icons.sos_rounded;
    case 'deviceOffline':
      return Icons.wifi_off_rounded;
    default:
      return Icons.notifications_rounded;
  }
}

/// Spec §22, now backed by a live stream from `/alerts/{caregiverUid}` —
/// a new alert (e.g. a real fall-detection pipeline pushing data in) would
/// appear here the instant it's written, with no polling or refresh needed.
/// That's the actual payoff of using the *Realtime* Database specifically.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final firebaseReady = ref.watch(firebaseReadyProvider);

    return PermissionGuard(
      required: Permission.emergencyAlerts,
      child: RoleScaffold(
        role: UserRole.caregiver,
        currentIndex: 2,
        title: 'Emergency Alerts',
        body: !firebaseReady
            ? const EmptyState(
                icon: Icons.cloud_off_outlined,
                message: 'Live alerts need Firebase set up — see FIREBASE_SETUP.md. Running in '
                    'local demo mode, so this list is empty for now.',
              )
            : alertsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ErrorView(
                  message: 'Could not load alerts.',
                  onRetry: () => ref.invalidate(alertsProvider),
                ),
                data: (alerts) => alerts.isEmpty
                    ? const EmptyState(
                        icon: Icons.notifications_off_outlined, message: 'No alerts right now.')
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: alerts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) => _AlertCard(alert: alerts[i]),
                      ),
              ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final CaregiverAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isCritical = alert.type == 'fallDetected' || alert.type == 'emergencyRequest';
    final timeLabel = DateFormat('MMM d, h:mm a').format(alert.createdAt);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: CircleAvatar(
          backgroundColor: (isCritical ? AppColors.alert : AppColors.warning).withValues(alpha: 0.12),
          child: Icon(_icon(alert.type), color: isCritical ? AppColors.alert : AppColors.warning),
        ),
        title: Text(_label(alert.type), style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${alert.userName} · $timeLabel · ${alert.status}'),
        trailing: FilledButton.tonal(onPressed: () {}, child: const Text('View')),
      ),
    );
  }
}
