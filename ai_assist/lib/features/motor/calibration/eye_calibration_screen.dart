import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/permission.dart';
import '../../../widgets/permission_guard.dart';

/// Spec §18: a simple, professional calibration flow. Real gaze tracking
/// requires a native plugin (e.g. platform camera + ML eye-tracking SDK);
/// this screen implements the full UX and progress state machine so it can
/// be wired to that plugin's callbacks later without restructuring the UI.
class EyeCalibrationScreen extends StatefulWidget {
  const EyeCalibrationScreen({super.key});

  @override
  State<EyeCalibrationScreen> createState() => _EyeCalibrationScreenState();
}

class _EyeCalibrationScreenState extends State<EyeCalibrationScreen> {
  bool _running = false;
  double _progress = 0;
  Timer? _timer;

  void _start() {
    setState(() {
      _running = true;
      _progress = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() => _progress += 0.05);
      if (_progress >= 1) {
        timer.cancel();
        setState(() => _running = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calibration complete.')),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      required: Permission.eyeCalibration,
      child: Scaffold(
        appBar: AppBar(title: const Text('Eye Calibration')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const Text(
                  '1. Sit comfortably.\n2. Look at the center of the screen.\n3. Follow the target.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                const Spacer(),
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40 + (_running ? _progress * 40 : 0),
                    height: 40 + (_running ? _progress * 40 : 0),
                    decoration: BoxDecoration(
                      color: AppColors.motor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.motor.withValues(alpha: 0.3),
                          blurRadius: 24,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (_running)
                  LinearProgressIndicator(
                    value: _progress.clamp(0, 1),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.motor),
                    onPressed: _start,
                    child: const Text('Start Calibration'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
