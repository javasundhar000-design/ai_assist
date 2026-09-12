import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_role.dart';
import '../../widgets/app_button.dart';

/// Spec §30: settings are role-aware — each role sees the same common
/// section, plus role-specific controls surfaced first/prominently.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _speechSpeed = 0.5;
  double _fontScale = 1.0;
  bool _highContrast = false;
  bool _notifications = true;
  double _dwellTime = 800;
  double _eyeSensitivity = 0.5;

  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _hasStoredKey = false;
  bool _savingKey = false;

  @override
  void initState() {
    super.initState();
    _loadStoredKey();
  }

  Future<void> _loadStoredKey() async {
    final key = await ref.read(secureStorageProvider).getOpenRouterKey();
    if (!mounted) return;
    setState(() {
      _hasStoredKey = key != null && key.trim().isNotEmpty;
      if (_hasStoredKey) _apiKeyController.text = key!;
    });
  }

  Future<void> _saveKey() async {
    setState(() => _savingKey = true);
    try {
      await ref.read(secureStorageProvider).saveOpenRouterKey(_apiKeyController.text.trim());
      if (!mounted) return;
      setState(() => _hasStoredKey = _apiKeyController.text.trim().isNotEmpty);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OpenRouter key saved on this device.')),
      );
    } finally {
      if (mounted) setState(() => _savingKey = false);
    }
  }

  Future<void> _clearKey() async {
    await ref.read(secureStorageProvider).clearOpenRouterKey();
    if (!mounted) return;
    setState(() {
      _apiKeyController.clear();
      _hasStoredKey = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OpenRouter key removed. AI features will use demo responses.')),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final role = user?.role;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _SectionTitle('AI Configuration'),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: (_hasStoredKey ? AppColors.success : AppColors.warning).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Row(
                children: [
                  Icon(_hasStoredKey ? Icons.check_circle_rounded : Icons.info_outline,
                      color: _hasStoredKey ? AppColors.success : AppColors.warning, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _hasStoredKey
                          ? 'Live AI is active. Vision and suggestion features call OpenRouter.'
                          : 'No key added yet — AI features are showing demo responses.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Your key is stored only on this device (Keystore/Keychain-backed) and is used to '
              'call OpenRouter directly. It is never bundled into the app or shared.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: 'OpenRouter API Key',
              controller: _apiKeyController,
              obscureText: _obscureKey,
              suffixIcon: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PrimaryButton(label: 'Save Key', onPressed: _saveKey, isLoading: _savingKey),
                ),
                if (_hasStoredKey) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(onPressed: _clearKey, child: const Text('Remove')),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (role == UserRole.blind) ...[
              _SectionTitle('Voice Settings'),
              _SliderTile(
                label: 'Speech Speed',
                value: _speechSpeed,
                onChanged: (v) => setState(() => _speechSpeed = v),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (role == UserRole.nonSpeaking) ...[
              _SectionTitle('Communication Settings'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.record_voice_over_rounded),
                title: const Text('Speech Voice'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              _SliderTile(
                label: 'Speech Speed',
                value: _speechSpeed,
                onChanged: (v) => setState(() => _speechSpeed = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.text_snippet_outlined),
                title: const Text('Quick Phrases'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (role == UserRole.motorImpaired) ...[
              _SectionTitle('Eye Control Settings'),
              _SliderTile(
                label: 'Dwell Time (${_dwellTime.round()} ms)',
                value: (_dwellTime - 400) / 1600,
                onChanged: (v) => setState(() => _dwellTime = 400 + v * 1600),
              ),
              _SliderTile(
                label: 'Eye Sensitivity',
                value: _eyeSensitivity,
                onChanged: (v) => setState(() => _eyeSensitivity = v),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (role == UserRole.caregiver) ...[
              _SectionTitle('Notification Settings'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Emergency Alert Notifications'),
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _SectionTitle('General'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language_rounded),
              title: const Text('Language'),
              trailing: const Text('English', style: TextStyle(color: AppColors.textSecondary)),
              onTap: () {},
            ),
            _SliderTile(
              label: 'Text Size',
              value: (_fontScale - 0.8) / 0.8,
              onChanged: (v) => setState(() => _fontScale = 0.8 + v * 0.8),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('High Contrast'),
              value: _highContrast,
              onChanged: (v) => setState(() => _highContrast = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Notifications'),
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('Account'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const Divider(height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout_rounded, color: AppColors.alert),
              title: const Text('Logout', style: TextStyle(color: AppColors.alert)),
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _SliderTile({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Slider(value: value.clamp(0, 1), onChanged: onChanged),
      ],
    );
  }
}
