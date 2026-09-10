import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../projects/providers/projects_provider.dart';
import '../providers/scan_session_provider.dart';
import '../providers/scan_upload_provider.dart';

class ScanPreviewScreen extends ConsumerWidget {
  final String projectId;
  const ScanPreviewScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(scanSessionProvider);
    final uploadState = ref.watch(scanUploadControllerProvider);
    final isOnline = ref.watch(isOnlineProvider);

    ref.listen(scanUploadControllerProvider, (prev, next) {
      if (next.completedRoomId != null &&
          prev?.completedRoomId != next.completedRoomId) {
        ref.read(scanSessionProvider.notifier).clear();
        context.go(
          '/projects/$projectId/room-analysis/${next.completedRoomId}',
        );
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    Future<void> confirm() async {
      final project = await ref.read(projectsRepositoryProvider).getProject(projectId);
      if (project == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project not found.')),
        );
        return;
      }
      await ref
          .read(scanUploadControllerProvider.notifier)
          .confirmScan(project: project, images: images);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Preview')),
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline) const OfflineBanner(),
            Expanded(
              child: images.isEmpty
                  ? AppEmptyView(
                      icon: Icons.photo_camera_back_outlined,
                      message: 'No photos captured yet.',
                      action: FilledButton(
                        onPressed: () => context.pop(),
                        child: const Text('Back to Camera'),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(images[index].path),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => ref
                                    .read(scanSessionProvider.notifier)
                                    .removeAt(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (uploadState.isBusy) ...[
                    LinearProgressIndicator(value: uploadState.progress),
                    const SizedBox(height: 8),
                    Text(
                      uploadState.isUploading
                          ? 'Uploading ${(uploadState.progress * images.length).ceil().clamp(0, images.length)} '
                              'of ${images.length}…'
                          : 'Analyzing photos ${(uploadState.progress * images.length).ceil().clamp(0, images.length)} '
                              'of ${images.length}…',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              uploadState.isBusy ? null : () => context.pop(),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Add More'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: (images.isEmpty || uploadState.isBusy)
                              ? null
                              : confirm,
                          icon: uploadState.isBusy
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check),
                          label: const Text('Confirm Scan'),
                        ),
                      ),
                    ],
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
