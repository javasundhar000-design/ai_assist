import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../models/project_model.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../projects/providers/projects_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final projectsAsync = ref.watch(userProjectsProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-project'),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline) const OfflineBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(userProjectsProvider),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, ${user?.name.isNotEmpty == true ? user!.name : 'Designer'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Let's design your space",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              tooltip: 'Furniture Library',
                              onPressed: () => context.push('/furniture'),
                              icon: const Icon(Icons.chair_alt_outlined),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Text('My Projects',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ),
                    projectsAsync.when(
                      loading: () => const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: AppLoadingView(),
                        ),
                      ),
                      error: (e, st) => SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: AppErrorView(
                            message: 'Could not load your projects.',
                            onRetry: () => ref.invalidate(userProjectsProvider),
                          ),
                        ),
                      ),
                      data: (projects) {
                        if (projects.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: AppEmptyView(
                                icon: Icons.chair_alt_outlined,
                                message:
                                    'No projects yet.\nCreate your first room project to get started.',
                                action: FilledButton(
                                  onPressed: () =>
                                      context.push('/create-project'),
                                  child: const Text('Create New Project'),
                                ),
                              ),
                            ),
                          );
                        }
                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.82,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _ProjectCard(project: projects[index]),
                              childCount: projects.length,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/projects/${project.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: scheme.surfaceVariant,
                child: project.thumbnailUrl != null
                    ? Image.network(project.thumbnailUrl!, fit: BoxFit.cover)
                    : Icon(Icons.image_outlined,
                        size: 40, color: scheme.outline),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.projectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(project.roomType.label,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMd()
                        .format(DateTime.fromMillisecondsSinceEpoch(
                            project.updatedAt)),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.outline, fontSize: 11),
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
