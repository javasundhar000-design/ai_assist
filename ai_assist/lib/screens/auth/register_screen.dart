import 'package:flutter/material.dart';

import '../../models/emergency_contact.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  UserRole _selectedRole = UserRole.blind;
  bool _saving = false;

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Please enter a name.');
      return;
    }

    if (_selectedRole == UserRole.admin) {
      if (_pinController.text.trim().length < 4) {
        _showError('Admin PIN must be at least 4 digits.');
        return;
      }
    } else {
      if (_contactNameController.text.trim().isEmpty ||
          _contactPhoneController.text.trim().isEmpty) {
        _showError('Please add at least one emergency contact.');
        return;
      }
    }

    setState(() => _saving = true);

    final contacts = _selectedRole == UserRole.admin
        ? <EmergencyContact>[]
        : [
            EmergencyContact(
              name: _contactNameController.text.trim(),
              phone: _contactPhoneController.text.trim(),
            ),
          ];

    await AuthService.instance.register(
      name: name,
      role: _selectedRole,
      emergencyContacts: contacts,
      adminPin: _selectedRole == UserRole.admin ? _pinController.text.trim() : null,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Person')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Priya',
                ),
              ),
              const SizedBox(height: 24),

              const Text('Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                'This decides what this person sees when they log in.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 10),
              ...UserRole.values.map((role) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: _selectedRole == role
                          ? role.color.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _selectedRole = role),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(role.icon, color: role.color),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(role.label,
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(role.description,
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey.shade700)),
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

              const SizedBox(height: 8),

              if (_selectedRole == UserRole.admin) ...[
                const Text('Admin PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '4 to 6 digits',
                  ),
                ),
              ] else ...[
                const Text('Emergency Contact',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  'Who should be alerted if this person taps the SOS button?',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contactNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Contact name',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contactPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Contact phone number',
                  ),
                ),
              ],

              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
