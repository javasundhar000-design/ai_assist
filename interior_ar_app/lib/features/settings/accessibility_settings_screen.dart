import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/accessibility/accessibility_settings.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_router.dart';
import '../authentication/session_provider.dart';
import '../eye_control/calibration/eye_calibration_screen.dart';
import '../../shared/dialogs/confirm_dialog.dart';

/// Section 26: every adjustable setting the spec lists, grouped exactly
/// as specified (Display / Voice / Haptic / Eye Control), each control
/// writing straight through [accessibilitySettingsProvider].
class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(accessibilitySettingsProvider);
    final notifier = ref.read(accessibilitySettingsProvider.notifier);
    final user = ref.watch(sessionProvider);
    final motorRoleActive =
        user?.accessibilityProfiles.any((r) => r.name == 'motorImpaired') ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Display'),
          ListTile(
            title: const Text('Font Size'),
            subtitle: Slider(
              value: settings.fontScale,
              min: 0.8,
              max: 2.0,
              divisions: 12,
              label: '${(settings.fontScale * 100).round()}%',
              onChanged: notifier.setFontScale,
            ),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('Light Mode'),
            value: AppThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (v) => notifier.setThemeMode(v!),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('Dark Mode'),
            value: AppThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (v) => notifier.setThemeMode(v!),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('High Contrast'),
            value: AppThemeMode.highContrast,
            groupValue: settings.themeMode,
            onChanged: (v) => notifier.setThemeMode(v!),
          ),
          SwitchListTile(
            title: const Text('Reduce Animation'),
            value: settings.reduceMotion,
            onChanged: notifier.setReduceMotion,
          ),

          const Divider(height: 32),
          _sectionTitle('Voice'),
          ListTile(
            title: const Text('Speech Speed'),
            subtitle: Slider(
              value: settings.speechRate,
              min: 0.1,
              max: 1.0,
              onChanged: notifier.setSpeechRate,
            ),
          ),
          ListTile(
            title: const Text('Pitch'),
            subtitle: Slider(
              value: settings.speechPitch,
              min: 0.5,
              max: 2.0,
              onChanged: notifier.setSpeechPitch,
            ),
          ),
          ListTile(
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: settings.speechLanguage,
              items: const [
                DropdownMenuItem(value: 'en-US', child: Text('English')),
                DropdownMenuItem(value: 'hi-IN', child: Text('Hindi')),
                DropdownMenuItem(value: 'ta-IN', child: Text('Tamil')),
                DropdownMenuItem(value: 'te-IN', child: Text('Telugu')),
              ],
              onChanged: (v) => notifier.setSpeechLanguage(v ?? settings.speechLanguage),
            ),
          ),

          const Divider(height: 32),
          _sectionTitle('Haptic'),
          SwitchListTile(
            title: const Text('Enable Haptic Feedback'),
            value: settings.hapticEnabled,
            onChanged: notifier.setHapticEnabled,
          ),

          if (motorRoleActive) ...[
            const Divider(height: 32),
            _sectionTitle('Eye Control'),
            ListTile(
              title: const Text('Recalibrate'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EyeCalibrationScreen()),
              ),
            ),
            ListTile(
              title: const Text('Dwell Time'),
              subtitle: Slider(
                value: settings.dwellTimeMs.toDouble(),
                min: 400,
                max: 3000,
                divisions: 13,
                label: '${settings.dwellTimeMs} ms',
                onChanged: (v) => notifier.setDwellTimeMs(v.round()),
              ),
            ),
            ListTile(
              title: const Text('Gaze Sensitivity'),
              subtitle: Slider(
                value: settings.gazeSensitivity,
                min: 0,
                max: 1,
                onChanged: notifier.setGazeSensitivity,
              ),
            ),
            SwitchListTile(
              title: const Text('Blink Selection'),
              value: settings.blinkSelectionEnabled,
              onChanged: notifier.setBlinkSelectionEnabled,
            ),
          ],

          const Divider(height: 32),
          _sectionTitle('AI Enhancement'),
          Text(
            'Optional. On-device recognition (used everywhere by default) '
            'works fully offline but is deliberately limited — it only '
            'recognizes a handful of broad object categories and can '
            'struggle with small or angled text. Adding your own AI API '
            'key noticeably improves Read Text, Medicine Reader, Book '
            'Reader, Object Assistant, Currency, and Describe Surroundings. '
            'Nothing is sent anywhere unless you add a key, and everything '
            'keeps working without one.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 12),
          const _AiApiKeyField(),

          const Divider(height: 32),
          _sectionTitle('Account'),
          ListTile(
            title: const Text('Delete All Data'),
            titleTextStyle: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16, fontWeight: FontWeight.w700),
            trailing: const Icon(Icons.delete_forever_rounded),
            onTap: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'Delete all data?',
                message: 'This removes your profile, phrases, and settings from this device permanently.',
                confirmLabel: 'DELETE',
              );
              if (confirmed == true) {
                await LocalStorageService.instance.clearAllData();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.splash, (_) => false);
                }
              }
            },
          ),
          ListTile(
            title: const Text('Log Out'),
            trailing: const Icon(Icons.logout_rounded),
            onTap: () async {
              await ref.read(sessionProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      );
}

/// Small self-contained widget so it can manage its own controller and
/// load/save the key asynchronously (from flutter_secure_storage, not
/// Hive — see LocalStorageService) without turning the whole settings
/// screen stateful.
class _AiApiKeyField extends StatefulWidget {
  const _AiApiKeyField();

  @override
  State<_AiApiKeyField> createState() => _AiApiKeyFieldState();
}

class _AiApiKeyFieldState extends State<_AiApiKeyField> {
  final _controller = TextEditingController();
  bool _obscured = true;
  bool _loading = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final key = await LocalStorageService.instance.getAiApiKey();
    if (!mounted) return;
    setState(() {
      _controller.text = key ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      await LocalStorageService.instance.clearAiApiKey();
    } else {
      await LocalStorageService.instance.saveAiApiKey(value);
    }
    if (!mounted) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value.isEmpty ? 'AI key removed.' : 'AI key saved.')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          obscureText: _obscured,
          onChanged: (_) => setState(() => _saved = false),
          decoration: InputDecoration(
            labelText: 'AI API Key',
            hintText: 'Paste your Gemini API key',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded),
              onPressed: () => setState(() => _obscured = !_obscured),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _saved ? null : _save,
          icon: Icon(_saved ? Icons.check_rounded : Icons.save_rounded),
          label: Text(_saved ? 'SAVED' : 'SAVE KEY'),
        ),
      ],
    );
  }
}
