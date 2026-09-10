import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/widgets/app_state_views.dart';
import '../providers/camera_provider.dart';
import '../providers/scan_session_provider.dart';

class RoomScannerScreen extends ConsumerWidget {
  final String projectId;
  const RoomScannerScreen({super.key, required this.projectId});

  Future<void> _capture(BuildContext context, WidgetRef ref,
      CameraController controller) async {
    if (!controller.value.isInitialized || controller.value.isTakingPicture) {
      return;
    }
    try {
      final file = await controller.takePicture();
      ref.read(scanSessionProvider.notifier).addImage(file);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture photo. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerAsync = ref.watch(cameraControllerProvider);
    final capturedImages = ref.watch(scanSessionProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Room'),
        actions: [
          if (capturedImages.isNotEmpty)
            TextButton(
              onPressed: () =>
                  context.push('/projects/$projectId/scan-preview'),
              child: Text(
                'Review (${capturedImages.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: controllerAsync.when(
        loading: () => const AppLoadingView(label: 'Starting camera…'),
        error: (error, st) => _CameraErrorView(error: error),
        data: (controller) => _CameraReady(
          controller: controller,
          capturedImages: capturedImages,
          onCapture: () => _capture(context, ref, controller),
          onRetakeLast: capturedImages.isEmpty
              ? null
              : () => ref
                  .read(scanSessionProvider.notifier)
                  .removeAt(capturedImages.length - 1),
          onDone: capturedImages.isEmpty
              ? null
              : () => context.push('/projects/$projectId/scan-preview'),
        ),
      ),
    );
  }
}

class _CameraReady extends StatelessWidget {
  final CameraController controller;
  final List<XFile> capturedImages;
  final VoidCallback onCapture;
  final VoidCallback? onRetakeLast;
  final VoidCallback? onDone;

  const _CameraReady({
    required this.controller,
    required this.capturedImages,
    required this.onCapture,
    required this.onRetakeLast,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Move your phone slowly around the room and capture '
                    'all important areas.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              if (capturedImages.isNotEmpty)
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: capturedImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(capturedImages[index].path),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RoundIconButton(
                    icon: Icons.undo,
                    label: 'Retake',
                    onPressed: onRetakeLast,
                  ),
                  GestureDetector(
                    onTap: onCapture,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: const Icon(Icons.circle,
                          color: Colors.white, size: 56),
                    ),
                  ),
                  _RoundIconButton(
                    icon: Icons.check,
                    label: 'Confirm',
                    onPressed: onDone,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  const _RoundIconButton(
      {required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon,
              color: enabled ? Colors.white : Colors.white24),
        ),
        Text(
          label,
          style: TextStyle(
              color: enabled ? Colors.white70 : Colors.white24, fontSize: 11),
        ),
      ],
    );
  }
}

/// Distinguishes permission-denied (offer Settings deep link) from other
/// camera failures (Sec. 29: "Camera permission denied", "Camera unavailable").
class _CameraErrorView extends StatelessWidget {
  final Object error;
  const _CameraErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    final message = error.toString();
    final isPermission = message.toLowerCase().contains('permission');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined,
                size: 48, color: Colors.white70),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (isPermission)
              FilledButton(
                onPressed: openAppSettings,
                child: const Text('Open Settings'),
              ),
          ],
        ),
      ),
    );
  }
}
