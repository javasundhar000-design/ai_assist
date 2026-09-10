import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes/app_router.dart';
import '../../models/accessibility_role.dart';
import '../authentication/session_provider.dart';
import '../vision/vision_home_screen.dart';
import '../communication/communication_home_screen.dart';
import '../eye_control/eye_control_home_screen.dart';
/// This is Section 2 made real: read the saved profile, and load the
/// right UI — no generic dashboard, no feature ever shown to a user who
/// didn't select it. If a user holds multiple roles, this becomes a
/// swipeable set of tabs, one per active module, instead of forcing a
/// single "primary" role.
class DashboardRouterScreen extends ConsumerWidget {
  const DashboardRouterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);

    if (user == null) {
      // Session lost/expired — bounce to login rather than crash.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final modules = user.accessibilityProfiles.activeModules.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    if (modules.isEmpty) {
      return const Scaffold(body: Center(child: Text('No accessibility profile selected.')));
    }

    if (modules.length == 1) {
      return _screenFor(modules.first);
    }

    return DefaultTabController(
      length: modules.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Hi, ${user.name.split(' ').first}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_rounded),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
            ),
          ],
          bottom: TabBar(
            tabs: modules.map((m) => Tab(text: _tabLabel(m), icon: Icon(_tabIcon(m)))).toList(),
          ),
        ),
        body: TabBarView(children: modules.map(_screenFor).toList()),
      ),
    );
  }

  Widget _screenFor(AppModule module) {
    switch (module) {
      case AppModule.vision:
        return const VisionHomeScreen();
      case AppModule.communication:
        return const CommunicationHomeScreen();
      case AppModule.eyeControl:
        return const EyeControlHomeScreen();
    }
  }

  String _tabLabel(AppModule m) {
    switch (m) {
      case AppModule.vision:
        return 'Vision';
      case AppModule.communication:
        return 'Communicate';
      case AppModule.eyeControl:
        return 'Eye Control';
    }
  }

  IconData _tabIcon(AppModule m) {
    switch (m) {
      case AppModule.vision:
        return Icons.remove_red_eye_rounded;
      case AppModule.communication:
        return Icons.chat_bubble_rounded;
      case AppModule.eyeControl:
        return Icons.visibility_rounded;
    }
  }
}
