import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared across all three role dashboards (Section 25). Each dashboard
/// just wires its own trigger — voice, big button, or gaze — to the same
/// underlying actions, so emergency behavior can't drift between roles.
class EmergencyService {
  EmergencyService._();
  static final EmergencyService instance = EmergencyService._();

  Future<bool> callContact(String phoneNumber) async {
    if (phoneNumber.isEmpty) return false;
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }

  Future<bool> sendSms(String phoneNumber, String message) async {
    if (phoneNumber.isEmpty) return false;
    final uri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }

  /// Returns null if location is unavailable/denied — callers should
  /// treat that as "continue without location" rather than an error,
  /// since location sharing is explicitly optional (Section 29).
  Future<Position?> getCurrentLocationIfAvailable() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  Future<void> triggerEmergency({
    required String emergencyContact,
    bool shareLocation = true,
  }) async {
    String message = 'I need help. This is an emergency alert from AI Assist.';
    if (shareLocation) {
      final position = await getCurrentLocationIfAvailable();
      if (position != null) {
        message +=
            ' My location: https://maps.google.com/?q=${position.latitude},${position.longitude}';
      }
    }
    await sendSms(emergencyContact, message);
    await callContact(emergencyContact);
  }
}
