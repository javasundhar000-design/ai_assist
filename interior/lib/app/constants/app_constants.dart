/// Central place for magic strings so nothing is duplicated or hardcoded
/// across features. Keep this file small and flat.
class AppConstants {
  AppConstants._();

  static const String appName = 'Interior AR';

  // ---- Firebase Realtime Database root paths (see MASTER PROMPT Sec. 24) ----
  static const String dbUsers = 'users';
  static const String dbProjects = 'projects';
  static const String dbRooms = 'rooms';
  static const String dbRoomImages = 'roomImages';
  static const String dbDetectedObjects = 'detectedObjects';
  static const String dbFurniture = 'furniture';
  static const String dbDesigns = 'designs';
  static const String dbDesignFurniture = 'designFurniture';

  // ---- Firebase Storage folders ----
  static const String storageRoomPhotos = 'room_photos';
  static const String storageProfilePictures = 'profile_pictures';
  static const String storageDesignPreviews = 'design_previews';
  static const String storageFurnitureImages = 'furniture_images';
  static const String storageModels = 'models';

  // ---- Local (Hive) box names — temporary caching only, NOT the database ----
  static const String hiveSettingsBox = 'settings_box';
  static const String hiveOfflineDraftsBox = 'offline_drafts_box';
}

/// Room types (Sec. 8)
enum RoomType {
  livingRoom('Living Room'),
  bedroom('Bedroom'),
  kitchen('Kitchen'),
  diningRoom('Dining Room'),
  office('Office'),
  studyRoom('Study Room'),
  hall('Hall'),
  other('Other');

  final String label;
  const RoomType(this.label);
}

/// Interior design styles (Sec. 13)
enum InteriorStyle {
  modern('Modern'),
  minimalist('Minimalist'),
  luxury('Luxury'),
  scandinavian('Scandinavian'),
  industrial('Industrial'),
  traditional('Traditional'),
  contemporary('Contemporary'),
  rustic('Rustic');

  final String label;
  const InteriorStyle(this.label);
}

/// Furniture catalog categories (Sec. 15)
enum FurnitureCategory {
  sofa('Sofa'),
  chair('Chair'),
  table('Table'),
  bed('Bed'),
  wardrobe('Wardrobe'),
  cabinet('Cabinet'),
  tvUnit('TV Unit'),
  desk('Desk'),
  lamp('Lamp'),
  dining('Dining'),
  decoration('Decoration');

  final String label;
  const FurnitureCategory(this.label);
}
