import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../models/user_role.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}

/// Provides the role-specific bottom navigation bar from spec §32:
///   Blind:        Home, History, Settings
///   Non-Speaking: Home, Messages, Settings
///   Motor:        Home, History, Settings
///   Caregiver:    Home, Users, Alerts, Settings
///   Admin:        Dashboard, Users, System, Settings
///
/// Each dashboard screen wraps its body in this scaffold so navigation never
/// exposes a section the role isn't permitted to use.
class RoleScaffold extends StatelessWidget {
  final UserRole role;
  final int currentIndex;
  final Widget body;
  final String title;

  const RoleScaffold({
    super.key,
    required this.role,
    required this.currentIndex,
    required this.body,
    this.title = 'AI Assist',
  });

  List<_NavItem> _itemsFor(UserRole role) {
    switch (role) {
      case UserRole.blind:
        return const [
          _NavItem('Home', Icons.home_rounded, '/blind/home'),
          _NavItem('History', Icons.history_rounded, '/blind/history'),
          _NavItem('Settings', Icons.settings_rounded, '/settings'),
        ];
      case UserRole.nonSpeaking:
        return const [
          _NavItem('Home', Icons.home_rounded, '/non-speaking/home'),
          _NavItem('Messages', Icons.chat_bubble_rounded, '/non-speaking/notepad'),
          _NavItem('Settings', Icons.settings_rounded, '/settings'),
        ];
      case UserRole.motorImpaired:
        return const [
          _NavItem('Home', Icons.home_rounded, '/motor/home'),
          _NavItem('History', Icons.history_rounded, '/motor/history'),
          _NavItem('Settings', Icons.settings_rounded, '/settings'),
        ];
      case UserRole.caregiver:
        return const [
          _NavItem('Home', Icons.home_rounded, '/caregiver/home'),
          _NavItem('Users', Icons.people_alt_rounded, '/caregiver/users'),
          _NavItem('Alerts', Icons.notifications_active_rounded, '/caregiver/alerts'),
          _NavItem('Settings', Icons.settings_rounded, '/settings'),
        ];
      case UserRole.admin:
        return const [
          _NavItem('Dashboard', Icons.dashboard_rounded, '/admin/home'),
          _NavItem('Users', Icons.people_alt_rounded, '/admin/users'),
          _NavItem('System', Icons.monitor_heart_rounded, '/admin/system'),
          _NavItem('Settings', Icons.settings_rounded, '/settings'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsFor(role);
    final accent = AppColors.forRole(role);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex.clamp(0, items.length - 1),
        indicatorColor: accent.withValues(alpha: 0.15),
        onDestinationSelected: (index) => context.go(items[index].route),
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: Icon(item.icon),
              label: item.label,
              selectedIcon: Icon(item.icon, color: accent),
            ),
        ],
      ),
    );
  }
}
