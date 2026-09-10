import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/text_to_speech_service.dart';
import '../../shared/buttons/emergency_button.dart';
import '../../shared/buttons/large_action_button.dart';
import '../../shared/cards/dashboard_header.dart';

/// Section 18: quick-access phrase grid is the first thing a non-speaking
/// user sees — communication should never be more than one tap away.
class CommunicationHomeScreen extends StatelessWidget {
  const CommunicationHomeScreen({super.key});

  static const _quickPhrases = [
    ('I NEED WATER', Icons.water_drop_rounded),
    ('I AM HUNGRY', Icons.restaurant_rounded),
    ('I NEED HELP', Icons.pan_tool_rounded),
    ('CALL MY FAMILY', Icons.family_restroom_rounded),
    ('CALL DOCTOR', Icons.medical_services_rounded),
    ('YES', Icons.thumb_up_rounded),
    ('NO', Icons.thumb_down_rounded),
    ('THANK YOU', Icons.favorite_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication Assistant'),
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHeader(
                greeting: 'What would you like to say?',
                subtitle: 'Tap a phrase, or type your own message.',
                icon: Icons.chat_bubble_rounded,
                gradientColors: [const Color(0xFF8E5CD9), const Color(0xFF8E5CD9).withValues(alpha: 0.75)],
              ),
              const SizedBox(height: 16),
              LargeActionButton(
                label: 'TYPE MESSAGE',
                icon: Icons.keyboard_rounded,
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.smartNotepad),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.quickPhrases),
                child: const Text('Browse all phrase categories →'),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  itemCount: _quickPhrases.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemBuilder: (context, i) {
                    final (label, icon) = _quickPhrases[i];
                    return _PhraseTile(label: label, icon: icon);
                  },
                ),
              ),
              const SizedBox(height: 12),
              const EmergencyButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhraseTile extends StatelessWidget {
  final String label;
  final IconData icon;

  const _PhraseTile({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => TextToSpeechService.instance.speak(label),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: scheme.onPrimaryContainer),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
