import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../models/room_and_design_models.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../furniture/providers/furniture_provider.dart';
import '../providers/design_provider.dart';

class DesignHistoryScreen extends ConsumerWidget {
  final String projectId;
  const DesignHistoryScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final designsAsync = ref.watch(projectDesignsProvider(projectId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Design History'),
          actions: [
            IconButton(
              tooltip: 'Compare Designs',
              icon: const Icon(Icons.compare_arrows_outlined),
              onPressed: () =>
                  context.push('/projects/$projectId/designs-compare-select'),
            ),
          ],
          bottom: const TabBar(tabs: [
            Tab(text: 'Active'),
            Tab(text: 'Deleted'),
          ]),
        ),
        body: designsAsync.when(
          loading: () => const AppLoadingView(),
          error: (e, st) => AppErrorView(
            message: 'Could not load design history.',
            onRetry: () => ref.invalidate(projectDesignsProvider(projectId)),
          ),
          data: (designs) {
            // Version numbers (Sec. 22: "Version 1 / Version 2 / ...")
            // computed by chronological order among ALL designs for this
            // project (active + deleted), oldest first.
            final chronological = [...designs]
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            final versionOf = <String, int>{
              for (var i = 0; i < chronological.length; i++)
                chronological[i].id: i + 1,
            };
            DesignModel? latest;
            for (final d in designs.where((d) => !d.isDeleted)) {
              if (latest == null || d.updatedAt > latest.updatedAt) latest = d;
            }
            final latestActiveId = latest?.id;

            final active = designs.where((d) => !d.isDeleted).toList();
            final deleted = designs.where((d) => d.isDeleted).toList();

            return TabBarView(
              children: [
                _DesignList(
                  projectId: projectId,
                  designs: active,
                  versionOf: versionOf,
                  latestId: latestActiveId,
                  isTrash: false,
                  emptyMessage:
                      'No saved designs yet.\nArrange furniture in AR and '
                      'tap Save to create your first version.',
                ),
                _DesignList(
                  projectId: projectId,
                  designs: deleted,
                  versionOf: versionOf,
                  latestId: null,
                  isTrash: true,
                  emptyMessage: 'No deleted designs.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DesignList extends ConsumerWidget {
  final String projectId;
  final List<DesignModel> designs;
  final Map<String, int> versionOf;
  final String? latestId;
  final bool isTrash;
  final String emptyMessage;

  const _DesignList({
    required this.projectId,
    required this.designs,
    required this.versionOf,
    required this.latestId,
    required this.isTrash,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (designs.isEmpty) {
      return AppEmptyView(
        icon: isTrash ? Icons.delete_outline : Icons.style_outlined,
        message: emptyMessage,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: designs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final design = designs[index];
        return _DesignCard(
          projectId: projectId,
          design: design,
          version: versionOf[design.id] ?? index + 1,
          isLatest: design.id == latestId,
          isTrash: isTrash,
        );
      },
    );
  }
}

class _DesignCard extends ConsumerWidget {
  final String projectId;
  final DesignModel design;
  final int version;
  final bool isLatest;
  final bool isTrash;

  const _DesignCard({
    required this.projectId,
    required this.design,
    required this.version,
    required this.isLatest,
    required this.isTrash,
  });

  Future<void> _duplicate(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(designRepositoryProvider).duplicateDesign(
            designId: design.id,
            userId: user.uid,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Design duplicated.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not duplicate design.')),
        );
      }
    }
  }

  Future<void> _softDelete(BuildContext context, WidgetRef ref) async {
    await ref.read(designRepositoryProvider).softDeleteDesign(design.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Design moved to Deleted.')),
      );
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    await ref.read(designRepositoryProvider).restoreDesign(design.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Design restored.')));
    }
  }

  Future<void> _permanentlyDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text(
            'This will permanently delete "${design.name}". This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(designRepositoryProvider).permanentlyDeleteDesign(design.id);
    }
  }

  Future<void> _editInAr(BuildContext context, WidgetRef ref) async {
    final furniture = await ref
        .read(designRepositoryProvider)
        .getDesignFurniture(design.id);
    final catalog = await ref.read(furnitureRepositoryProvider).watchAll().first;
    final items = furniture
        .map((f) {
          try {
            return catalog.firstWhere((c) => c.id == f.furnitureId);
          } catch (_) {
            return null;
          }
        })
        .whereType<FurnitureModel>()
        .toList();

    if (items.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('This design has no furniture items to edit.')),
        );
      }
      return;
    }

    ref.read(designEditHandoffProvider.notifier).state =
        DesignEditHandoff(designName: design.name, items: items);
    if (context.mounted) {
      context.push('/projects/$projectId/room-analysis/${design.roomId}/ar');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(design.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                if (isLatest)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Latest',
                        style: TextStyle(
                            fontSize: 11, color: scheme.onPrimaryContainer)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Version $version · ${design.style.label} · '
              '${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(design.updatedAt))}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: isTrash
                  ? [
                      TextButton.icon(
                        onPressed: () => _restore(context, ref),
                        icon: const Icon(Icons.restore, size: 18),
                        label: const Text('Restore'),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _permanentlyDelete(context, ref),
                        icon: Icon(Icons.delete_forever,
                            size: 18, color: scheme.error),
                        label: Text('Delete Permanently',
                            style: TextStyle(color: scheme.error)),
                      ),
                    ]
                  : [
                      TextButton.icon(
                        onPressed: () => context
                            .push('/projects/$projectId/designs/${design.id}'),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('Open'),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editInAr(context, ref);
                              break;
                            case 'duplicate':
                              _duplicate(context, ref);
                              break;
                            case 'delete':
                              _softDelete(context, ref);
                              break;
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit (continue in AR)')),
                          PopupMenuItem(
                              value: 'duplicate', child: Text('Duplicate')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}
