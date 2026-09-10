import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../models/room_and_design_models.dart';
import '../providers/room_analysis_provider.dart';
import '../services/label_mapping.dart';

class DetectedObjectsScreen extends ConsumerWidget {
  final String roomId;
  const DetectedObjectsScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objectsAsync = ref.watch(detectedObjectsStreamProvider(roomId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detected Objects')),
      body: SafeArea(
        child: objectsAsync.when(
          loading: () => const AppLoadingView(),
          error: (e, st) => const AppErrorView(
              message: 'Could not load detected objects.'),
          data: (objects) {
            if (objects.isEmpty) {
              return const AppEmptyView(
                icon: Icons.search_off,
                message: 'No objects were detected in this scan.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: objects.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Positions are estimated from where each item '
                      'appears within a scan photo (2D), not measured '
                      'in 3D room space yet. Precise 3D placement is '
                      'available once you place items in AR.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                final obj = objects[index - 1];
                return _DetectedObjectTile(object: obj);
              },
            );
          },
        ),
      ),
    );
  }
}

class _DetectedObjectTile extends StatelessWidget {
  final DetectedObjectModel object;
  const _DetectedObjectTile({required this.object});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final confidencePct = (object.confidence * 100).round();
    final isFullFrame = object.width >= 0.999 && object.height >= 0.999;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                isRoomComponent(object.objectType)
                    ? Icons.door_front_door_outlined
                    : Icons.chair_alt_outlined,
                color: scheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayNameForObjectType(object.objectType),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isFullFrame
                        ? 'Detected somewhere in a photo (no precise position)'
                        : 'Position: ${(object.positionX * 100).round()}%, '
                            '${(object.positionY * 100).round()}% of photo',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _confidenceColor(confidencePct, scheme),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$confidencePct%',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _confidenceColor(int pct, ColorScheme scheme) {
    if (pct >= 80) return scheme.primaryContainer;
    if (pct >= 60) return scheme.tertiaryContainer;
    return scheme.errorContainer;
  }
}
