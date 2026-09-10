import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/emergency_service.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../auth/profile_select_screen.dart';

/// MOTOR MODE — implementation note:
///
/// True camera-based eye/gaze tracking requires a native SDK (e.g. Google's
/// MediaPipe Face Landmarker, or a platform-specific gaze library) wired in
/// through platform channels — that's beyond a single Dart file and belongs
/// in its own native-integration milestone.
///
/// What ships here instead is "switch scanning": the standard accessible
/// input pattern used by real AAC / motor-accessibility apps (e.g. Grid,
/// TD Snap) for anyone who can reliably trigger only ONE input — a single
/// tap anywhere on screen, a switch button, a sip-and-puff switch mapped to
/// a key, or a bluetooth switch mapped to spacebar/enter.
///
/// How it works: each tile highlights in sequence automatically. The user
/// triggers their one input (tap the screen / press the mapped key) while
/// their target is highlighted to select it. Scan speed is configurable.
/// This is a drop-in upgrade point: swap `_advanceScan` triggers for a
/// gaze-based "dwell" signal once real eye tracking is added, and the rest
/// of the UI needs no change.
class ScanModeScreen extends StatefulWidget {
  const ScanModeScreen({super.key});

  @override
  State<ScanModeScreen> createState() => _ScanModeScreenState();
}

class _ScanTile {
  final String label;
  final IconData icon;
  final VoidCallback action;
  const _ScanTile(this.label, this.icon, this.action);
}

class _ScanModeScreenState extends State<ScanModeScreen> {
  Timer? _timer;
  int _index = 0;
  int _scanSpeedMs = 1500;
  bool _paused = false;
  UserProfile? _profile;

  late final List<_ScanTile> _tiles;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tiles = [
      _ScanTile('Yes', Icons.check_circle, () => _speak('Yes.')),
      _ScanTile('No', Icons.cancel, () => _speak('No.')),
      _ScanTile('Emergency', Icons.emergency, _triggerEmergency),
      _ScanTile('Water', Icons.local_drink, () => _speak('Could I have some water, please?')),
      _ScanTile('Pain', Icons.sick, () => _speak('I am in pain.')),
      _ScanTile('Thank you', Icons.favorite, () => _speak('Thank you.')),
      _ScanTile('Slower', Icons.slow_motion_video, _decreaseSpeed),
      _ScanTile('Faster', Icons.fast_forward, _increaseSpeed),
    ];
    _loadSpeed();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.instance.getCurrentProfile();
    setState(() => _profile = profile);
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ProfileSelectScreen()),
      (route) => false,
    );
  }

  /// Selecting the "Emergency" tile through the normal scan-and-select flow
  /// IS the accessible SOS action here — a motor-impaired user relies on
  /// this same single-switch selection for everything else, so the
  /// emergency action must work through the identical mechanism rather
  /// than requiring a separate precise tap elsewhere on screen.
  Future<void> _triggerEmergency() async {
    if (_profile == null) return;
    await EmergencyService.instance.triggerAlert(_profile!);
  }

  Future<void> _loadSpeed() async {
    final ms = await StorageService.instance.loadScanSpeedMs();
    setState(() => _scanSpeedMs = ms);
    _startScan();
  }

  void _startScan() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _scanSpeedMs), (_) {
      if (_paused) return;
      setState(() {
        _index = (_index + 1) % _tiles.length;
      });
    });
  }

  void _speak(String text) {
    TtsService.instance.speak(text);
  }

  void _increaseSpeed() {
    setState(() => _scanSpeedMs = (_scanSpeedMs - 300).clamp(500, 4000));
    StorageService.instance.saveScanSpeedMs(_scanSpeedMs);
    _startScan();
  }

  void _decreaseSpeed() {
    setState(() => _scanSpeedMs = (_scanSpeedMs + 300).clamp(500, 4000));
    StorageService.instance.saveScanSpeedMs(_scanSpeedMs);
    _startScan();
  }

  /// The single "select" action — call this from ANY input source:
  /// full-screen tap, a mapped hardware switch, or (later) a gaze dwell.
  void _selectCurrent() {
    setState(() => _paused = true);
    final tile = _tiles[_index];
    tile.action();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _paused = false);
    });
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.enter)) {
      _selectCurrent();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motor Mode'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Log out'),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('${_scanSpeedMs}ms')),
          ),
        ],
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: GestureDetector(
          // The entire screen is the "switch" — a single tap anywhere
          // selects whatever tile is currently highlighted. This mirrors
          // how a physical single-button switch is used with scanning.
          onTap: _selectCurrent,
          behavior: HitTestBehavior.opaque,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Tap anywhere, or press Space/Enter, to select the highlighted tile.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: _tiles.length,
                      itemBuilder: (context, i) {
                        final tile = _tiles[i];
                        final isActive = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.5),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                tile.icon,
                                size: 40,
                                color: isActive ? Colors.white : Colors.black54,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tile.label,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
