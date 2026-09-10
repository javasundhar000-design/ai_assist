import 'package:flutter/material.dart';

import '../../services/family_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import 'choose_member_screen.dart';

class JoinFamilyScreen extends StatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _joinFamily() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => _error = 'Enter the 6-character code your caregiver gave you.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uid = await FamilyService.instance.resolveCode(code);
      if (uid == null) {
        setState(() => _error = 'That code doesn\'t match any family. Double check with your caregiver.');
        return;
      }

      await SessionService.instance.saveFamilyUid(uid);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChooseMemberScreen(familyUid: uid)),
      );
    } catch (e) {
      setState(() => _error = 'Couldn\'t connect. Check your internet connection and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a family')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ask your caregiver for the 6-character code shown on '
                'their Admin Dashboard.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 6),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: 'A1B2C3',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
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
                onPressed: _loading ? null : _joinFamily,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
