import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is optional at startup, not required: if firebase_options.dart
  // is still the placeholder (fresh checkout, flutterfire configure hasn't
  // been run yet) or initialization otherwise fails, the app falls back to
  // the on-device LocalAuthRepository/DemoAiService path instead of
  // crashing on launch. See core/providers.dart for where that fallback
  // decision is made.
  var firebaseReady = false;
  if (DefaultFirebaseOptions.isConfigured) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      firebaseReady = true;
    } catch (e) {
      debugPrint('Firebase failed to initialize, falling back to on-device storage: $e');
    }
  } else {
    debugPrint(
        'firebase_options.dart is still a placeholder — run `flutterfire configure` to enable '
        'Firebase. Falling back to on-device storage for now.');
  }

  runApp(
    ProviderScope(
      overrides: [firebaseReadyProvider.overrideWithValue(firebaseReady)],
      child: const AiAssistApp(),
    ),
  );
}

class AiAssistApp extends ConsumerWidget {
  const AiAssistApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AI Assist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      // Respect the system's font scale but clamp it so extreme settings
      // don't break layouts, while still honoring spec §31's requirement
      // for adjustable text size.
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final clampedScale = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.6,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScale),
          child: child!,
        );
      },
    );
  }
}
