import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import '../../core/accessibility/accessibility_settings.dart';
import '../../core/theme/app_theme.dart';

/// Grid-friendly action tile — icon in a colored circle, bold label
/// below. Used in place of a plain stacked-button list for the primary
/// actions on each dashboard, giving a visual scan pattern more typical
/// of a "premium" app while keeping the tap target large (Section 3).
class QuickActionTile extends ConsumerWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const QuickActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(accessibilitySettingsProvider);
    final scheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final highContrast = semantic?.isHighContrast ?? false;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        elevation: highContrast ? 0 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            if (settings.hapticEnabled) {
              final hasVibrator = await Vibration.hasVibrator();
              if (hasVibrator) Vibration.vibrate(duration: 30);
            }
            onPressed();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 128),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: highContrast ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: highContrast ? 0.0 : 0.14),
                    shape: BoxShape.circle,
                    border: highContrast ? Border.all(color: Colors.white, width: 2) : null,
                  ),
                  child: Icon(icon, color: highContrast ? Colors.white : color, size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 14 * settings.fontScale,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
