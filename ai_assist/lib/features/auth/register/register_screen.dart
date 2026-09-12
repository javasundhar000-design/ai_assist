import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_role.dart';
import '../../../widgets/app_button.dart';

class _RoleOption {
  final UserRole role;
  final String category;
  final String title;
  final IconData icon;
  const _RoleOption(this.role, this.category, this.title, this.icon);
}

/// Spec §3: registration collects identity fields + accessibility role.
/// ADMIN is intentionally NOT one of the [_roleOptions] — admin accounts are
/// provisioned only by an existing admin or backend configuration. The
/// repository layer enforces this too (defense in depth), so even a
/// maliciously crafted request can't self-register as admin.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

const _roleOptions = [
  _RoleOption(UserRole.blind, 'Eye / Vision Assistance', 'Blind Person', Icons.visibility_off_rounded),
  _RoleOption(UserRole.nonSpeaking, 'Communication Assistance', 'Non-Speaking Person',
      Icons.record_voice_over_rounded),
  _RoleOption(UserRole.motorImpaired, 'Motor Assistance', 'Motor-Impaired Person',
      Icons.accessible_rounded),
  _RoleOption(UserRole.caregiver, 'Support', 'Caregiver', Icons.volunteer_activism_rounded),
];

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole? _selectedRole;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      setState(() => _errorMessage = 'Please select an accessibility role.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).register(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole!,
          );
      // Router redirect takes it from here (spec §3 flow: Account Created ->
      // Role Saved -> Login -> Role-Based Dashboard).
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.alert.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        child: Text(_errorMessage!, style: const TextStyle(color: AppColors.alert)),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    AppTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your phone number' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Password',
                      controller: _passwordController,
                      obscureText: true,
                      validator: (v) =>
                          (v == null || v.length < 8) ? 'Password must be at least 8 characters' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Confirm Password',
                      controller: _confirmPasswordController,
                      obscureText: true,
                      validator: (v) =>
                          (v != _passwordController.text) ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Accessibility Role', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    for (final option in _roleOptions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _RoleCard(
                          option: option,
                          selected: _selectedRole == option.role,
                          onTap: () => setState(() => _selectedRole = option.role),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: 'Create Account',
                      onPressed: _submit,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account?'),
                        TextButton(onPressed: () => context.pop(), child: const Text('Login')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final _RoleOption option;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forRole(option.role);
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.category}. ${option.title}',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: kMinTouchTarget + 24),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: selected ? accent : AppColors.border, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(option.icon, color: accent, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.category,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(option.title, style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? accent : AppColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
