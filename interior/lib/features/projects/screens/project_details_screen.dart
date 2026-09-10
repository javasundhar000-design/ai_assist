import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_state_views.dart';
import '../providers/projects_provider.dart';

/// Shows a single project's info and entry points into Scan Room and
/// Design History.
class ProjectDetailsScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(projectsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Project Details')),
      body: FutureBuilder(
        future: repo.getProject(projectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView();
          }
          final project = snapshot.data;
          if (project == null) {
            return const AppErrorView(message: 'Project not found.');
          }
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.projectName,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(project.roomType.label,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                if (project.description.isNotEmpty) Text(project.description),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/projects/$projectId/scan-room'),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Scan Room'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/projects/$projectId/designs'),
                  icon: const Icon(Icons.history_outlined),
                  label: const Text('Design History'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
