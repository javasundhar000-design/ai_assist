import 'package:url_launcher/url_launcher.dart';

import '../models/user_profile.dart';
import 'family_service.dart';
import 'tts_service.dart';

/// Handles the emergency / SOS flow available from Blind, Non-Speaking,
/// and Motor mode screens.
///
/// What this does on a real device:
///  1. Writes an alert to Firebase Realtime Database under the member's
///     family — because this is now backed by Firebase (not local
///     storage), the caregiver's Admin Dashboard sees it appear LIVE on
///     their own device, even if they're nowhere near the member's phone.
///     This was the main limitation of the local-only prototype; it's
///     gone now.
///  2. Speaks a confirmation aloud via TTS.
///  3. Opens the phone's own SMS app, pre-addressed to the member's first
///     saved emergency contact with a pre-filled message. The member (or
///     whoever's nearby) still has to tap "send" in that app — see the
///     note below on why this isn't silent.
///
/// Why SMS isn't sent silently: doing that needs the SEND_SMS permission
/// and a plugin like flutter_sms/telephony, which Google Play treats as a
/// sensitive permission requiring additional review and justification.
/// That's a deliberate decision to make explicitly for your deployment,
/// not a default to ship quietly — see README's security notes.
class EmergencyService {
  EmergencyService._internal();
  static final EmergencyService instance = EmergencyService._internal();

  /// Triggers a full emergency alert for [profile], who belongs to the
  /// family identified by [familyUid].
  Future<void> triggerAlert({
    required String familyUid,
    required UserProfile profile,
  }) async {
    await FamilyService.instance.pushAlert(familyUid: familyUid, profile: profile);

    await TtsService.instance.speak(
      'Emergency alert sent for ${profile.name}. Opening a message to '
      'your emergency contact now.',
    );

    if (profile.emergencyContacts.isNotEmpty) {
      final contact = profile.emergencyContacts.first;
      final now = DateTime.now();
      final smsUri = Uri(
        scheme: 'sms',
        path: contact.phone,
        queryParameters: {
          'body':
              'EMERGENCY ALERT: ${profile.name} (${profile.role.label}, '
              'AI Assist app) needs help right now. Sent at '
              '${now.hour.toString().padLeft(2, '0')}:'
              '${now.minute.toString().padLeft(2, '0')}.',
        },
      );
      try {
        await launchUrl(smsUri);
      } catch (_) {
        // Soft failure — the alert is still logged in Firebase and spoken
        // aloud even if no SMS app is available to open.
      }
    }
  }

  /// Directly dials the member's first emergency contact.
  Future<void> callFirstContact(UserProfile profile) async {
    if (profile.emergencyContacts.isEmpty) return;
    final phone = profile.emergencyContacts.first.phone;
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } catch (_) {
      // soft failure — no dialer available
    }
  }
}
