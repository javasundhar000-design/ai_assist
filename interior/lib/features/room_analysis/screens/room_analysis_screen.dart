import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../models/room_and_design_models.dart';
import '../providers/room_analysis_provider.dart';
import '../services/label_mapping.dart';

class RoomAnalysisScreen extends ConsumerWidget {
  final String projectId;
  final String roomId;
  const RoomAnalysisScreen(
      {super.key, required this.projectId, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomStreamProvider(roomId));
    final objectsAsync = ref.watch(detectedObjectsStreamProvider(roomId));

    return Scaffold(
      appBar: AppBar(title: const Text('Room Analysis')),
      body: SafeArea(
        child: roomAsync.when(
          loading: () => const AppLoadingView(),
          error: (e, st) => AppErrorView(
            message: 'Could not load room analysis.',
            onRetry: () => ref.invalidate(roomStreamProvider(roomId)),
          ),
          data: (room) {
            if (room == null) {
              return const AppErrorView(message: 'Room not found.');
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.roomType.label,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  _DimensionsCard(room: room),
                  const SizedBox(height: 20),
                  Text('Detected Objects',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Automatically detected from your scan photos '
                    '(on-device, no data leaves this app).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  objectsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: AppLoadingView(),
                    ),
                    error: (e, st) => const AppErrorView(
                        message: 'Could not load detected objects.'),
                    data: (objects) {
                      if (objects.isEmpty) {
                        return const AppEmptyView(
                          icon: Icons.search_off,
                          message:
                              'No objects were confidently detected in this scan.\n'
                              'You can still continue and add furniture manually.',
                        );
                      }
                      return _DetectedObjectsChecklist(objects: objects);
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                        '/projects/$projectId/room-analysis/$roomId/objects'),
                    icon: const Icon(Icons.list_alt_outlined),
                    label: const Text('View Detection Details'),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () => context.push(
                        '/projects/$projectId/room-analysis/$roomId/style'),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DimensionsCard extends StatelessWidget {
  final RoomModel room;
  const _DimensionsCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Estimated Dimensions',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: 8),
                if (room.isEstimated)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Estimated',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DimStat(label: 'Length', value: '${room.length} m'),
                _DimStat(label: 'Width', value: '${room.width} m'),
                _DimStat(label: 'Height', value: '${room.height} m'),
              ],
            ),
            const Divider(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Floor Area',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text('${room.floorArea} m²',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            if (room.isEstimated) ...[
              const SizedBox(height: 8),
              Text(
                'Based on typical sizes for this room type. For a precise '
                'measurement, use AR scanning (available in AR Visualization).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DimStat extends StatelessWidget {
  final String label;
  final String value;
  const _DimStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _DetectedObjectsChecklist extends StatelessWidget {
  final List<DetectedObjectModel> objects;
  const _DetectedObjectsChecklist({required this.objects});

  @override
  Widget build(BuildContext context) {
    final furniture =
        objects.where((o) => !isRoomComponent(o.objectType)).toList();
    final roomComponents =
        objects.where((o) => isRoomComponent(o.objectType)).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...furniture.map((o) => _ObjectChip(object: o)),
        ...roomComponents.map((o) => _ObjectChip(object: o)),
      ],
    );
  }
}

class _ObjectChip extends StatelessWidget {
  final DetectedObjectModel object;
  const _ObjectChip({required this.object});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(Icons.check_circle,
          size: 18, color: scheme.primary),
      label: Text(displayNameForObjectType(object.objectType)),
      backgroundColor: scheme.surfaceVariant,
      side: BorderSide.none,
    );
  }
}
