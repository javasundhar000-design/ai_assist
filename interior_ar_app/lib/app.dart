import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/accessibility/accessibility_settings.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget. Theme and global font scale both come from
/// [accessibilitySettingsProvider], so changing a setting anywhere in the
/// app (e.g. Settings screen, or a role-specific dashboard shortcut)
/// takes effect immediately app-wide without a restart.
class AiAssistApp extends ConsumerWidget {
  const AiAssistApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(accessibilitySettingsProvider);

    return MaterialApp(
      title: 'AI ASSIST',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.resolve(settings.themeMode),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.fontScale),
          ),
          child: child!,
        );
      },
    );
  }
}
