import '../../../app/constants/app_constants.dart';
import '../../../firebase/realtime_database/realtime_database_service.dart';
import '../../../models/project_model.dart';

class ProjectsRepository {
  final RealtimeDatabaseService _db;
  ProjectsRepository(this._db);

  /// Live stream of the signed-in user's projects only — security rules
  /// (Sec. 26) enforce this server-side too, this is just the query shape.
  Stream<List<ProjectModel>> watchUserProjects(String userId) {
    return _db
        .watchWhereEquals(AppConstants.dbProjects, 'userId', userId)
        .map((event) {
      final value = event.snapshot.value;
      if (value == null) return <ProjectModel>[];
      final map = Map<dynamic, dynamic>.from(value as Map);
      final projects = map.entries
          .map((e) => ProjectModel.fromMap(
              e.key as String, e.value as Map<dynamic, dynamic>))
          .toList();
      projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return projects;
    });
  }

  Future<ProjectModel> createProject({
    required String userId,
    required String projectName,
    required RoomType roomType,
    required String description,
  }) async {
    final id = _db.pushId(AppConstants.dbProjects);
    final now = DateTime.now().millisecondsSinceEpoch;
    final project = ProjectModel(
      id: id,
      userId: userId,
      projectName: projectName,
      roomType: roomType,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
    await _db.set('${AppConstants.dbProjects}/$id', project.toMap());
    return project;
  }

  Future<ProjectModel?> getProject(String projectId) async {
    final snap = await _db.readOnce('${AppConstants.dbProjects}/$projectId');
    if (!snap.exists || snap.value == null) return null;
    return ProjectModel.fromMap(projectId, snap.value as Map<dynamic, dynamic>);
  }

  Future<void> updateProject(ProjectModel project) {
    return _db.update(
      '${AppConstants.dbProjects}/${project.id}',
      project.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch).toMap(),
    );
  }

  Future<void> deleteProject(String projectId) {
    return _db.remove('${AppConstants.dbProjects}/$projectId');
  }
}
