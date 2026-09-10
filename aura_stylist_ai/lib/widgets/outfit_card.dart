import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

/// Vertical outfit card: image + name + occasion score + favorite toggle.
/// Used in grids (Recommendations, Favorites) and horizontal rails (Home).
class OutfitCard extends StatelessWidget {
  final Outfit outfit;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final double width;
  final double imageHeight;

  const OutfitCard({
    super.key,
    required this.outfit,
    this.onTap,
    this.onFavoriteToggle,
    this.width = 160,
    this.imageHeight = 190,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  OutfitCoverImage(
                    imagePath: outfit.coverImagePath,
                    accent: outfit.accent,
                    height: imageHeight,
                    width: width,
                    borderRadius: AppRadii.lg,
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, size: 12, color: AppColors.success),
                          const SizedBox(width: 3),
                          Text('${outfit.fashionScore}/100',
                              style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavoriteToggle,
                      child: GlassContainer(
                        padding: const EdgeInsets.all(6),
                        borderRadius: AppRadii.pill,
                        child: Icon(
                          outfit.isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: outfit.isFavorite ? AppColors.magenta : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(outfit.name, style: AppTextStyles.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(outfit.occasion, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}
