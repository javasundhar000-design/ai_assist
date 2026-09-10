import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/accessibility/accessibility_settings.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../communication/prediction/prediction_service.dart';
import '../gaze/gaze_service.dart';

/// Section 23/24: large on-screen keyboard where the currently gazed-at
/// key is highlighted, selected via configurable dwell time (or blink,
/// per settings), and full sentence suggestions can be selected the same
/// way — this is the key demonstration feature per Section 24.
class EyeKeyboardScreen extends ConsumerStatefulWidget {
  const EyeKeyboardScreen({super.key});

  @override
  ConsumerState<EyeKeyboardScreen> createState() => _EyeKeyboardScreenState();
}

const _rows = [
  ['A', 'B', 'C', 'D', 'E'],
  ['F', 'G', 'H', 'I', 'J'],
  ['K', 'L', 'M', 'N', 'O'],
  ['P', 'Q', 'R', 'S', 'T'],
  ['U', 'V', 'W', 'X', 'Y'],
  ['Z', 'SPACE', 'BACKSPACE', 'SPEAK'],
];

class _KeyTarget {
  final GlobalKey key = GlobalKey();
  final String label;
  _KeyTarget(this.label);
}

class _EyeKeyboardScreenState extends ConsumerState<EyeKeyboardScreen> {
  final List<_KeyTarget> _keys = _rows.expand((r) => r).map(_KeyTarget.new).toList();
  String _text = '';
  String? _focusedLabel;
  double _dwellProgress = 0;
  Timer? _dwellTimer;
  bool _cameraFailed = false;
  List<String> _sentenceSuggestions = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _startGaze();
    TextToSpeechService.instance.speak('Eye keyboard ready. Look at a letter to select it.');
  }

  Future<void> _startGaze() async {
    try {
      final calibration = LocalStorageService.instance.getCalibration();
      if (calibration != null) {
        GazeService.instance.setCalibration(GazeCalibration.fromJson(calibration));
      }
      final controller = await GazeService.instance.startFrontCamera();
      controller.startImageStream((image) {
        GazeService.instance.processFrame(image, _onGaze);
      });
    } catch (_) {
      setState(() => _cameraFailed = true);
      TextToSpeechService.instance.speak(AppStrings.errEyeTracking);
    }
  }

  void _onGaze(GazePoint point) {
    final settings = ref.read(accessibilitySettingsProvider);

    if (settings.blinkSelectionEnabled && point.isBlinking && _focusedLabel != null) {
      _selectKey(_focusedLabel!);
      return;
    }

    // Map normalized gaze point to the nearest key's screen position.
    _KeyTarget? nearest;
    double bestDist = double.infinity;
    for (final target in _keys) {
      final ctx = target.key.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final screenSize = MediaQuery.of(context).size;
      final center = box.localToGlobal(box.size.center(Offset.zero));
      final normX = center.dx / screenSize.width;
      final normY = center.dy / screenSize.height;
      final dist = (normX - point.x).abs() + (normY - point.y).abs();
      if (dist < bestDist) {
        bestDist = dist;
        nearest = target;
      }
    }

    if (nearest == null) return;
    if (nearest.label != _focusedLabel) {
      _dwellTimer?.cancel();
      setState(() {
        _focusedLabel = nearest!.label;
        _dwellProgress = 0;
      });
      if (!settings.blinkSelectionEnabled) {
        _startDwellTimer(nearest.label, settings.dwellTimeMs);
      }
    }
  }

  void _startDwellTimer(String label, int dwellMs) {
    const tick = 50;
    var elapsed = 0;
    _dwellTimer = Timer.periodic(const Duration(milliseconds: tick), (timer) {
      elapsed += tick;
      setState(() => _dwellProgress = (elapsed / dwellMs).clamp(0.0, 1.0).toDouble());
      if (elapsed >= dwellMs) {
        timer.cancel();
        _selectKey(label);
      }
    });
  }

  void _selectKey(String label) {
    _dwellTimer?.cancel();
    setState(() {
      _dwellProgress = 0;
      switch (label) {
        case 'SPACE':
          _text += ' ';
          break;
        case 'BACKSPACE':
          if (_text.isNotEmpty) _text = _text.substring(0, _text.length - 1);
          break;
        case 'SPEAK':
          if (_text.trim().isNotEmpty) {
            TextToSpeechService.instance.speak(_text);
            LocalStorageService.instance.addRecentMessage(_text);
          }
          return;
        default:
          _text += label;
      }
      _sentenceSuggestions = PredictionService.instance.suggestSentences(_text);
    });
  }

  void _selectSentence(String sentence) {
    setState(() {
      _text = sentence;
      _sentenceSuggestions = [];
    });
    TextToSpeechService.instance.speak(sentence);
    LocalStorageService.instance.addRecentMessage(sentence);
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    GazeService.instance.stop();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Eye Keyboard')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              if (_cameraFailed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(AppStrings.errEyeTracking, style: TextStyle(color: scheme.error)),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _text.isEmpty ? 'Start typing…' : _text,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
              if (_sentenceSuggestions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _sentenceSuggestions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => FilledButton(
                        onPressed: () => _selectSentence(_sentenceSuggestions[i]),
                        child: Text(_sentenceSuggestions[i]),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  children: _rows
                      .map((row) => Expanded(
                            child: Row(
                              children: row.map((label) {
                                final target = _keys.firstWhere((k) => k.label == label);
                                final focused = _focusedLabel == label;
                                return Expanded(
                                  flex: label.length > 1 ? 2 : 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Container(
                                      key: target.key,
                                      decoration: BoxDecoration(
                                        color: focused ? scheme.primary : scheme.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(12),
                                        border: focused
                                            ? Border.all(color: scheme.primary, width: 3)
                                            : null,
                                      ),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Text(
                                              label,
                                              style: TextStyle(
                                                fontSize: label.length > 1 ? 13 : 22,
                                                fontWeight: FontWeight.w800,
                                                color: focused ? Colors.white : scheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          if (focused && _dwellProgress > 0)
                                            Positioned(
                                              bottom: 0,
                                              left: 0,
                                              right: 0,
                                              child: LinearProgressIndicator(
                                                value: _dwellProgress,
                                                minHeight: 4,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
