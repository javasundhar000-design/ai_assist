import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../services/tts_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../blind_mode/image_assist_screen.dart';
import '../motor_mode/scan_mode_screen.dart';
import '../non_speaking_mode/notepad_screen.dart';
import 'register_screen.dart';

class ProfileSelectScreen extends StatefulWidget {
  const ProfileSelectScreen({super.key});

  @override
  State<ProfileSelectScreen> createState() => _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends State<ProfileSelectScreen> {
  List<UserProfile> _profiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TtsService.instance.speak('Who is using AI Assist? Choose your name, or add a new person.');
    });
  }

  Future<void> _load() async {
    final profiles = await AuthService.instance.loadProfiles();
    setState(() {
      _profiles = profiles;
      _loading = false;
    });
  }

  Future<void> _selectProfile(UserProfile profile) async {
    if (profile.role == UserRole.admin) {
      final ok = await _promptAdminPin(profile);
      if (!ok) return;
    }
    await AuthService.instance.login(profile.id);
    if (!mounted) return;
    final familyUid = await SessionService.instance.loadFamilyUidOnly();
    if (!mounted) return;
    if (familyUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This device is not connected to a family yet.')),
      );
      return;
    }
    _navigateToRoleHome(familyUid, profile);
  }

  Future<bool> _promptAdminPin(UserProfile profile) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Admin PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final ok = AuthService.instance.verifyAdminPin(profile, controller.text.trim());
              Navigator.pop(context, ok);
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect PIN.')),
                );
              }
            },
            child: const Text('Enter'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _navigateToRoleHome(String familyUid, UserProfile profile) {
    Widget destination;
    switch (profile.role) {
      case UserRole.blind:
        destination = ImageAssistScreen(familyUid: familyUid, profile: profile);
        break;
      case UserRole.nonSpeaking:
        destination = NotepadScreen(familyUid: familyUid, profile: profile);
        break;
      case UserRole.motor:
        destination = ScanModeScreen(familyUid: familyUid, profile: profile);
        break;
      case UserRole.admin:
        destination = const AdminDashboardScreen();
        break;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Assist'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Who is using the app?',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Each person only sees the mode set up for them.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _profiles.isEmpty
                          ? Center(
                              child: Text(
                                'No one is registered yet.\nTap "Add Person" below to get started.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _profiles.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final p = _profiles[i];
                                return Material(
                                  color: p.role.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(18),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () => _selectProfile(p),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 26,
                                            backgroundColor: p.role.color,
                                            child: Icon(p.role.icon, color: Colors.white),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(p.name,
                                                    style: const TextStyle(
                                                        fontSize: 18, fontWeight: FontWeight.bold)),
                                                Text(p.role.label,
                                                    style: TextStyle(color: Colors.grey.shade700)),
                                              ],
                                            ),
                                          ),
                                          if (p.role == UserRole.admin)
                                            const Icon(Icons.lock, size: 18, color: Colors.grey),
                                          const Icon(Icons.chevron_right),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Person'),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                        _load();
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
