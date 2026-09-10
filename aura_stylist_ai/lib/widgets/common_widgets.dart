import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shows an outfit's real cover photo (derived from a real wardrobe item
/// photo, or an actual captured try-on photo) when one exists, falling back
/// to [FashionImagePlaceholder] otherwise. Centralizing this here means
/// Home, Recommendations, Favorites, Outfit Details, and History all treat
/// "do we have a real photo?" the same way.
class OutfitCoverImage extends StatelessWidget {
  final String? imagePath;
  final Color accent;
  final double height;
  final double width;
  final double borderRadius;

  const OutfitCoverImage({
    super.key,
    required this.imagePath,
    required this.accent,
    required this.height,
    required this.width,
    this.borderRadius = AppRadii.md,
  });

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path != null && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(File(path), height: height, width: width, fit: BoxFit.cover),
      );
    }
    return FashionImagePlaceholder(accent: accent, icon: Icons.checkroom, height: height, width: width, borderRadius: borderRadius);
  }
}

/// Stand-in for real fashion photography. Swap `child` usage sites for
/// `Image.network` / `Image.asset` once real model shots are wired up —
/// every call site here is intentionally isolated to this one widget.
class FashionImagePlaceholder extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final double borderRadius;
  final double? height;
  final double? width;

  const FashionImagePlaceholder({
    super.key,
    required this.accent,
    this.icon = Icons.person_outline,
    this.borderRadius = AppRadii.md,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withOpacity(0.55), AppColors.surface],
        ),
      ),
      child: Center(
        child: Icon(icon, size: (height ?? 120) * 0.32, color: Colors.white.withOpacity(0.85)),
      ),
    );
  }
}

/// Primary call-to-action button with the app's signature violet→magenta
/// gradient. Used for Login, Get Started, Try On, etc.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label, style: AppTextStyles.button),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary (outline) button, used alongside a GradientButton (e.g. Save).
class OutlineActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const OutlineActionButton({super.key, required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.favorite_border, size: 18, color: AppColors.textPrimary),
        label: Text(label, style: AppTextStyles.bodyStrong),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
        ),
      ),
    );
  }
}

/// A frosted / glassmorphism surface used for overlays on top of imagery
/// (camera controls, floating badges, stat chips).
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
    this.borderRadius = AppRadii.md,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: child,
    );
  }
}

/// Small pill badge that communicates an active AI capability
/// (e.g. "AI Scanning", "Pose Tracking", "Fashion Score").
class AiBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  const AiBadge({super.key, required this.label, this.icon = Icons.auto_awesome});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Circular fashion-score indicator, reused on cards + details screen.
class FashionScoreBadge extends StatelessWidget {
  final int score;
  final double size;
  const FashionScoreBadge({super.key, required this.score, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.55),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.success.withOpacity(0.7), width: 1.6),
      ),
      alignment: Alignment.center,
      child: Text(
        '$score',
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        ),
      ),
    );
  }
}

/// Section header with an optional trailing "See All" action — used on
/// Home, Recommendations, Wardrobe, etc.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const SectionHeader({super.key, required this.title, this.trailing, this.onTrailingTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h2),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(trailing!, style: AppTextStyles.caption.copyWith(color: AppColors.violet, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

/// The single bottom navigation bar shared by every primary screen.
class AuraBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AuraBottomNav({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.camera_alt_outlined, Icons.camera_alt, 'Camera'),
    (Icons.checkroom_outlined, Icons.checkroom, 'Wardrobe'),
    (Icons.favorite_outline, Icons.favorite, 'Favorites'),
    (Icons.history_outlined, Icons.history, 'History'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final selected = i == currentIndex;
            final item = _items[i];
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? item.$2 : item.$1,
                      color: selected ? AppColors.violet : AppColors.textMuted,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$3,
                      style: AppTextStyles.caption.copyWith(
                        color: selected ? AppColors.violet : AppColors.textMuted,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Standard rounded surface used for cards throughout the app —
/// keeps corner radius / border / padding identical everywhere.
class AuraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AuraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}
