import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/permission.dart';
import '../../../models/user_role.dart';
import '../../../widgets/permission_guard.dart';
import '../../../widgets/role_scaffold.dart';

enum _AlertType { fallDetected, lowBattery, emergencyRequest, deviceOffline }

class _Alert {
  final String user;
  final _AlertType type;
  final String time;
  final String status;
  const _Alert(this.user, this.type, this.time, this.status);
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  static const _alerts = [
    _Alert('Rahul Sharma', _AlertType.fallDetected, '2 minutes ago', 'Open'),
    _Alert('Sneha Sharma', _AlertType.lowBattery, '40 minutes ago', 'Acknowledged'),
    _Alert('Vikram Sharma', _AlertType.deviceOffline, 'Yesterday', 'Resolved'),
  ];

  String _label(_AlertType t) {
    switch (t) {
      case _AlertType.fallDetected:
        return 'Fall Detected';
      case _AlertType.lowBattery:
        return 'Low Battery';
      case _AlertType.emergencyRequest:
        return 'Emergency Request';
      case _AlertType.deviceOffline:
        return 'Device Offline';
    }
  }

  IconData _icon(_AlertType t) {
    switch (t) {
      case _AlertType.fallDetected:
        return Icons.warning_amber_rounded;
      case _AlertType.lowBattery:
        return Icons.battery_alert_rounded;
      case _AlertType.emergencyRequest:
        return Icons.sos_rounded;
      case _AlertType.deviceOffline:
        return Icons.wifi_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      required: Permission.emergencyAlerts,
      child: RoleScaffold(
        role: UserRole.caregiver,
        currentIndex: 2,
        title: 'Emergency Alerts',
        body: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: _alerts.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final a = _alerts[i];
            final isCritical = a.type == _AlertType.fallDetected ||
                a.type == _AlertType.emergencyRequest;
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                leading: CircleAvatar(
                  backgroundColor:
                      (isCritical ? AppColors.alert : AppColors.warning).withValues(alpha: 0.12),
                  child: Icon(_icon(a.type),
                      color: isCritical ? AppColors.alert : AppColors.warning),
                ),
                title: Text(_label(a.type), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${a.user} · ${a.time} · ${a.status}'),
                trailing: FilledButton.tonal(
                  onPressed: () {},
                  child: const Text('View'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
