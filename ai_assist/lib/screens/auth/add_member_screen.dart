import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../services/family_service.dart';
import '../../theme/app_theme.dart';

class AddMemberScreen extends StatefulWidget {
  final String familyUid;

  const AddMemberScreen({super.key, required this.familyUid});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _nameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  // Members are always Blind, Non-Speaking, or Motor — caregivers are
  // real Firebase Auth accounts, created via sign-up, not added here.
  static const _memberRoles = [UserRole.blind, UserRole.nonSpeaking, UserRole.motor];

  UserRole _selectedRole = UserRole.blind;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final contactName = _contactNameController.text.trim();
    final contactPhone = _contactPhoneController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter a name.');
      return;
    }
    if (contactName.isEmpty || contactPhone.isEmpty) {
      setState(() => _error = 'Please add an emergency contact for this person.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await FamilyService.instance.addMember(
        familyUid: widget.familyUid,
        name: name,
        role: _selectedRole,
        emergencyContacts: [
          {'name': contactName, 'phone': contactPhone, 'relation': 'Caregiver'},
        ],
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Couldn\'t save. Check your internet connection and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) => setState(() => _error = message);

  @override
  void dispose() {
    _nameController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a member')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Name', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'e.g. Priya'),
              ),
              const SizedBox(height: 24),

              Text('Which mode do they need?', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'This is the only screen they\'ll see when they join with the family code.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ..._memberRoles.map((role) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: _selectedRole == role
                          ? role.color.withValues(alpha: 0.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => _selectedRole = role),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedRole == role ? role.color : AppColors.mist,
                              width: _selectedRole == role ? 1.6 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(role.icon, color: role.color),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(role.label,
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text(role.description,
                                        style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                ),
                              ),
                              Radio<UserRole>(
                                value: role,
                                groupValue: _selectedRole,
                                onChanged: (r) => setState(() => _selectedRole = r!),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )),

              const SizedBox(height: 12),
              Text('Emergency contact', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Who should be texted if this person taps the SOS button?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contactNameController,
                decoration: const InputDecoration(labelText: 'Contact name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contactPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact phone number'),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.alert.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppColors.alert)),
                ),
              ],

              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save member'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
