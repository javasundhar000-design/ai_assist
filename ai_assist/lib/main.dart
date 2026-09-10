import 'package:flutter/material.dart';

import 'screens/auth/profile_select_screen.dart';

void main() {
  runApp(const AIAssistApp());
}

class AIAssistApp extends StatelessWidget {
  const AIAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Assist',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      // Every session starts at profile selection ("who is using this
      // app?"), which enforces role-based access from the very first
      // screen — a Blind-role member is routed straight into Blind Mode
      // only, never shown the other modes.
      home: const ProfileSelectScreen(),
    );
  }
}
