import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/permission.dart';
import '../../../services/gaze_calibration.dart';
import '../../../services/gaze_tracking_service.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/permission_guard.dart';

enum _Step { center, left, right, up, down, done }

const _stepOrder = [_Step.center, _Step.left, _Step.right, _Step.up, _Step.down];

extension on _Step {
  String get instruction {
    switch (this) {
      case _Step.center:
        return 'Look straight at the center of the screen';
      case _Step.left:
        return 'Turn your head to look as far left as comfortable';
      case _Step.right:
        return 'Turn your head to look as far right as comfortable';
      case _Step.up:
        return 'Tilt your head to look up';
      case _Step.down:
        return 'Tilt your head to look down';
      case _Step.done:
        return 'Calibration complete';
    }
  }
}

/// Spec §18, rebuilt on real head-pose tracking (see GazeTrackingService for
/// why this is head-pose, not true pupil-level gaze). Walks through 5
/// positions, holds the camera on each for ~1.5s, and averages the readings
/// into a GazeCalibrationData used by EyeKeyboardScreen to map your head
/// angle to an on-screen cursor position.
///
/// NOT verified against real camera hardware in the environment this was
/// written in. If face detection never finds a face, check lighting and
/// confirm the front camera preview below actually shows your face — if it
/// doesn't, camera permission or camera selection is the first thing to
/// check, not the calibration logic itself.
class EyeCalibrationScreen extends StatefulWidget {
  const EyeCalibrationScreen({super.key});

  @override
  State<EyeCalibrationScreen> createState() => _EyeCalibrationScreenState();
}

class _EyeCalibrationScreenState extends State<EyeCalibrationScreen> {
  final _service = GazeTrackingService();
  final _store = GazeCalibrationStore();
  StreamSubscription<HeadPose>? _subscription;

  bool _initializing = true;
  String? _errorMessage;
  int _stepIndex = 0;
  bool _capturing = false;
  double _captureProgress = 0;

  final Map<_Step, List<HeadPose>> _samples = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _service.start();
      _subscription = _service.poses.listen(_onPose);
      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _errorMessage = 'Could not access the front camera. Check camera permission in your '
              'phone\'s Settings -> Apps -> AI Assist -> Permissions, then reopen this screen.';
        });
      }
    }
  }

  void _onPose(HeadPose pose) {
    if (!_capturing) return;
    final step = _stepOrder[_stepIndex];
    (_samples[step] ??= []).add(pose);
  }

  Future<void> _captureCurrentStep() async {
    final step = _stepOrder[_stepIndex];
    _samples[step] = [];
    setState(() {
      _capturing = true;
      _captureProgress = 0;
    });

    const totalMs = 1500;
    const tickMs = 50;
    for (var elapsed = 0; elapsed < totalMs; elapsed += tickMs) {
      await Future.delayed(const Duration(milliseconds: tickMs));
      if (!mounted) return;
      setState(() => _captureProgress = elapsed / totalMs);
    }

    if (!mounted) return;
    setState(() {
      _capturing = false;
      _captureProgress = 1;
    });

    final collected = _samples[step] ?? [];
    if (collected.isEmpty) {
      setState(() => _errorMessage =
          'No face detected during that capture. Make sure your face is centered in the '
          'preview and well lit, then try again.');
      return;
    }
    setState(() => _errorMessage = null);

    if (_stepIndex < _stepOrder.length - 1) {
      setState(() => _stepIndex++);
    } else {
      await _finish();
    }
  }

  double _average(List<HeadPose> poses, double Function(HeadPose) selector) {
    if (poses.isEmpty) return 0;
    return poses.map(selector).reduce((a, b) => a + b) / poses.length;
  }

  Future<void> _finish() async {
    final center = _samples[_Step.center] ?? [];
    final left = _samples[_Step.left] ?? [];
    final right = _samples[_Step.right] ?? [];
    final up = _samples[_Step.up] ?? [];
    final down = _samples[_Step.down] ?? [];

    final data = GazeCalibrationData(
      yawCenter: _average(center, (p) => p.yawDegrees),
      yawLeft: _average(left, (p) => p.yawDegrees),
      yawRight: _average(right, (p) => p.yawDegrees),
      pitchCenter: _average(center, (p) => p.pitchDegrees),
      pitchUp: _average(up, (p) => p.pitchDegrees),
      pitchDown: _average(down, (p) => p.pitchDegrees),
    );
    await _store.save(data);
    if (!mounted) return;
    setState(() => _stepIndex = _stepOrder.length); // moves to "done" state
  }

  Future<void> _retry() async {
    setState(() {
      _stepIndex = 0;
      _samples.clear();
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      required: Permission.eyeCalibration,
      child: Scaffold(
        appBar: AppBar(title: const Text('Eye Calibration')),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _service.controller == null) {
      return ErrorView(message: _errorMessage!, onRetry: _init);
    }

    final isDone = _stepIndex >= _stepOrder.length;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          if (_service.controller != null)
            AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: CameraPreview(_service.controller!),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          if (isDone) ...[
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
            const SizedBox(height: AppSpacing.sm),
            Text('Calibration complete', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Head-tracking is now calibrated to you. Open the Eye-Controlled Keyboard and '
              'turn on Gaze Control to try it.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: _retry, child: const Text('Recalibrate')),
          ] else ...[
            Text('Step ${_stepIndex + 1} of ${_stepOrder.length}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(_stepOrder[_stepIndex].instruction,
                style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Text(_errorMessage!, textAlign: TextAlign.center),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_capturing)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _captureProgress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Hold steady...'),
                ],
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.motor),
                onPressed: _captureCurrentStep,
                child: const Text('Capture This Position'),
              ),
          ],
        ],
      ),
    );
  }
}
