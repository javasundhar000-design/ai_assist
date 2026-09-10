import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes/app_router.dart';
import '../../models/accessibility_role.dart';
import '../../shared/cards/accessible_card.dart';
import '../../shared/dialogs/confirm_dialog.dart';
import '../authentication/session_provider.dart';

/// Lets a returning user change their accessibility profile after
/// registration (Section 2 implies this should be possible — needs
/// change over time, e.g. a Low-Vision user later adding Motor Support).
/// Saving here re-triggers [DashboardRouterScreen]'s module resolution,
/// so the UI adapts immediately without a re-login.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Set<AccessibilityRole> _selectedRoles;

  @override
  void initState() {
    super.initState();
    _selectedRoles = {...?ref.read(sessionProvider)?.accessibilityProfiles};
  }

  Future<void> _save() async {
    if (_selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one accessibility need.')),
      );
      return;
    }
    await ref.read(sessionProvider.notifier).updateRoles(_selectedRoles);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.dashboard, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CircleAvatar(
              radius: 40,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
            Center(child: Text(user.email)),
            const SizedBox(height: 8),
            Center(child: Text('Emergency contact: ${user.emergencyContact}')),
            const SizedBox(height: 28),
            const Text('ACCESSIBILITY NEEDS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Adjust which modules AI Assist shows you.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            ...AccessibilityRole.values.map(
              (role) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AccessibleCard(
                  title: role.label,
                  subtitle: role.groupLabel,
                  selected: _selectedRoles.contains(role),
                  icon: _selectedRoles.contains(role)
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  onTap: () => setState(() {
                    if (_selectedRoles.contains(role)) {
                      _selectedRoles.remove(role);
                    } else {
                      _selectedRoles.add(role);
                    }
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('SAVE CHANGES')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Log out?',
                  message: 'You can log back in any time on this device.',
                  confirmLabel: 'LOG OUT',
                );
                if (confirmed == true) {
                  await ref.read(sessionProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
                  }
                }
              },
              child: const Text('LOG OUT'),
            ),
          ],
        ),
      ),
    );
  }
}
