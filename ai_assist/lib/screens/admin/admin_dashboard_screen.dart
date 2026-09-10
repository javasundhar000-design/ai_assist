import 'package:flutter/material.dart';

import '../../models/emergency_alert.dart';
import '../../models/user_profile.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/emergency_service.dart';
import '../auth/profile_select_screen.dart';
import '../auth/register_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserProfile> _profiles = [];
  List<EmergencyAlert> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final profiles = await AuthService.instance.loadProfiles();
    final alerts = await EmergencyService.instance.loadAlerts();
    setState(() {
      _profiles = profiles;
      _alerts = alerts;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ProfileSelectScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteProfile(UserProfile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this person?'),
        content: Text('This removes ${profile.name} and their settings from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.instance.deleteProfile(profile.id);
      _load();
    }
  }

  Future<void> _resolveAlert(EmergencyAlert alert) async {
    await EmergencyService.instance.resolveAlert(alert.id);
    _load();
  }

  int get _unresolvedCount => _alerts.where((a) => !a.resolved).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Log out'),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(icon: Icon(Icons.people), text: 'Members'),
            Tab(
              icon: Badge(
                isLabelVisible: _unresolvedCount > 0,
                label: Text('$_unresolvedCount'),
                child: const Icon(Icons.emergency),
              ),
              text: 'Alerts',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Person'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildMembersTab(), _buildAlertsTab()],
            ),
    );
  }

  Widget _buildMembersTab() {
    if (_profiles.isEmpty) {
      return const Center(child: Text('No members registered yet.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _profiles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final p = _profiles[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: p.role.color,
              child: Icon(p.role.icon, color: Colors.white),
            ),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              p.role == UserRole.admin
                  ? p.role.label
                  : '${p.role.label} · ${p.emergencyContacts.isEmpty ? 'no emergency contact' : p.emergencyContacts.first.name}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteProfile(p),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    if (_alerts.isEmpty) {
      return const Center(child: Text('No emergency alerts yet.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final a = _alerts[i];
        return Card(
          color: a.resolved ? null : Colors.red.shade50,
          child: ListTile(
            leading: Icon(
              a.resolved ? Icons.check_circle : Icons.emergency,
              color: a.resolved ? Colors.green : Colors.red,
            ),
            title: Text('${a.profileName} (${a.roleLabel})',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_formatTimestamp(a.timestamp)),
            trailing: a.resolved
                ? const Text('Resolved', style: TextStyle(color: Colors.green))
                : TextButton(
                    onPressed: () => _resolveAlert(a),
                    child: const Text('Mark resolved'),
                  ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final sameDay = now.year == dt.year && now.month == dt.month && now.day == dt.day;
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return sameDay ? 'Today at $time' : '${dt.day}/${dt.month}/${dt.year} at $time';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
