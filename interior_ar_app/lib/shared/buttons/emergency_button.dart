import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/emergency_service.dart';
import '../../core/services/text_to_speech_service.dart';
import '../../features/authentication/session_provider.dart';
import '../dialogs/confirm_dialog.dart';
import '../../core/theme/app_theme.dart';

/// The one emergency control shared by all dashboards (Section 25).
/// Always confirms before dialing/texting — accidental dwell-selects or
/// mis-taps must never silently place an emergency call.
class EmergencyButton extends ConsumerWidget {
  final String semanticLabel;

  const EmergencyButton({super.key, this.semanticLabel = 'Emergency'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final semantic = Theme.of(context).extension<AppSemanticColors>();

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: semantic?.emergency ?? Colors.red,
        borderRadius: BorderRadius.circular(AppTheme.baseRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.baseRadius),
          onTap: () async {
            final confirmed = await showConfirmDialog(
              context,
              title: 'Send emergency alert?',
              message: 'This will call and text your emergency contact.',
              confirmLabel: 'YES, SEND',
              cancelLabel: 'CANCEL',
            );
            if (confirmed != true) return;

            await TextToSpeechService.instance.speak('Sending emergency alert now.');
            final contact = user?.emergencyContact ?? '';
            if (contact.isEmpty) {
              await TextToSpeechService.instance
                  .speak('No emergency contact is set. Please add one in settings.');
              return;
            }
            await EmergencyService.instance.triggerEmergency(emergencyContact: contact);
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 96),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              semanticLabel.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
