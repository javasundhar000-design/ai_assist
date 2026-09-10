import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/local_storage_service.dart';

/// Local session re-entry. Since there's no backend, "login" really means
/// "re-open the saved on-device profile" — matching Section 4's returning
/// user flow (Splash → Check Local Session → Dashboard). This screen
/// mainly exists for the case where the user chose to log out.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = LocalStorageService.instance;
    final user = storage.getCurrentUser();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.accessibility_new_rounded, size: 72),
              const SizedBox(height: 20),
              Text(
                user != null ? 'Welcome back, ${user.name}!' : 'Welcome to ${AppStrings.appName}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 32),
              if (user != null)
                ElevatedButton(
                  onPressed: () async {
                    await storage.saveUser(user);
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil(AppRoutes.dashboard, (_) => false);
                    }
                  },
                  child: const Text('CONTINUE'),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.registration),
                child: Text(user != null ? 'Create a new account' : 'Get started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
