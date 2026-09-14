import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';

/// Spec §28: shows branding, then automatically checks authentication and
/// routes to either the role dashboard or login. The actual redirect
/// decision lives in app_router.dart's `redirect` callback — this screen
/// only needs to render while AuthController resolves its initial state.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching auth state here ensures this screen rebuilds (and GoRouter's
    // redirect re-evaluates) the moment session restoration finishes.
    ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
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
              child: const Icon(Icons.accessibility_new_rounded,
                  size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'AI Assist',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Empowering Everyone with AI',
              style: TextStyle(fontSize: 15, color: Colors.white70, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Accessibility for a smarter tomorrow.',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
