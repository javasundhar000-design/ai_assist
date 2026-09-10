import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/accessibility/accessibility_settings.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/local_storage_service.dart';
import '../authentication/session_provider.dart';

/// Section 5 + Section 4 "returning user" flow: check local session, then
/// route straight to the dashboard (skipping onboarding/registration) if
/// a profile already exists on this device.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final reduceMotion = ref.read(accessibilitySettingsProvider).reduceMotion;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: reduceMotion ? 200 : 900),
    )..forward();
    _decideNextRoute();
  }

  Future<void> _decideNextRoute() async {
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    final storage = LocalStorageService.instance;
    final user = ref.read(sessionProvider);

    String next;
    if (user != null && storage.isLoggedIn) {
      next = AppRoutes.dashboard;
    } else if (storage.isOnboarded) {
      next = AppRoutes.login;
    } else {
      next = AppRoutes.onboarding;
    }
    Navigator.of(context).pushReplacementNamed(next);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _controller,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(Icons.accessibility_new_rounded,
                      size: 56, color: scheme.primary),
                ),
                const SizedBox(height: 28),
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    AppStrings.appTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
