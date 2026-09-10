import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes/app_router.dart';
import '../../models/accessibility_role.dart';
import '../../shared/cards/accessible_card.dart';
import 'session_provider.dart';

/// Section 7: name/email/password + accessibility-needs selection, all in
/// one flow, ending in a saved local [UserProfile]. Section 2's role
/// router reads `accessibilityProfiles` straight off this saved profile.
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  String _language = 'English';

  final Set<AccessibilityRole> _selectedRoles = {};
  String? _roleError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _emergencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _roleError = _selectedRoles.isEmpty
        ? 'Please select at least one accessibility need.'
        : null);

    if (!_formKey.currentState!.validate() || _selectedRoles.isEmpty) return;

    await ref.read(sessionProvider.notifier).register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          roles: _selectedRoles,
          preferredLanguage: _language,
          emergencyContact: _emergencyCtrl.text.trim(),
        );

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.dashboard, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Your Account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _field(_nameCtrl, 'Full Name', validator: _required),
              _field(_emailCtrl, 'Email', keyboardType: TextInputType.emailAddress, validator: _required),
              _field(_passwordCtrl, 'Password', obscure: true, validator: _required),
              _field(_confirmCtrl, 'Confirm Password', obscure: true, validator: (v) {
                if (v != _passwordCtrl.text) return 'Passwords do not match';
                return null;
              }),
              _field(_emergencyCtrl, 'Emergency Contact (phone number)',
                  keyboardType: TextInputType.phone, validator: _required),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _language,
                decoration: const InputDecoration(labelText: 'Preferred Language'),
                items: const ['English', 'Hindi', 'Tamil', 'Telugu', 'Bengali']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _language = v ?? _language),
              ),
              const SizedBox(height: 28),
              const Text(
                'SELECT YOUR ACCESSIBILITY NEEDS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'You can select more than one — the app will combine features from each.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 16),
              _roleGroup('👁️ Vision Support', [AccessibilityRole.blind, AccessibilityRole.lowVision]),
              const SizedBox(height: 12),
              _roleGroup('🔊 Communication Support', [AccessibilityRole.nonSpeaking]),
              const SizedBox(height: 12),
              _roleGroup('👀 Motor Support', [AccessibilityRole.motorImpaired]),
              if (_roleError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_roleError!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: _submit, child: const Text('CREATE ACCOUNT')),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                child: const Text('Already have an account? Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleGroup(String title, List<AccessibilityRole> roles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...roles.map(
          (role) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AccessibleCard(
              title: role.label,
              selected: _selectedRoles.contains(role),
              icon: _selectedRoles.contains(role)
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              onTap: () => setState(() {
                if (_selectedRoles.contains(role)) {
                  _selectedRoles.remove(role);
                } else {
                  _selectedRoles.add(role);
                }
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
}
