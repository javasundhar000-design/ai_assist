import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/constants/app_constants.dart';
import '../../../models/project_model.dart';
import '../../authentication/providers/auth_provider.dart';
import '../repositories/projects_repository.dart';

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  return ProjectsRepository(ref.watch(realtimeDatabaseServiceProvider));
});

/// Live list of the current user's projects. Empty when signed out.
final userProjectsProvider = StreamProvider<List<ProjectModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(<ProjectModel>[]);
  return ref.watch(projectsRepositoryProvider).watchUserProjects(user.uid);
});

class CreateProjectController extends StateNotifier<AsyncValue<void>> {
  final ProjectsRepository _repo;
  CreateProjectController(this._repo) : super(const AsyncData(null));

  Future<ProjectModel?> create({
    required String userId,
    required String projectName,
    required RoomType roomType,
    required String description,
  }) async {
    state = const AsyncLoading();
    try {
      final project = await _repo.createProject(
        userId: userId,
        projectName: projectName,
        roomType: roomType,
        description: description,
      );
      state = const AsyncData(null);
      return project;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final createProjectControllerProvider =
    StateNotifierProvider<CreateProjectController, AsyncValue<void>>((ref) {
  return CreateProjectController(ref.watch(projectsRepositoryProvider));
});
