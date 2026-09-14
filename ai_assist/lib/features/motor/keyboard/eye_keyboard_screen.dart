import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/permission.dart';
import '../../../services/gaze_calibration.dart';
import '../../../services/gaze_tracking_service.dart';
import '../../../widgets/permission_guard.dart';

const _rows = [
  'QWERTYUIOP',
  'ASDFGHJKL',
  'ZXCVBNM',
];

const _allKeyLabels = [
  'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P',
  'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L',
  'Z', 'X', 'C', 'V', 'B', 'N', 'M',
  '⌫', 'Space', 'Enter',
];

/// Spec §19: large-key accessible keyboard with dwell selection.
///
/// Two input modes, sharing the same dwell-selection state machine:
///  - Touch (default): press-and-hold a key to dwell-select it, or tap it
///    quickly to select immediately (see _handleTapUp).
///  - Gaze Control: uses GazeTrackingService's head-pose stream, mapped
///    through your calibration from EyeCalibrationScreen, to move a cursor
///    and dwell-select whichever key it rests on. Requires calibrating
///    first. This is head-pose tracking, not true pupil-level gaze — see
///    GazeTrackingService's doc comment for what that means in practice.
///
/// NOT verified against real camera hardware in the environment this was
/// written in.
class EyeKeyboardScreen extends ConsumerStatefulWidget {
  const EyeKeyboardScreen({super.key});

  @override
  ConsumerState<EyeKeyboardScreen> createState() => _EyeKeyboardScreenState();
}

class _EyeKeyboardScreenState extends ConsumerState<EyeKeyboardScreen> {
  final _buffer = StringBuffer();
  String? _dwellingKey;
  double _dwellProgress = 0;
  Timer? _dwellTimer;
  double dwellTimeMs = 800;
  bool _consumedByDwell = false;

  // Gaze control
  final _gazeService = GazeTrackingService();
  final _calibrationStore = GazeCalibrationStore();
  StreamSubscription<HeadPose>? _gazeSubscription;
  GazeCalibrationData? _calibration;
  bool _gazeEnabled = false;
  bool _gazeStarting = false;
  Offset? _cursorLocal;
  final _gridKey = GlobalKey();
  final Map<String, GlobalKey> _keyKeys = {for (final label in _allKeyLabels) label: GlobalKey()};

  @override
  void initState() {
    super.initState();
    _calibrationStore.load().then((data) {
      if (mounted) setState(() => _calibration = data);
    });
  }

  // ---- Dwell state machine (shared by touch and gaze) ----

  void _beginDwell(String key) {
    _consumedByDwell = false;
    _dwellTimer?.cancel();
    setState(() {
      _dwellingKey = key;
      _dwellProgress = 0;
    });
    const tick = Duration(milliseconds: 40);
    _dwellTimer = Timer.periodic(tick, (timer) {
      setState(() => _dwellProgress += tick.inMilliseconds / dwellTimeMs);
      if (_dwellProgress >= 1) {
        timer.cancel();
        _consumedByDwell = true;
        _selectKey(key);
      }
    });
  }

  void _cancelDwell() {
    _dwellTimer?.cancel();
    setState(() {
      _dwellingKey = null;
      _dwellProgress = 0;
    });
  }

  /// Normal touch tap release: types immediately if the dwell timer hasn't
  /// already fired for this press (see the doc comment on the class for
  /// why — a quick tap should behave like an ordinary keyboard).
  void _handleTapUp(String key) {
    if (_consumedByDwell) return;
    _cancelDwell();
    _selectKey(key);
  }

  void _selectKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_buffer.isNotEmpty) {
          final s = _buffer.toString();
          _buffer
            ..clear()
            ..write(s.substring(0, s.length - 1));
        }
      } else if (key == 'Space') {
        _buffer.write(' ');
      } else if (key == 'Enter') {
        ref.read(ttsServiceProvider).speak(_buffer.toString());
      } else {
        _buffer.write(key);
      }
      _dwellingKey = null;
      _dwellProgress = 0;
    });
  }

  // ---- Gaze control ----

  Future<void> _toggleGaze() async {
    if (_gazeEnabled) {
      await _stopGaze();
      return;
    }
    if (_calibration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calibrate first from the Eye Calibration screen, then come back here.'),
        ),
      );
      return;
    }
    setState(() => _gazeStarting = true);
    try {
      await _gazeService.start();
      _gazeSubscription = _gazeService.poses.listen(_onGazePose);
      if (!mounted) return;
      setState(() {
        _gazeEnabled = true;
        _gazeStarting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _gazeStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not access the front camera. Check camera permission for AI Assist.'),
        ),
      );
    }
  }

  Future<void> _stopGaze() async {
    await _gazeSubscription?.cancel();
    _gazeSubscription = null;
    await _gazeService.stop();
    if (!mounted) return;
    setState(() {
      _gazeEnabled = false;
      _cursorLocal = null;
    });
    _cancelDwell();
  }

  void _onGazePose(HeadPose pose) {
    final calibration = _calibration;
    if (calibration == null) return;
    final gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null || !gridBox.hasSize) return;

    final normalized = calibration.normalize(pose);
    final localPoint = Offset(
      normalized.dx * gridBox.size.width,
      normalized.dy * gridBox.size.height,
    );

    String? hoveredKey;
    for (final entry in _keyKeys.entries) {
      final keyBox = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (keyBox == null || !keyBox.hasSize) continue;
      final topLeft = keyBox.localToGlobal(Offset.zero, ancestor: gridBox);
      final rect = topLeft & keyBox.size;
      if (rect.contains(localPoint)) {
        hoveredKey = entry.key;
        break;
      }
    }

    if (!mounted) return;
    setState(() => _cursorLocal = localPoint);

    // Note: if you keep looking at a key after it's selected, this will
    // immediately start dwelling on it again rather than waiting for you to
    // look away first. That's a reasonable v1 default (mirrors how the
    // touch dwell behaves) but a natural next improvement is a short
    // cooldown on the just-selected key so continuous fixation doesn't
    // repeat-type it.
    if (hoveredKey != _dwellingKey) {
      if (hoveredKey == null) {
        _cancelDwell();
      } else {
        _beginDwell(hoveredKey);
      }
    }
  }

  Widget _key(String label, {double flex = 1}) {
    final isDwelling = _dwellingKey == label;
    return Expanded(
      flex: flex.round(),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: GestureDetector(
          onTapDown: (_) => _beginDwell(label),
          onTapCancel: _cancelDwell,
          onTapUp: (_) => _handleTapUp(label),
          child: Container(
            key: _keyKeys[label],
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDwelling
                  ? Color.lerp(Colors.white, AppColors.motor, _dwellProgress)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDwelling && _dwellProgress > 0.5 ? Colors.white : AppColors.textPrimary,
                )),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    _gazeSubscription?.cancel();
    _gazeService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      required: Permission.eyeControlledKeyboard,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Eye-Controlled Keyboard'),
          actions: [
            IconButton(
              icon: _gazeStarting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_gazeEnabled ? Icons.visibility_rounded : Icons.visibility_off_outlined,
                      color: _gazeEnabled ? AppColors.motor : null),
              tooltip: _gazeEnabled ? 'Turn off Gaze Control' : 'Turn on Gaze Control',
              onPressed: _gazeStarting ? null : _toggleGaze,
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Dwell settings',
              onPressed: _showSettings,
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _buffer.isEmpty ? 'Message will appear here...' : _buffer.toString(),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                if (_gazeEnabled) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, size: 14, color: AppColors.motor),
                      const SizedBox(width: 4),
                      Text('Gaze Control on — look at a key and hold',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.motor)),
                      const Spacer(),
                      if (_gazeService.controller != null)
                        SizedBox(
                          width: 48,
                          height: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CameraPreview(_gazeService.controller!),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        key: _gridKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            for (final row in _rows)
                              Row(children: [for (final c in row.split('')) _key(c)]),
                            Row(children: [
                              _key('⌫', flex: 2),
                              _key('Space', flex: 4),
                              _key('Enter', flex: 2),
                            ]),
                          ],
                        ),
                      ),
                      if (_gazeEnabled && _cursorLocal != null)
                        Positioned(
                          left: _cursorLocal!.dx - 12,
                          top: _cursorLocal!.dy - 12,
                          child: IgnorePointer(
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.motor.withValues(alpha: 0.55),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dwell Time: ${dwellTimeMs.round()} ms',
                  style: Theme.of(context).textTheme.titleLarge),
              Slider(
                min: 400,
                max: 2000,
                divisions: 16,
                value: dwellTimeMs,
                onChanged: (v) => setSheetState(() => dwellTimeMs = v),
              ),
              if (_calibration == null) ...[
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Gaze Control needs calibration first — open Eye Calibration from the Motor '
                  'dashboard.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    ).then((_) => setState(() {}));
  }
}
