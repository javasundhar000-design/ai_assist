import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../models/user_role.dart';
import '../../services/family_service.dart';
import '../../services/session_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../blind_mode/image_assist_screen.dart';
import '../motor_mode/scan_mode_screen.dart';
import '../non_speaking_mode/notepad_screen.dart';

/// Shown after a device has joined a family by code. This IS the login
/// step for members — no typing a password, just tapping your own name,
/// because that's realistic for people who may not be able to type one.
/// Whoever taps a name becomes the active session on THIS device from
/// then on (cached by SessionService) until someone logs out.
class ChooseMemberScreen extends StatefulWidget {
  final String familyUid;

  const ChooseMemberScreen({super.key, required this.familyUid});

  @override
  State<ChooseMemberScreen> createState() => _ChooseMemberScreenState();
}

class _ChooseMemberScreenState extends State<ChooseMemberScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TtsService.instance.speak('Choose your name to continue.');
    });
  }

  Future<void> _selectMember(UserProfile profile) async {
    await SessionService.instance.saveMemberSession(
      familyUid: widget.familyUid,
      memberId: profile.id,
    );
    if (!mounted) return;

    Widget destination;
    switch (profile.role) {
      case UserRole.blind:
        destination = ImageAssistScreen(familyUid: widget.familyUid, profile: profile);
        break;
      case UserRole.nonSpeaking:
        destination = NotepadScreen(familyUid: widget.familyUid, profile: profile);
        break;
      case UserRole.motor:
        destination = ScanModeScreen(familyUid: widget.familyUid, profile: profile);
        break;
      case UserRole.admin:
        return; // members are never admin — defensive no-op
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Who is this?')),
      body: SafeArea(
        child: StreamBuilder<List<UserProfile>>(
          stream: FamilyService.instance.membersStream(widget.familyUid),
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
                    'No members have been added to this family yet.\n'
                    'Ask your caregiver to add you from their Admin Dashboard.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = members[i];
                return Material(
                  color: p.role.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _selectMember(p),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: p.role.color,
                            child: Icon(p.role.icon, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: Theme.of(context).textTheme.titleLarge),
                                Text(p.role.label, style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.ink),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
