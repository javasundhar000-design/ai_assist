import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    // Real check: has this device already got a saved session? Route
    // straight to Home if so, otherwise to Login.
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      final isLoggedIn = context.read<AppState>().isLoggedIn;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => isLoggedIn ? const HomeScreen() : const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.1,
                  colors: [AppColors.violet.withOpacity(0.18), AppColors.background],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                ShaderMask(
                  shaderCallback: (bounds) => AppColors.logoGradient.createShader(bounds),
                  child: Text(
                    'AURA',
                    style: AppTextStyles.display.copyWith(fontSize: 44, color: Colors.white, letterSpacing: 4),
                  ),
                ),
                Text(
                  'STYLIST AI',
                  style: AppTextStyles.h2.copyWith(letterSpacing: 6, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Text(
                  'AI-Powered Virtual\nSmart Dressing Assistant',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final glow = 0.35 + (_pulseController.value * 0.25);
                        return Container(
                          width: 190,
                          height: 320,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(140),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.magenta.withOpacity(glow),
                                blurRadius: 80,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.checkroom,
                            size: 160,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.violet),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
