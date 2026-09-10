import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/pose_garment_painter.dart';
import '../services/camera_image_converter.dart';
import 'capture_look_screen.dart';
import 'recommendations_screen.dart';

/// Full-screen smart-mirror try-on experience with **real** garment
/// tracking: a live camera feed is run through Google ML Kit's on-device
/// pose detector every frame, and the selected wardrobe item is drawn as a
/// silhouette warped to the wearer's actual detected shoulders/hips/knees
/// (see `PoseGarmentPainter`) — not a fixed icon sitting in the middle of
/// the screen. There's no real garment photo to texture-map (no licensed
/// photography is available here), so the rendered layer is a colored,
/// tracked silhouette rather than a photorealistic diffusion render; swap
/// the painter's path-building for a textured mesh once real garment
/// cutouts exist.
///
/// Voice: uses `speech_to_text`. Tapping the mic requests microphone
/// permission, starts listening, and matches the recognized phrase against
/// a small command grammar (see `_handleVoiceCommand`).
class TryOnScreen extends StatefulWidget {
  final bool embedded;
  final Outfit? initialOutfit;
  const TryOnScreen({super.key, this.embedded = false, this.initialOutfit});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  Future<void>? _cameraInitFuture;
  String? _cameraError;
  bool _streaming = false;

  late final PoseDetector _poseDetector =
      PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.stream));
  Pose? _pose;
  Size _rotatedImageSize = Size.zero;
  bool _detecting = false; // guards against overlapping async detection calls
  int _framesReceived = 0; // proves the image stream is actually delivering frames
  int _posesDetected = 0; // proves ML Kit is actually finding a body
  String? _detectionError;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _voiceStatus = '';

  int _selectedGarment = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _speech.initialize().then((available) {
      if (mounted) setState(() => _speechAvailable = available);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseDetector.close();
    _speech.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _cameraError = 'Camera permission denied. Enable it in system settings to use the smart mirror.');
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera found on this device.');
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      // ML Kit needs NV21 on Android / BGRA8888 on iOS — see CameraImageConverter.
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatformIsAndroid() ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );
      setState(() {
        _cameraController = controller;
        _cameraError = null;
        _cameraInitFuture = controller.initialize();
      });
      await _cameraInitFuture;
      if (!mounted) return;
      await _startPoseStream();
      setState(() {});
    } catch (e) {
      setState(() => _cameraError = 'Could not start the camera: $e');
    }
  }

  Future<void> _startPoseStream() async {
    final controller = _cameraController;
    if (controller == null || _streaming) return;
    _streaming = true;
    await controller.startImageStream(_onCameraFrame);
  }

  void _onCameraFrame(CameraImage image) {
    _framesReceived++;
    if (mounted && _framesReceived % 5 == 0) setState(() {}); // periodic refresh so the debug counter visibly moves without rebuilding every frame
    if (_detecting) return; // drop frames while a detection is in flight
    final controller = _cameraController;
    if (controller == null) return;
    _detecting = true;

    final inputImage = CameraImageConverter.toInputImage(
      image: image,
      camera: controller.description,
      deviceOrientation: controller.value.deviceOrientation,
    );
    final rotation = CameraImageConverter.rotationFor(controller.description, controller.value.deviceOrientation);

    if (inputImage == null || rotation == null) {
      _detecting = false;
      if (mounted) {
        setState(() => _detectionError =
            'Frame format ${image.format.raw} on ${image.planes.length} plane(s) didn\'t match what ML Kit expects for this platform.');
      }
      return;
    }

    _poseDetector.processImage(inputImage).then((poses) {
      if (!mounted) return;
      setState(() {
        _pose = poses.isNotEmpty ? poses.first : null;
        if (poses.isNotEmpty) _posesDetected++;
        _rotatedImageSize = CameraImageConverter.rotatedSize(image, rotation);
        _detectionError = null;
      });
    }).catchError((e) {
      if (mounted) setState(() => _detectionError = 'Pose detector error: $e');
    }).whenComplete(() => _detecting = false);
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      setState(() => _voiceStatus = 'Voice recognition is not available on this device.');
      return;
    }
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      setState(() => _voiceStatus = 'Microphone permission denied.');
      return;
    }
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    setState(() {
      _isListening = true;
      _voiceStatus = '';
    });
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() => _isListening = false);
          _handleVoiceCommand(result.recognizedWords);
        }
      },
    );
  }

  void _handleVoiceCommand(String phrase) {
    final p = phrase.toLowerCase();
    String response;

    if (p.contains('next')) {
      _cycleGarment(1);
      response = 'Showing the next item.';
    } else if (p.contains('previous') || p.contains('back')) {
      _cycleGarment(-1);
      response = 'Showing the previous item.';
    } else if (p.contains('capture') || p.contains('save look') || p.contains('take a picture')) {
      response = 'Capturing your look.';
      _capture();
    } else if (p.contains('wardrobe')) {
      response = 'Opening your wardrobe.';
    } else if (p.contains('formal')) {
      response = 'Showing formal outfits for you.';
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecommendationsScreen(initialOccasion: 'Formal')));
    } else if (p.contains('casual')) {
      response = 'Showing casual outfits for you.';
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecommendationsScreen(initialOccasion: 'Casual')));
    } else if (p.contains('recommend')) {
      response = 'Here are my top recommendations.';
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecommendationsScreen()));
    } else if (p.isEmpty) {
      response = "Sorry, I didn't catch that.";
    } else {
      response = 'Heard: "$phrase" — try "next outfit", "capture look", or "show casual outfits".';
    }
    setState(() => _voiceStatus = response);
  }

  void _cycleGarment(int delta) {
    final appState = context.read<AppState>();
    final count = appState.wardrobe.length;
    if (count == 0) return;
    setState(() => _selectedGarment = (_selectedGarment + delta) % count < 0 ? count - 1 : (_selectedGarment + delta) % count);
  }

  bool _capturing = false;

  Future<void> _capture() async {
    final appState = context.read<AppState>();
    final outfit = widget.initialOutfit ?? appState.allOutfits.first;
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized || _capturing) {
      await appState.recordLookCaptured(outfit.id);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CaptureLookScreen(outfit: outfit)));
      return;
    }

    setState(() => _capturing = true);
    String? savedPath;
    final wasStreaming = _streaming;
    try {
      // Most camera implementations can't take a still photo while an
      // image stream is active, so pause it, capture, then resume.
      if (wasStreaming) {
        await controller.stopImageStream();
        _streaming = false;
      }
      final photo = await controller.takePicture();
      final docsDir = await getApplicationDocumentsDirectory();
      final capturesDir = Directory('${docsDir.path}/captures');
      if (!await capturesDir.exists()) await capturesDir.create(recursive: true);
      final fileName = 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await File(photo.path).copy('${capturesDir.path}/$fileName');
      savedPath = saved.path;
    } catch (_) {
      // Camera hiccup — fall through and record the look without a photo
      // rather than blocking the user.
    } finally {
      if (wasStreaming) await _startPoseStream();
    }

    await appState.recordLookCaptured(outfit.id, capturedImagePath: savedPath);
    if (!mounted) return;
    setState(() => _capturing = false);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CaptureLookScreen(outfit: outfit, capturedImagePath: savedPath)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final garments = appState.wardrobe;
    final activeItem = garments.isNotEmpty ? garments[_selectedGarment % garments.length] : null;
    final isFrontCamera = _cameraController?.description.lensDirection == CameraLensDirection.front;

    final content = Stack(
      fit: StackFit.expand,
      children: [
        _buildCameraLayer(),

        // Real AR layer: garment silhouette warped to the live-detected pose.
        if (activeItem != null)
          Positioned.fill(
            child: CustomPaint(
              painter: PoseGarmentPainter(
                pose: _pose,
                imageSize: _rotatedImageSize,
                mirror: isFrontCamera,
                garmentColor: activeItem.color,
                category: activeItem.category,
                itemName: activeItem.name,
              ),
            ),
          ),

        if (_cameraController != null && _pose == null && _cameraError == null)
          Positioned(
            bottom: 210,
            left: 24,
            right: 24,
            child: GlassContainer(
              child: Text(
                'Step back so your shoulders and hips are in frame.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: Colors.white),
              ),
            ),
          ),

        // Diagnostics — read this first when something looks wrong. It
        // tells you exactly which stage is failing: no wardrobe item
        // selected, no camera frames arriving, frames arriving but in the
        // wrong format, or frames fine but no body detected.
        Positioned(
          top: 64,
          left: 8,
          right: 8,
          child: _DebugPanel(
            hasWardrobeItem: activeItem != null,
            framesReceived: _framesReceived,
            posesDetected: _posesDetected,
            detectionError: _detectionError,
            poseDetectedNow: _pose != null,
          ),
        ),

        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GlassContainer(
                borderRadius: AppRadii.pill,
                padding: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: widget.embedded ? null : () => Navigator.of(context).maybePop(),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
              AiBadge(
                label: _pose != null ? 'Tracking body' : 'Virtual Try-On',
                icon: _pose != null ? Icons.accessibility_new : Icons.center_focus_strong,
              ),
              Row(
                children: [
                  GlassContainer(
                    borderRadius: AppRadii.pill,
                    padding: const EdgeInsets.all(8),
                    child: InkWell(
                      onTap: _switchCamera,
                      child: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Positioned(
          right: 16,
          top: 120,
          child: Column(
            children: [
              _SideControl(
                icon: _isListening ? Icons.mic : Icons.mic_none_rounded,
                label: 'Voice',
                active: _isListening,
                onTap: _toggleListening,
              ),
            ],
          ),
        ),

        if (_isListening || _voiceStatus.isNotEmpty)
          Positioned(
            top: 120,
            left: 16,
            right: 90,
            child: GlassContainer(
              child: Text(
                _isListening ? '🎙 Listening...' : _voiceStatus,
                style: AppTextStyles.bodyStrong.copyWith(color: Colors.white),
              ),
            ),
          ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Column(
            children: [
              if (garments.isNotEmpty)
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: garments.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final selected = i == _selectedGarment;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedGarment = i),
                        child: Container(
                          width: 56,
                          decoration: BoxDecoration(
                            color: garments[i].color.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            border: Border.all(
                              color: selected ? AppColors.violet : Colors.white24,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Icon(garments[i].icon, color: Colors.white),
                        ),
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Your wardrobe is empty — add items to try them on.', style: AppTextStyles.body.copyWith(color: Colors.white70)),
                ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _cycleGarment(-1),
                    child: const GlassContainer(
                      borderRadius: AppRadii.pill,
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.chevron_left, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 28),
                  GestureDetector(
                    onTap: _capturing ? null : _capture,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white24, width: 4),
                      ),
                      child: _capturing
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.violet),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 28),
                  GestureDetector(
                    onTap: () => _cycleGarment(1),
                    child: const GlassContainer(
                      borderRadius: AppRadii.pill,
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.chevron_right, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) return content;
    return Scaffold(body: content);
  }

  Future<void> _switchCamera() async {
    final controller = _cameraController;
    if (controller == null) return;
    final cameras = await availableCameras();
    if (cameras.length < 2) return;
    final current = controller.description;
    final next = cameras.firstWhere((c) => c.lensDirection != current.lensDirection, orElse: () => current);

    await controller.stopImageStream();
    await controller.dispose();
    _streaming = false;
    _pose = null;

    final newController = CameraController(
      next,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: defaultTargetPlatformIsAndroid() ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    setState(() {
      _cameraController = newController;
      _cameraInitFuture = newController.initialize();
    });
    await _cameraInitFuture;
    if (!mounted) return;
    await _startPoseStream();
    setState(() {});
  }

  Widget _buildCameraLayer() {
    if (_cameraError != null) {
      return Container(
        color: AppColors.background,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined, color: Colors.white38, size: 48),
            const SizedBox(height: 16),
            Text(_cameraError!, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: Colors.white70)),
            const SizedBox(height: 16),
            OutlineActionButton(label: 'Retry', icon: Icons.refresh, onPressed: _initCamera),
          ],
        ),
      );
    }
    if (_cameraController == null || _cameraInitFuture == null) {
      return const ColoredBox(color: AppColors.background, child: Center(child: CircularProgressIndicator(color: AppColors.violet)));
    }
    return FutureBuilder<void>(
      future: _cameraInitFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ColoredBox(color: AppColors.background, child: Center(child: CircularProgressIndicator(color: AppColors.violet)));
        }
        if (snapshot.hasError) {
          return Container(
            color: AppColors.background,
            alignment: Alignment.center,
            child: Text('Camera error: ${snapshot.error}', style: AppTextStyles.body),
          );
        }
        return SizedBox.expand(child: CameraPreview(_cameraController!));
      },
    );
  }
}

bool defaultTargetPlatformIsAndroid() => defaultTargetPlatform == TargetPlatform.android;

class _DebugPanel extends StatelessWidget {
  final bool hasWardrobeItem;
  final int framesReceived;
  final int posesDetected;
  final String? detectionError;
  final bool poseDetectedNow;

  const _DebugPanel({
    required this.hasWardrobeItem,
    required this.framesReceived,
    required this.posesDetected,
    required this.detectionError,
    required this.poseDetectedNow,
  });

  @override
  Widget build(BuildContext context) {
    Color dot(bool ok) => ok ? AppColors.success : Colors.redAccent;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _dotIcon(dot(hasWardrobeItem)),
              const SizedBox(width: 6),
              Text('Wardrobe item selected: ${hasWardrobeItem ? "yes" : "NO — add one in Wardrobe first"}',
                  style: AppTextStyles.caption.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              _dotIcon(dot(framesReceived > 0)),
              const SizedBox(width: 6),
              Text('Camera frames received: $framesReceived',
                  style: AppTextStyles.caption.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              _dotIcon(dot(posesDetected > 0)),
              const SizedBox(width: 6),
              Text(
                'Body detected so far: $posesDetected time(s)${poseDetectedNow ? " (tracking now)" : ""}',
                style: AppTextStyles.caption.copyWith(color: Colors.white),
              ),
            ],
          ),
          if (detectionError != null) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                _dotIcon(Colors.redAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(detectionError!, style: AppTextStyles.caption.copyWith(color: Colors.redAccent)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _dotIcon(Color color) => Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _SideControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _SideControl({required this.icon, required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: active ? AppColors.violet : AppColors.surfaceGlass,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}
