import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/permission.dart';
import '../../../models/user_role.dart';
import '../../../widgets/permission_guard.dart';
import '../../../widgets/role_scaffold.dart';

class SystemMonitorScreen extends StatelessWidget {
  const SystemMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      required: Permission.monitorSystem,
      child: RoleScaffold(
        role: UserRole.admin,
        currentIndex: 2,
        title: 'System Monitor',
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            _StatusTile('Backend API', 'Operational', AppColors.success),
            SizedBox(height: AppSpacing.sm),
            _StatusTile('OpenRouter AI Service', 'Operational', AppColors.success),
            SizedBox(height: AppSpacing.sm),
            _StatusTile('Database', 'Operational', AppColors.success),
            SizedBox(height: AppSpacing.sm),
            _StatusTile('Push Notifications', 'Degraded', AppColors.warning),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final String name;
  final String status;
  final Color color;
  const _StatusTile(this.name, this.status, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: Icon(Icons.circle, color: color, size: 14),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
