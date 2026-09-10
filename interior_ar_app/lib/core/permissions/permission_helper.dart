import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Section 28: always explain *why* before requesting, and never request
/// everything on first launch — each feature screen calls
/// [requestWithExplanation] for just the permission it needs, right
/// before it needs it.
class PermissionHelper {
  PermissionHelper._();

  // Not `const`: Permission overrides `==`/`hashCode` with custom value
  // equality, which Dart's const-evaluator won't accept as a const map
  // key (it requires primitive/identity equality for const map keys).
  // A `static final` map is built once at first access and behaves
  // identically for our purposes — it just isn't compile-time constant.
  static final Map<Permission, String> explanations = {
    Permission.camera: 'AI Assist needs camera access to read text and recognize objects.',
    Permission.microphone: 'AI Assist needs microphone access for voice commands.',
    Permission.notification: 'AI Assist can notify you about important reminders.',
    Permission.locationWhenInUse: 'AI Assist can share your location during an emergency alert.',
    Permission.phone: 'AI Assist needs phone access to make emergency calls.',
    Permission.sms: 'AI Assist needs SMS access to send emergency messages.',
  };

  static Future<bool> requestWithExplanation(
    BuildContext context,
    Permission permission,
  ) async {
    final explanation = explanations[permission] ?? 'This permission is needed for this feature.';

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Needed'),
        content: Text(explanation),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NOT NOW')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ALLOW')),
        ],
      ),
    );

    if (proceed != true) return false;
    final status = await permission.request();
    return status.isGranted;
  }
}
