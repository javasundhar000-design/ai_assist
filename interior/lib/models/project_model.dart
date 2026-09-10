import 'package:equatable/equatable.dart';
import '../app/constants/app_constants.dart';

/// Maps to root/projects/{projectId} (Sec. 8, Sec. 24)
class ProjectModel extends Equatable {
  final String id;
  final String userId;
  final String projectName;
  final RoomType roomType;
  final String description;
  final int createdAt;
  final String? thumbnailUrl;
  final int updatedAt;

  const ProjectModel({
    required this.id,
    required this.userId,
    required this.projectName,
    required this.roomType,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailUrl,
  });

  factory ProjectModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return ProjectModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      projectName: map['projectName'] as String? ?? 'Untitled Project',
      roomType: RoomType.values.firstWhere(
        (t) => t.name == map['roomType'],
        orElse: () => RoomType.other,
      ),
      description: map['description'] as String? ?? '',
      createdAt: map['createdAt'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
      updatedAt: map['updatedAt'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
      thumbnailUrl: map['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'projectName': projectName,
      'roomType': roomType.name,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    };
  }

  ProjectModel copyWith({
    String? projectName,
    RoomType? roomType,
    String? description,
    String? thumbnailUrl,
    int? updatedAt,
  }) {
    return ProjectModel(
      id: id,
      userId: userId,
      projectName: projectName ?? this.projectName,
      roomType: roomType ?? this.roomType,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  @override
  List<Object?> get props =>
      [id, userId, projectName, roomType, description, createdAt, updatedAt, thumbnailUrl];
}
