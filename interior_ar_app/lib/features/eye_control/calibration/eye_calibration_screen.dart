import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../gaze/gaze_service.dart';

/// Section 22: the dot moves through six fixed points; the user follows
/// it with their eyes/head, and we record the head-pose extremes at each
/// point so [GazeService] can map future poses back to screen
/// coordinates for this specific user.
class EyeCalibrationScreen extends StatefulWidget {
  const EyeCalibrationScreen({super.key});

  @override
  State<EyeCalibrationScreen> createState() => _EyeCalibrationScreenState();
}

enum _CalPoint { topLeft, topCenter, topRight, center, bottomLeft, bottomRight }

class _EyeCalibrationScreenState extends State<EyeCalibrationScreen> {
  static const _sequence = [
    _CalPoint.topLeft,
    _CalPoint.topCenter,
    _CalPoint.topRight,
    _CalPoint.center,
    _CalPoint.bottomLeft,
    _CalPoint.bottomRight,
  ];

  int _index = 0;
  final Map<_CalPoint, (double yaw, double pitch)> _readings = {};
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    // Gaze estimation assumes a fixed portrait orientation (see
    // GazeService.rotation) — lock it for the duration of this screen so
    // that assumption actually holds on real devices.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _startCamera();
    TextToSpeechService.instance.speak('Follow the dot with your eyes. Hold still at each point.');
  }

  Future<void> _startCamera() async {
    try {
      final controller = await GazeService.instance.startFrontCamera();
      controller.startImageStream((image) {
        GazeService.instance.processFrameForCalibration(
          image,
          (yaw, pitch) => _readings[_sequence[_index]] = (yaw, pitch),
        );
      });
      if (mounted) setState(() => _cameraReady = true);
    } catch (_) {
      // Calibration remains usable with fallback defaults if camera fails.
    }
  }

  void _confirmPoint() {
    if (_index < _sequence.length - 1) {
      setState(() => _index++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final yaws = _readings.values.map((r) => r.$1).toList();
    final pitches = _readings.values.map((r) => r.$2).toList();
    final calibration = yaws.isEmpty
        ? GazeCalibration.fallback
        : GazeCalibration(
            minYaw: yaws.reduce((a, b) => a < b ? a : b),
            maxYaw: yaws.reduce((a, b) => a > b ? a : b),
            minPitch: pitches.reduce((a, b) => a < b ? a : b),
            maxPitch: pitches.reduce((a, b) => a > b ? a : b),
          );

    await LocalStorageService.instance.saveCalibration(calibration.toJson());
    GazeService.instance.setCalibration(calibration);
    await GazeService.instance.stop();

    await TextToSpeechService.instance.speak('Calibration complete.');
    if (mounted) Navigator.of(context).pop(true);
  }

  Alignment _alignmentFor(_CalPoint p) {
    switch (p) {
      case _CalPoint.topLeft:
        return const Alignment(-0.85, -0.85);
      case _CalPoint.topCenter:
        return const Alignment(0, -0.85);
      case _CalPoint.topRight:
        return const Alignment(0.85, -0.85);
      case _CalPoint.center:
        return Alignment.center;
      case _CalPoint.bottomLeft:
        return const Alignment(-0.85, 0.85);
      case _CalPoint.bottomRight:
        return const Alignment(0.85, 0.85);
    }
  }

  @override
  void dispose() {
    GazeService.instance.stop();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Text(
                'Point ${_index + 1} of ${_sequence.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              alignment: _alignmentFor(_sequence[_index]),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 6)],
                ),
              ),
            ),
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  if (!_cameraReady)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('Starting camera…', style: TextStyle(color: Colors.white70)),
                    ),
                  ElevatedButton(
                    onPressed: _confirmPoint,
                    child: Text(_index == _sequence.length - 1 ? 'FINISH' : "I'M LOOKING AT IT"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
