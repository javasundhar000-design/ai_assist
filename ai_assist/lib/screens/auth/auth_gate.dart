import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../models/user_role.dart';
import '../../services/caregiver_auth_service.dart';
import '../../services/family_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../blind_mode/image_assist_screen.dart';
import '../motor_mode/scan_mode_screen.dart';
import '../non_speaking_mode/notepad_screen.dart';
import 'choose_member_screen.dart';
import 'welcome_screen.dart';

/// Decides what a cold app launch should show, in priority order:
///
///  1. A cached member session on THIS device ("Priya's phone") →
///     straight into her mode screen. Most member devices live here
///     permanently after first setup.
///  2. A signed-in caregiver (Firebase Auth persists this automatically)
///     → straight into the Admin Dashboard.
///  3. A device that joined a family by code but hasn't picked a member
///     yet → the "who is this?" picker.
///  4. Nothing at all → the Welcome screen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<Widget> _resolved;

  @override
  void initState() {
    super.initState();
    _resolved = _resolve();
  }

  Future<Widget> _resolve() async {
    final memberSession = await SessionService.instance.loadMemberSession();
    if (memberSession != null) {
      final member = await FamilyService.instance.getMember(
        memberSession.familyUid,
        memberSession.memberId,
      );
      if (member != null) {
        return _screenForMember(memberSession.familyUid, member);
      }
      // Member was deleted by their caregiver since this device last
      // opened the app — fall through and clear the stale session.
      await SessionService.instance.clear();
    }

    final caregiver = CaregiverAuthService.instance.currentUser;
    if (caregiver != null) {
      return const AdminDashboardScreen();
    }

    final joinedFamilyUid = await SessionService.instance.loadFamilyUidOnly();
    if (joinedFamilyUid != null) {
      return ChooseMemberScreen(familyUid: joinedFamilyUid);
    }

    return const WelcomeScreen();
  }

  Widget _screenForMember(String familyUid, UserProfile profile) {
    switch (profile.role) {
      case UserRole.blind:
        return ImageAssistScreen(familyUid: familyUid, profile: profile);
      case UserRole.nonSpeaking:
        return NotepadScreen(familyUid: familyUid, profile: profile);
      case UserRole.motor:
        return ScanModeScreen(familyUid: familyUid, profile: profile);
      case UserRole.admin:
        return const WelcomeScreen(); // defensive — members are never admin
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolved,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.canvas,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!;
      },
    );
  }
}
