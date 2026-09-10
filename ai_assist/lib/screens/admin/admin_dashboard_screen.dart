import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/emergency_alert.dart';
import '../../models/user_profile.dart';
import '../../services/caregiver_auth_service.dart';
import '../../services/family_service.dart';
import '../../theme/app_theme.dart';
import '../auth/add_member_screen.dart';
import '../auth/welcome_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final String _uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _uid = CaregiverAuthService.instance.currentUser!.uid;
  }

  Future<void> _logout() async {
    await CaregiverAuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteMember(UserProfile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this person?'),
        content: Text('This removes ${profile.name} from your family.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.alert),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FamilyService.instance.deleteMember(_uid, profile.id);
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied — share it with the member\'s device.')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your family'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Sign out'),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.signal,
          unselectedLabelColor: AppColors.ink.withValues(alpha: 0.5),
          indicatorColor: AppColors.signal,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Members'),
            Tab(icon: Icon(Icons.emergency), text: 'Alerts'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.signal,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddMemberScreen(familyUid: _uid)),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('Add member'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMembersTab(), _buildAlertsTab()],
      ),
    );
  }

  Widget _buildMembersTab() {
    return Column(
      children: [
        _JoinCodeBanner(uid: _uid, onCopy: _copyCode),
        Expanded(
          child: StreamBuilder<List<UserProfile>>(
            stream: FamilyService.instance.membersStream(_uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final members = snapshot.data!;
              if (members.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No one added yet. Tap "Add member" to register the '
                      'first person, then share your family code with their device.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final p = members[i];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: p.role.color,
                        child: Icon(p.role.icon, color: Colors.white),
                      ),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        p.emergencyContacts.isEmpty
                            ? p.role.label
                            : '${p.role.label} · ${p.emergencyContacts.first.name}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.alert),
                        onPressed: () => _deleteMember(p),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsTab() {
    return StreamBuilder<List<EmergencyAlert>>(
      stream: FamilyService.instance.alertsStream(_uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final alerts = snapshot.data!;
        if (alerts.isEmpty) {
          return Center(
            child: Text('No emergency alerts yet.', style: Theme.of(context).textTheme.bodyLarge),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: alerts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final a = alerts[i];
            return Card(
              color: a.resolved ? null : AppColors.alert.withValues(alpha: 0.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: a.resolved ? AppColors.mist : AppColors.alert, width: 1),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Icon(
                  a.resolved ? Icons.check_circle : Icons.emergency,
                  color: a.resolved ? Colors.green : AppColors.alert,
                ),
                title: Text('${a.profileName} · ${a.roleLabel}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_formatTimestamp(a.timestamp)),
                trailing: a.resolved
                    ? const Text('Resolved', style: TextStyle(color: Colors.green))
                    : TextButton(
                        onPressed: () => FamilyService.instance.resolveAlert(_uid, a.id),
                        child: const Text('Mark resolved'),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final sameDay = now.year == dt.year && now.month == dt.month && now.day == dt.day;
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return sameDay ? 'Today at $time' : '${dt.day}/${dt.month}/${dt.year} at $time';
  }
}

class _JoinCodeBanner extends StatelessWidget {
  final String uid;
  final void Function(String code) onCopy;

  const _JoinCodeBanner({required this.uid, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: FamilyService.instance.familyCodeStream(uid),
      builder: (context, snapshot) {
        final code = snapshot.data;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.signal,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.qr_code_2, color: Colors.white, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Family code',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(
                      code ?? '······',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              if (code != null)
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white),
                  onPressed: () => onCopy(code),
                  tooltip: 'Copy code',
                ),
            ],
          ),
        );
      },
    );
  }
}
