import 'package:flutter/material.dart';

/// A single AI-recommended outfit. In production, `imageUrl` would come
/// from the styling/recommendation API and `garments` from the vision
/// pipeline that segmented the try-on render.
class Outfit {
  final String id;
  final String name;
  final String occasion;
  final int fashionScore;
  final String imageAsset;
  final Color accent;
  bool isFavorite;
  final List<GarmentItem> garments;
  final List<String> reasons;
  final bool isCustom;
  final List<String> wardrobeItemIds; // populated only for user-built outfits
  final String? coverImagePath; // a real photo on disk, when one is available

  Outfit({
    required this.id,
    required this.name,
    required this.occasion,
    required this.fashionScore,
    required this.imageAsset,
    required this.accent,
    this.isFavorite = false,
    this.garments = const [],
    this.reasons = const [],
    this.isCustom = false,
    this.wardrobeItemIds = const [],
    this.coverImagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'occasion': occasion,
        'fashionScore': fashionScore,
        'accent': accent.value,
        'isCustom': isCustom,
        'wardrobeItemIds': wardrobeItemIds,
        'coverImagePath': coverImagePath,
      };

  factory Outfit.fromJson(Map<String, dynamic> json) => Outfit(
        id: json['id'] as String,
        name: json['name'] as String,
        occasion: json['occasion'] as String,
        fashionScore: json['fashionScore'] as int,
        imageAsset: '',
        accent: Color(json['accent'] as int),
        isCustom: json['isCustom'] as bool? ?? true,
        wardrobeItemIds: (json['wardrobeItemIds'] as List).cast<String>(),
        coverImagePath: json['coverImagePath'] as String?,
      );
}

extension OutfitSearch on Outfit {
  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) || occasion.toLowerCase().contains(q);
  }
}

/// Resolves what to actually show for "This Outfit Includes" / "Why this
/// outfit?" — real wardrobe pieces + a generated rationale for outfits the
/// user built themselves, or the curated copy for seed catalog outfits.
extension OutfitDisplay on Outfit {
  List<GarmentItem> displayGarments(List<WardrobeItem> wardrobe) {
    if (!isCustom) return garments;
    return wardrobeItemIds
        .map((id) {
          final match = wardrobe.where((w) => w.id == id);
          return match.isEmpty ? null : GarmentItem(match.first.name, match.first.icon);
        })
        .whereType<GarmentItem>()
        .toList();
  }

  List<String> displayReasons() {
    if (!isCustom) return reasons;
    return [
      'Built by you from your own wardrobe',
      'Combines ${wardrobeItemIds.length} piece${wardrobeItemIds.length == 1 ? '' : 's'} you already own',
      'Tagged for $occasion occasions',
    ];
  }
}

class GarmentItem {
  final String name;
  final IconData icon;
  const GarmentItem(this.name, this.icon);
}

class WardrobeItem {
  final String id;
  final String name;
  final String category; // Tops, Bottoms, Shoes, Accessories
  final IconData icon;
  final Color color;
  bool isFavorite;
  final String? imagePath; // path on disk when added via camera/gallery

  WardrobeItem({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.color,
    this.isFavorite = false,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'icon': icon.codePoint,
        'color': color.value,
        'isFavorite': isFavorite,
        'imagePath': imagePath,
      };

  factory WardrobeItem.fromJson(Map<String, dynamic> json) => WardrobeItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
        color: Color(json['color'] as int),
        isFavorite: json['isFavorite'] as bool? ?? false,
        imagePath: json['imagePath'] as String?,
      );
}

class HistoryEntry {
  final String outfitId;
  final DateTime timestamp;
  final String? capturedImagePath; // the actual photo taken when this look was captured
  const HistoryEntry({required this.outfitId, required this.timestamp, this.capturedImagePath});

  // Outfit lookup goes through AppState.outfitById (covers custom outfits
  // as well as the seed catalog) rather than a hardcoded MockData lookup.

  String get group {
    final now = DateTime.now();
    final d = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    final mm = timestamp.month.toString().padLeft(2, '0');
    return '${timestamp.day} / $mm / ${timestamp.year}';
  }

  String get time {
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Map<String, dynamic> toJson() => {
        'outfitId': outfitId,
        'timestamp': timestamp.toIso8601String(),
        'capturedImagePath': capturedImagePath,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        outfitId: json['outfitId'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        capturedImagePath: json['capturedImagePath'] as String?,
      );
}

/// Central mock data so every screen shows consistent, matching content.
class MockData {
  MockData._();

  static final List<Outfit> outfits = [
    Outfit(
      id: 'formal_elegance',
      name: 'Formal Elegance',
      occasion: 'Office',
      fashionScore: 94,
      imageAsset: 'formal',
      accent: const Color(0xFF6D5EF5),
      isFavorite: true,
      garments: const [
        GarmentItem('Navy Shirt', Icons.checkroom),
        GarmentItem('Beige Pant', Icons.dry_cleaning),
        GarmentItem('Brown Belt', Icons.linear_scale),
        GarmentItem('Brown Shoes', Icons.hiking),
      ],
      reasons: const [
        'Perfect for your skin tone',
        'Great for your body proportions',
        'Ideal for Office occasion',
        'Matches your style preference',
      ],
    ),
    Outfit(
      id: 'smart_casual',
      name: 'Smart Casual',
      occasion: 'Casual',
      fashionScore: 89,
      imageAsset: 'casual',
      accent: const Color(0xFF38BDF8),
    ),
    Outfit(
      id: 'party_glam',
      name: 'Party Glam',
      occasion: 'Party',
      fashionScore: 91,
      imageAsset: 'party',
      accent: const Color(0xFFEC4899),
      isFavorite: true,
    ),
    Outfit(
      id: 'wedding_look',
      name: 'Wedding Look',
      occasion: 'Wedding',
      fashionScore: 93,
      imageAsset: 'wedding',
      accent: const Color(0xFFF59E0B),
      isFavorite: true,
    ),
    Outfit(
      id: 'casual_day_out',
      name: 'Casual Day Out',
      occasion: 'Casual',
      fashionScore: 86,
      imageAsset: 'casual2',
      accent: const Color(0xFF34D399),
      isFavorite: true,
    ),
  ];

  static Outfit byId(String id) => outfits.firstWhere((o) => o.id == id);

  static List<WardrobeItem> seedWardrobe() => [
        WardrobeItem(id: 'w1', name: 'White Shirt', category: 'Tops', icon: Icons.checkroom, color: const Color(0xFFE5E7EB)),
        WardrobeItem(id: 'w2', name: 'Denim Jeans', category: 'Bottoms', icon: Icons.dry_cleaning, color: const Color(0xFF3B82F6)),
        WardrobeItem(id: 'w3', name: 'Olive Jacket', category: 'Tops', icon: Icons.checkroom, color: const Color(0xFF6B7A4F)),
        WardrobeItem(id: 'w4', name: 'White Sneakers', category: 'Shoes', icon: Icons.hiking, color: const Color(0xFFF3F4F6)),
        WardrobeItem(id: 'w5', name: 'Classic Watch', category: 'Accessories', icon: Icons.watch, color: const Color(0xFFD4AF37)),
        WardrobeItem(id: 'w6', name: 'Sunglasses', category: 'Accessories', icon: Icons.remove_red_eye, color: const Color(0xFF111827)),
        WardrobeItem(id: 'w7', name: 'Leather Shoes', category: 'Shoes', icon: Icons.hiking, color: const Color(0xFF7C4A2D)),
        WardrobeItem(id: 'w8', name: 'Leather Bag', category: 'Accessories', icon: Icons.work_outline, color: const Color(0xFF5B3A29)),
        WardrobeItem(id: 'w9', name: 'Formal Shoes', category: 'Shoes', icon: Icons.hiking, color: const Color(0xFF2B2B2B)),
      ];

  static List<HistoryEntry> seedHistory() {
    final now = DateTime.now();
    return [
      HistoryEntry(outfitId: 'formal_elegance', timestamp: DateTime(now.year, now.month, now.day, 10, 30)),
      HistoryEntry(outfitId: 'smart_casual', timestamp: now.subtract(const Duration(days: 1)).copyWith(hour: 18, minute: 45)),
      HistoryEntry(outfitId: 'party_glam', timestamp: now.subtract(const Duration(days: 2)).copyWith(hour: 20, minute: 15)),
      HistoryEntry(outfitId: 'casual_day_out', timestamp: now.subtract(const Duration(days: 3)).copyWith(hour: 17, minute: 20)),
    ];
  }

  static final List<Color> bestColors = [
    const Color(0xFF1E3A5F), // Navy
    const Color(0xFF6B7A4F), // Olive
    const Color(0xFF7B2D3B), // Maroon
    const Color(0xFFD8C3A5), // Beige
    const Color(0xFF111111), // Black
  ];

  static const categories = [
    {'label': 'Formal', 'icon': Icons.business_center_outlined},
    {'label': 'Casual', 'icon': Icons.weekend_outlined},
    {'label': 'Party', 'icon': Icons.celebration_outlined},
    {'label': 'Wedding', 'icon': Icons.favorite_outline},
    {'label': 'Sports', 'icon': Icons.sports_basketball_outlined},
  ];
}
