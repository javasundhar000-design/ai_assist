import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/permission.dart';
import '../../../widgets/permission_guard.dart';

const _rows = [
  'QWERTYUIOP',
  'ASDFGHJKL',
  'ZXCVBNM',
];

/// Spec §19: large-key accessible keyboard with dwell selection.
///
/// True gaze input requires a native eye-tracking SDK/camera pipeline. This
/// screen implements the full dwell-selection *interaction model* — look at
/// (press-and-hold on) a key, dwell for a configurable duration, key fires —
/// using touch-and-hold as the stand-in input source, so the moment a native
/// gaze plugin is wired in, it only needs to drive the same `_beginDwell` /
/// `_cancelDwell` calls this UI already uses.
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

  void _beginDwell(String key) {
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

  Widget _key(String label, {double flex = 1}) {
    final isDwelling = _dwellingKey == label;
    return Expanded(
      flex: flex.round(),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: GestureDetector(
          onTapDown: (_) => _beginDwell(label),
          onTapCancel: _cancelDwell,
          onTapUp: (_) => _cancelDwell(),
          child: Container(
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
                const SizedBox(height: AppSpacing.md),
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
            ],
          ),
        ),
      ),
    ).then((_) => setState(() {}));
  }
}
