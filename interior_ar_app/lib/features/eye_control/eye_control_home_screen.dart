import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/local_storage_service.dart';
import '../../shared/buttons/emergency_button.dart';
import '../../shared/buttons/large_action_button.dart';
import '../../shared/cards/dashboard_header.dart';
import 'calibration/eye_calibration_screen.dart';
import 'keyboard/eye_keyboard_screen.dart';

/// Section 21: minimizes touch interaction — the two primary actions are
/// "open the gaze keyboard" and "recalibrate", both reachable via a
/// single large tap since dexterity, not visibility, is the constraint
/// here (unlike the Blind dashboard).
class EyeControlHomeScreen extends StatelessWidget {
  const EyeControlHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasCalibration = LocalStorageService.instance.hasCalibration;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eye Control'),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHeader(
                greeting: hasCalibration ? 'Ready to go' : 'Let\'s get set up',
                subtitle: hasCalibration
                    ? 'Open the gaze keyboard whenever you\'re ready.'
                    : 'Calibrate once to personalize gaze tracking for your eyes.',
                icon: Icons.visibility_rounded,
                gradientColors: const [Color(0xFF2C93D9), Color(0xFF1FB871)],
              ),
              const SizedBox(height: 24),
              LargeActionButton(
                label: hasCalibration ? 'RECALIBRATE' : 'CALIBRATE EYES',
                icon: Icons.center_focus_strong_rounded,
                filled: !hasCalibration,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EyeCalibrationScreen()),
                ),
              ),
              const SizedBox(height: 12),
              LargeActionButton(
                label: 'OPEN GAZE KEYBOARD',
                icon: Icons.keyboard_alt_rounded,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EyeKeyboardScreen()),
                ),
              ),
              const Spacer(),
              const EmergencyButton(semanticLabel: 'Gaze Emergency Button'),
            ],
          ),
        ),
      ),
    );
  }
}
