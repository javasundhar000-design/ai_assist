import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AIAssistApp());
}

class AIAssistApp extends StatelessWidget {
  const AIAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Assist',
      theme: AppTheme.light(),
      // AuthGate figures out, on cold launch, whether this device already
      // belongs to a member or a signed-in caregiver, and routes straight
      // there — see auth_gate.dart for the priority order.
      home: const AuthGate(),
    );
  }
}
