import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/constants/app_constants.dart';

/// Purely presentational — the actual "authenticated? -> dashboard : login"
/// decision lives in the router's redirect logic (app/routes/app_router.dart)
/// so there's a single source of truth for navigation.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chair_alt_rounded, size: 64, color: scheme.onPrimary),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              style: TextStyle(
                color: scheme.onPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: scheme.onPrimary),
          ],
        ),
      ),
    );
  }
}
