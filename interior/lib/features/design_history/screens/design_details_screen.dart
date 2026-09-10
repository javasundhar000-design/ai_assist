import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../models/room_and_design_models.dart';
import '../../furniture/providers/furniture_provider.dart';
import '../providers/design_provider.dart';

class DesignDetailsScreen extends ConsumerWidget {
  final String projectId;
  final String designId;
  const DesignDetailsScreen(
      {super.key, required this.projectId, required this.designId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(designRepositoryProvider);
    final furnitureRepo = ref.watch(furnitureRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Design')),
      body: FutureBuilder(
        future: Future.wait([
          repo.getDesign(designId),
          repo.getDesignFurniture(designId),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView();
          }
          final design = snapshot.data?[0] as DesignModel?;
          final instances =
              (snapshot.data?[1] as List<DesignFurnitureInstance>?) ?? [];
          if (design == null) {
            return const AppErrorView(message: 'Design not found.');
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(design.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    '${design.style.label} · Saved '
                    '${DateFormat.yMMMd().add_jm().format(DateTime.fromMillisecondsSinceEpoch(design.createdAt))}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  Text('Furniture in this design (${instances.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  if (instances.isEmpty)
                    const AppEmptyView(
                      icon: Icons.chair_alt_outlined,
                      message: 'No furniture was placed in this design.',
                    )
                  else
                    FutureBuilder<List<FurnitureModel?>>(
                      future: Future.wait(instances
                          .map((i) => furnitureRepo.getById(i.furnitureId))),
                      builder: (context, itemsSnapshot) {
                        if (!itemsSnapshot.hasData) {
                          return const AppLoadingView();
                        }
                        final items = itemsSnapshot.data!;
                        return Column(
                          children: List.generate(instances.length, (index) {
                            final item = items[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  child: const Icon(Icons.chair_alt_outlined),
                                ),
                                title: Text(item?.name ?? 'Unknown item'),
                                subtitle: item != null
                                    ? Text(item.category.label)
                                    : const Text(
                                        'This catalog item no longer exists'),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '"Continue in AR" re-adds these same items for '
                            'you to place again — their exact previous '
                            'positions can\'t be restored automatically, '
                            'since AR sessions don\'t share a persistent '
                            'coordinate space.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: instances.isEmpty
                          ? null
                          : () async {
                              final catalog =
                                  await furnitureRepo.watchAll().first;
                              final items = instances
                                  .map((i) {
                                    try {
                                      return catalog.firstWhere(
                                          (c) => c.id == i.furnitureId);
                                    } catch (_) {
                                      return null;
                                    }
                                  })
                                  .whereType<FurnitureModel>()
                                  .toList();
                              if (items.isEmpty) return;
                              ref
                                  .read(designEditHandoffProvider.notifier)
                                  .state = DesignEditHandoff(
                                designName: design.name,
                                items: items,
                              );
                              if (context.mounted) {
                                context.push(
                                  '/projects/$projectId/room-analysis/'
                                  '${design.roomId}/ar',
                                );
                              }
                            },
                      icon: const Icon(Icons.view_in_ar_outlined),
                      label: const Text('Continue in AR'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
