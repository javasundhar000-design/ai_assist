import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/emergency_service.dart';
import '../services/tts_service.dart';

/// A big, hard-to-miss SOS button. Tapping it starts a short countdown
/// (cancellable) before actually sending the alert — this prevents a
/// single accidental tap (especially relevant for Motor Mode users) from
/// triggering a false alarm, while still being fast for a real emergency.
class EmergencyButton extends StatelessWidget {
  final UserProfile profile;

  const EmergencyButton({super.key, required this.profile});

  Future<void> _startConfirmFlow(BuildContext context) async {
    await TtsService.instance.speak('Emergency. Confirm within 3 seconds to send an alert.');
    if (!context.mounted) return;

    bool cancelled = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        int secondsLeft = 3;
        Timer? timer;
        return StatefulBuilder(
          builder: (context, setState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              secondsLeft--;
              if (secondsLeft <= 0) {
                t.cancel();
                if (!cancelled) Navigator.of(dialogContext).pop();
              } else {
                setState(() {});
              }
            });
            return AlertDialog(
              backgroundColor: Colors.red.shade50,
              title: Row(
                children: const [
                  Icon(Icons.emergency, color: Colors.red, size: 32),
                  SizedBox(width: 10),
                  Text('Sending Emergency Alert'),
                ],
              ),
              content: Text(
                'Sending in $secondsLeft...\nTap Cancel to stop.',
                style: const TextStyle(fontSize: 18),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    cancelled = true;
                    timer?.cancel();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
              ],
            );
          },
        );
      },
    );

    if (cancelled) {
      TtsService.instance.speak('Emergency alert cancelled.');
      return;
    }

    await EmergencyService.instance.triggerAlert(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Emergency SOS. Press to alert your emergency contact.',
      child: FloatingActionButton.extended(
        heroTag: 'emergency_button',
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.emergency, size: 28),
        label: const Text('SOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        onPressed: () => _startConfirmFlow(context),
      ),
    );
  }
}
