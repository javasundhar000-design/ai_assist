import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/speech_command_service.dart';
import '../../core/services/text_to_speech_service.dart';
import '../../shared/buttons/emergency_button.dart';
import '../../shared/cards/dashboard_header.dart';
import '../../shared/cards/quick_action_tile.dart';
import '../authentication/session_provider.dart';

/// Section 9: voice-first home screen for Blind / Low Vision users.
/// Every action here speaks its own confirmation, and the mic button is
/// the visual and functional focal point — not one tile among many.
class VisionHomeScreen extends ConsumerStatefulWidget {
  const VisionHomeScreen({super.key});

  @override
  ConsumerState<VisionHomeScreen> createState() => _VisionHomeScreenState();
}

class _VisionHomeScreenState extends ConsumerState<VisionHomeScreen> {
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final name = ref.read(sessionProvider)?.name.split(' ').first ?? '';
      TextToSpeechService.instance.speak(
        'Good morning${name.isNotEmpty ? ', $name' : ''}. How can I help?',
      );
    });
  }

  Future<void> _startListening() async {
    setState(() => _listening = true);
    await SpeechCommandService.instance.listen(
      onCommand: (command, rawText) {
        if (!mounted) return;
        setState(() => _listening = false);
        _handleCommand(command);
      },
    );
  }

  void _handleCommand(VoiceCommand command) {
    switch (command) {
      case VoiceCommand.readThis:
        Navigator.of(context).pushNamed(AppRoutes.visionReader);
        break;
      case VoiceCommand.readMedicine:
        Navigator.of(context).pushNamed(AppRoutes.medicineReader);
        break;
      case VoiceCommand.openBookReader:
        Navigator.of(context).pushNamed(AppRoutes.bookReader);
        break;
      case VoiceCommand.describeThis:
        Navigator.of(context).pushNamed(AppRoutes.sceneAssistant);
        break;
      case VoiceCommand.stop:
        TextToSpeechService.instance.stop();
        break;
      case VoiceCommand.repeat:
        TextToSpeechService.instance.speak('How can I help?');
        break;
      case VoiceCommand.emergency:
        TextToSpeechService.instance.speak('Opening emergency options.');
        break;
      case VoiceCommand.unknown:
        TextToSpeechService.instance.speak("Sorry, I didn't catch that. Please try again.");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = ref.watch(sessionProvider)?.name.split(' ').first ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vision Assistant'),
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DashboardHeader(
              greeting: name.isNotEmpty ? 'Good morning, $name' : 'Good morning',
              subtitle: 'Tap the mic or choose an action below.',
              icon: Icons.remove_red_eye_rounded,
              gradientColors: [scheme.primary, scheme.primary.withValues(alpha: 0.75)],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _startListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 116,
                      height: 116,
                      decoration: BoxDecoration(
                        color: _listening ? scheme.primary : scheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        boxShadow: _listening
                            ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.35), blurRadius: 24, spreadRadius: 4)]
                            : null,
                      ),
                      child: Icon(Icons.mic_rounded,
                          size: 48, color: _listening ? Colors.white : scheme.primary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _listening ? 'Listening…' : 'TAP & SPEAK',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.05,
              children: [
                QuickActionTile(
                  label: 'Read Text',
                  icon: Icons.document_scanner_rounded,
                  color: scheme.primary,
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.visionReader),
                ),
                QuickActionTile(
                  label: 'Medicine',
                  icon: Icons.medication_rounded,
                  color: const Color(0xFFE0533D),
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.medicineReader),
                ),
                QuickActionTile(
                  label: 'Book Reader',
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF8E5CD9),
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.bookReader),
                ),
                QuickActionTile(
                  label: 'Objects',
                  icon: Icons.category_rounded,
                  color: const Color(0xFF1FB871),
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.objectAssistant),
                ),
                QuickActionTile(
                  label: 'Currency',
                  icon: Icons.currency_rupee_rounded,
                  color: const Color(0xFFD9A02C),
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.currencyAssistant),
                ),
                QuickActionTile(
                  label: 'Describe\nSurroundings',
                  icon: Icons.wallpaper_rounded,
                  color: const Color(0xFF2C93D9),
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.sceneAssistant),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const EmergencyButton(semanticLabel: 'Voice Emergency'),
          ],
        ),
      ),
    );
  }
}
