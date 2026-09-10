import 'package:flutter/material.dart';

import '../../services/caregiver_auth_service.dart';
import '../../services/family_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';

class CaregiverAuthScreen extends StatefulWidget {
  const CaregiverAuthScreen({super.key});

  @override
  State<CaregiverAuthScreen> createState() => _CaregiverAuthScreenState();
}

class _CaregiverAuthScreenState extends State<CaregiverAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = CaregiverAuthService.instance;
      final credential = _isSignUp
          ? await auth.signUp(email: email, password: password)
          : await auth.signIn(email: email, password: password);

      final uid = credential.user!.uid;
      if (_isSignUp) {
        // New caregiver account — mint this family's join code right away
        // so the dashboard has something to show immediately.
        await FamilyService.instance.ensureFamilyCode(uid);
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _error = CaregiverAuthService.instance.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email above first, then tap "Forgot password?" again.');
      return;
    }
    try {
      await CaregiverAuthService.instance.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email.')),
      );
    } catch (e) {
      setState(() => _error = CaregiverAuthService.instance.friendlyError(e));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? 'Create caregiver account' : 'Caregiver sign in')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isSignUp
                    ? 'Set up a family and start adding members.'
                    : 'Sign in to manage your family and see alerts.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              if (!_isSignUp) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
              ] else
                const SizedBox(height: 16),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.alert.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppColors.alert)),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isSignUp ? 'Create account' : 'Sign in'),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => setState(() {
                  _isSignUp = !_isSignUp;
                  _error = null;
                }),
                child: Text(
                  _isSignUp
                      ? 'Already have an account? Sign in'
                      : 'New here? Create a caregiver account',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
