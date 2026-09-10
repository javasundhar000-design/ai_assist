import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import '../../core/accessibility/accessibility_settings.dart';
import '../../core/theme/app_theme.dart';

/// The single "big tappable thing" widget used across all three
/// dashboards (Section 3: large buttons everywhere, no tiny controls).
/// Centralizing it here means haptic feedback + font scaling behave
/// identically whether it's a Blind-dashboard action, a phrase button,
/// or an eye-control target.
class LargeActionButton extends ConsumerWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final bool filled;
  final bool isEmergency;

  const LargeActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
    this.filled = true,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(accessibilitySettingsProvider);
    final scheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();

    final bg = isEmergency
        ? (semantic?.emergency ?? scheme.error)
        : (color ?? (filled ? scheme.primary : scheme.surface));
    final fg = isEmergency || filled ? Colors.white : scheme.onSurface;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.baseRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.baseRadius),
          onTap: () async {
            if (settings.hapticEnabled) {
              final hasVibrator = await Vibration.hasVibrator();
              if (hasVibrator) Vibration.vibrate(duration: 40);
            }
            onPressed();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: AppTheme.largeButtonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.baseRadius),
              border: (semantic?.isHighContrast ?? false)
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Icon(icon, color: fg, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 20 * settings.fontScale,
                      fontWeight: FontWeight.w700,
                    ),
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
