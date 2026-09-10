import 'package:flutter/material.dart';

import '../services/tts_service.dart';
import '../widgets/mode_card.dart';
import 'blind_mode/image_assist_screen.dart';
import 'motor_mode/scan_mode_screen.dart';
import 'non_speaking_mode/notepad_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Announce the app on open — helpful for screen-reader / blind users
    // launching the app without sighted assistance.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TtsService.instance.speak(
        'AI Assist. Choose a mode: Blind mode, Non speaking mode, or Motor mode.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assist'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Choose a mode',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ModeCard(
                title: 'Blind Mode',
                subtitle:
                    'Point the camera to read text, identify objects, '
                    'describe scenes, and read medicine labels aloud.',
                icon: Icons.remove_red_eye,
                color: Colors.indigo,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ImageAssistScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ModeCard(
                title: 'Non-Speaking Mode',
                subtitle:
                    'Type or speak, get smart phrase suggestions, and '
                    'have your device speak for you.',
                icon: Icons.chat_bubble,
                color: Colors.teal,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotepadScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ModeCard(
                title: 'Motor Mode',
                subtitle:
                    'Large auto-scanning buttons that can be selected with '
                    'a single tap, switch, or key press.',
                icon: Icons.touch_app,
                color: Colors.deepOrange,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ScanModeScreen(),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Tip: Blind Mode and Non-Speaking Mode read results aloud '
                'automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
