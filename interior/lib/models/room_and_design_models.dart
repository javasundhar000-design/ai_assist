import 'package:equatable/equatable.dart';
import '../app/constants/app_constants.dart';

/// root/rooms/{roomId} (Sec. 11, 24)
class RoomModel extends Equatable {
  final String id;
  final String projectId;
  final RoomType roomType;
  final double length; // meters
  final double width;
  final double height;
  final double floorArea;
  final bool isEstimated; // true unless from reliable spatial sensors

  const RoomModel({
    required this.id,
    required this.projectId,
    required this.roomType,
    required this.length,
    required this.width,
    required this.height,
    required this.floorArea,
    this.isEstimated = true,
  });

  factory RoomModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return RoomModel(
      id: id,
      projectId: map['projectId'] as String? ?? '',
      roomType: RoomType.values.firstWhere(
        (t) => t.name == map['roomType'],
        orElse: () => RoomType.other,
      ),
      length: (map['length'] as num? ?? 0).toDouble(),
      width: (map['width'] as num? ?? 0).toDouble(),
      height: (map['height'] as num? ?? 0).toDouble(),
      floorArea: (map['floorArea'] as num? ?? 0).toDouble(),
      isEstimated: map['isEstimated'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'projectId': projectId,
        'roomType': roomType.name,
        'length': length,
        'width': width,
        'height': height,
        'floorArea': floorArea,
        'isEstimated': isEstimated,
      };

  @override
  List<Object?> get props =>
      [id, projectId, roomType, length, width, height, floorArea, isEstimated];
}

/// root/detectedObjects/{roomId}/{objectId} (Sec. 10, 24)
class DetectedObjectModel extends Equatable {
  final String id;
  final String objectType; // e.g. sofa, wall, door, window, table...
  final double confidence; // 0.0 - 1.0
  final double positionX;
  final double positionY;
  final double positionZ;
  final double width;
  final double height;
  final double depth;
  final double rotation;

  const DetectedObjectModel({
    required this.id,
    required this.objectType,
    required this.confidence,
    this.positionX = 0,
    this.positionY = 0,
    this.positionZ = 0,
    this.width = 0,
    this.height = 0,
    this.depth = 0,
    this.rotation = 0,
  });

  factory DetectedObjectModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return DetectedObjectModel(
      id: id,
      objectType: map['objectType'] as String? ?? 'unknown',
      confidence: (map['confidence'] as num? ?? 0).toDouble(),
      positionX: (map['positionX'] as num? ?? 0).toDouble(),
      positionY: (map['positionY'] as num? ?? 0).toDouble(),
      positionZ: (map['positionZ'] as num? ?? 0).toDouble(),
      width: (map['width'] as num? ?? 0).toDouble(),
      height: (map['height'] as num? ?? 0).toDouble(),
      depth: (map['depth'] as num? ?? 0).toDouble(),
      rotation: (map['rotation'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'objectType': objectType,
        'confidence': confidence,
        'positionX': positionX,
        'positionY': positionY,
        'positionZ': positionZ,
        'width': width,
        'height': height,
        'depth': depth,
        'rotation': rotation,
      };

  @override
  List<Object?> get props => [
        id,
        objectType,
        confidence,
        positionX,
        positionY,
        positionZ,
        width,
        height,
        depth,
        rotation,
      ];
}

/// root/furniture/{furnitureId} — catalog item (Sec. 15, 24)
class FurnitureModel extends Equatable {
  final String id;
  final String name;
  final FurnitureCategory category;
  final String description;
  final InteriorStyle style;
  final String material;
  final String color;
  final double width;
  final double height;
  final double depth;
  final double price;
  final String imageUrl;
  final String modelUrl; // .glb / .gltf in Firebase Storage

  const FurnitureModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.style,
    required this.material,
    required this.color,
    required this.width,
    required this.height,
    required this.depth,
    required this.price,
    required this.imageUrl,
    required this.modelUrl,
  });

  factory FurnitureModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return FurnitureModel(
      id: id,
      name: map['name'] as String? ?? '',
      category: FurnitureCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => FurnitureCategory.decoration,
      ),
      description: map['description'] as String? ?? '',
      style: InteriorStyle.values.firstWhere(
        (s) => s.name == map['style'],
        orElse: () => InteriorStyle.contemporary,
      ),
      material: map['material'] as String? ?? '',
      color: map['color'] as String? ?? '',
      width: (map['width'] as num? ?? 0).toDouble(),
      height: (map['height'] as num? ?? 0).toDouble(),
      depth: (map['depth'] as num? ?? 0).toDouble(),
      price: (map['price'] as num? ?? 0).toDouble(),
      imageUrl: map['imageUrl'] as String? ?? '',
      modelUrl: map['modelUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category.name,
        'description': description,
        'style': style.name,
        'material': material,
        'color': color,
        'width': width,
        'height': height,
        'depth': depth,
        'price': price,
        'imageUrl': imageUrl,
        'modelUrl': modelUrl,
      };

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        description,
        style,
        material,
        color,
        width,
        height,
        depth,
        price,
        imageUrl,
        modelUrl,
      ];
}

/// root/designs/{designId} (Sec. 21, 24)
class DesignModel extends Equatable {
  final String id;
  final String userId;
  final String projectId;
  final String roomId;
  final String name;
  final InteriorStyle style;
  final int createdAt;
  final int updatedAt;
  final String? previewImageUrl;
  // Soft-delete timestamp (Phase 14: Delete + Restore share this one
  // field rather than needing a separate trash collection). Null means
  // active/not deleted.
  final int? deletedAt;

  const DesignModel({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.roomId,
    required this.name,
    required this.style,
    required this.createdAt,
    required this.updatedAt,
    this.previewImageUrl,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  factory DesignModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return DesignModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      projectId: map['projectId'] as String? ?? '',
      roomId: map['roomId'] as String? ?? '',
      name: map['name'] as String? ?? 'Untitled Design',
      style: InteriorStyle.values.firstWhere(
        (s) => s.name == map['style'],
        orElse: () => InteriorStyle.contemporary,
      ),
      createdAt: map['createdAt'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
      updatedAt: map['updatedAt'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
      previewImageUrl: map['previewImageUrl'] as String?,
      deletedAt: map['deletedAt'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'projectId': projectId,
        'roomId': roomId,
        'name': name,
        'style': style.name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        if (previewImageUrl != null) 'previewImageUrl': previewImageUrl,
        if (deletedAt != null) 'deletedAt': deletedAt,
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        projectId,
        roomId,
        name,
        style,
        createdAt,
        updatedAt,
        previewImageUrl,
        deletedAt,
      ];
}

/// root/designFurniture/{designId}/{instanceId} — one placed instance
/// of a catalog furniture item within a specific design (Sec. 21, 24)
class DesignFurnitureInstance extends Equatable {
  final String instanceId;
  final String furnitureId;
  final double positionX;
  final double positionY;
  final double positionZ;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double scaleX;
  final double scaleY;
  final double scaleZ;

  const DesignFurnitureInstance({
    required this.instanceId,
    required this.furnitureId,
    this.positionX = 0,
    this.positionY = 0,
    this.positionZ = 0,
    this.rotationX = 0,
    this.rotationY = 0,
    this.rotationZ = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.scaleZ = 1,
  });

  factory DesignFurnitureInstance.fromMap(
      String instanceId, Map<dynamic, dynamic> map) {
    return DesignFurnitureInstance(
      instanceId: instanceId,
      furnitureId: map['furnitureId'] as String? ?? '',
      positionX: (map['positionX'] as num? ?? 0).toDouble(),
      positionY: (map['positionY'] as num? ?? 0).toDouble(),
      positionZ: (map['positionZ'] as num? ?? 0).toDouble(),
      rotationX: (map['rotationX'] as num? ?? 0).toDouble(),
      rotationY: (map['rotationY'] as num? ?? 0).toDouble(),
      rotationZ: (map['rotationZ'] as num? ?? 0).toDouble(),
      scaleX: (map['scaleX'] as num? ?? 1).toDouble(),
      scaleY: (map['scaleY'] as num? ?? 1).toDouble(),
      scaleZ: (map['scaleZ'] as num? ?? 1).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'furnitureId': furnitureId,
        'positionX': positionX,
        'positionY': positionY,
        'positionZ': positionZ,
        'rotationX': rotationX,
        'rotationY': rotationY,
        'rotationZ': rotationZ,
        'scaleX': scaleX,
        'scaleY': scaleY,
        'scaleZ': scaleZ,
      };

  DesignFurnitureInstance copyWith({
    double? positionX,
    double? positionY,
    double? positionZ,
    double? rotationX,
    double? rotationY,
    double? rotationZ,
    double? scaleX,
    double? scaleY,
    double? scaleZ,
  }) {
    return DesignFurnitureInstance(
      instanceId: instanceId,
      furnitureId: furnitureId,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      positionZ: positionZ ?? this.positionZ,
      rotationX: rotationX ?? this.rotationX,
      rotationY: rotationY ?? this.rotationY,
      rotationZ: rotationZ ?? this.rotationZ,
      scaleX: scaleX ?? this.scaleX,
      scaleY: scaleY ?? this.scaleY,
      scaleZ: scaleZ ?? this.scaleZ,
    );
  }

  @override
  List<Object?> get props => [
        instanceId,
        furnitureId,
        positionX,
        positionY,
        positionZ,
        rotationX,
        rotationY,
        rotationZ,
        scaleX,
        scaleY,
        scaleZ,
      ];
}
