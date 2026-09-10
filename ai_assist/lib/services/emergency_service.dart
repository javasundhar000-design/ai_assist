import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/emergency_alert.dart';
import '../models/user_profile.dart';
import 'tts_service.dart';

/// Handles the emergency / SOS flow available from Blind, Non-Speaking,
/// and Motor mode screens.
///
/// What this actually does on a real device:
///  1. Writes an EmergencyAlert record to local storage, so the Admin
///     dashboard (on THIS device) can see it in the alert log.
///  2. Speaks a confirmation aloud via TTS.
///  3. Opens the phone's own SMS app, pre-addressed to the member's first
///     saved emergency contact with a pre-filled message — the member (or
///     whoever's nearby) still has to tap "send" in that app. This is a
///     deliberate limitation: sending SMS silently/automatically requires
///     the SEND_SMS permission and a plugin like flutter_sms /
///     telephony, which Google Play treats as a sensitive permission
///     requiring special review — appropriate for a hardened production
///     build, not this prototype.
///
/// For real deployment where alerts must reach a caregiver's phone even
/// when they're not looking at this device (true push notification),
/// you need a backend: this device posts the alert to a server (e.g.
/// Firebase Firestore), and the admin's device gets a push notification
/// (e.g. Firebase Cloud Messaging) — see README for the swap-in points.
class EmergencyService {
  EmergencyService._internal();
  static final EmergencyService instance = EmergencyService._internal();

  static const _kAlertsKey = 'emergency_alerts';
  final _rand = Random();

  Future<List<EmergencyAlert>> loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAlertsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => EmergencyAlert.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> _saveAlerts(List<EmergencyAlert> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(alerts.map((a) => a.toJson()).toList());
    await prefs.setString(_kAlertsKey, raw);
  }

  Future<void> resolveAlert(String id) async {
    final alerts = await loadAlerts();
    final alert = alerts.firstWhere((a) => a.id == id);
    alert.resolved = true;
    await _saveAlerts(alerts);
  }

  /// Triggers a full emergency alert for [profile]. Returns the created
  /// alert so the calling screen can show confirmation UI if it wants to.
  Future<EmergencyAlert> triggerAlert(UserProfile profile) async {
    final alert = EmergencyAlert(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_rand.nextInt(99999)}',
      profileId: profile.id,
      profileName: profile.name,
      roleLabel: profile.role.label,
      timestamp: DateTime.now(),
    );

    final alerts = await loadAlerts();
    alerts.insert(0, alert);
    await _saveAlerts(alerts);

    await TtsService.instance.speak(
      'Emergency alert sent for ${profile.name}. Opening a message to '
      'your emergency contact now.',
    );

    if (profile.emergencyContacts.isNotEmpty) {
      final contact = profile.emergencyContacts.first;
      final smsUri = Uri(
        scheme: 'sms',
        path: contact.phone,
        queryParameters: {
          'body':
              'EMERGENCY ALERT: ${profile.name} (${profile.role.label}, '
              'AI Assist app) needs help right now. Sent at '
              '${alert.timestamp.hour.toString().padLeft(2, '0')}:'
              '${alert.timestamp.minute.toString().padLeft(2, '0')}.',
        },
      );
      try {
        await launchUrl(smsUri);
      } catch (_) {
        // If no SMS app / launch fails, the alert is still logged locally
        // and spoken aloud — this is a soft failure, not a thrown error.
      }
    }

    return alert;
  }

  /// Directly dials the member's first emergency contact (separate from
  /// triggerAlert, for a "Call Now" button instead of / in addition to SMS).
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
