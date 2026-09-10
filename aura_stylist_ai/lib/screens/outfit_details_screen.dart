import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'tryon_screen.dart';

class OutfitDetailsScreen extends StatefulWidget {
  final Outfit outfit;
  const OutfitDetailsScreen({super.key, required this.outfit});

  @override
  State<OutfitDetailsScreen> createState() => _OutfitDetailsScreenState();
}

class _OutfitDetailsScreenState extends State<OutfitDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final outfit = widget.outfit;
    final appState = context.watch<AppState>();
    final garments = outfit.displayGarments(appState.wardrobe);
    final reasons = outfit.displayReasons();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(outfit.name, style: AppTextStyles.h1),
        actions: [
          if (outfit.isCustom)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, outfit),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                OutfitCoverImage(
                  imagePath: outfit.coverImagePath,
                  accent: outfit.accent,
                  height: 340,
                  width: double.infinity,
                  borderRadius: AppRadii.lg,
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: GlassContainer(
                    borderRadius: AppRadii.md,
                    child: Column(
                      children: [
                        Text('${outfit.fashionScore}', style: AppTextStyles.h1.copyWith(color: AppColors.success)),
                        Text('/100', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                        Text('Fashion Score', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                if (outfit.isCustom)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: AiBadge(label: 'Your Outfit', icon: Icons.checkroom),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SectionHeader(title: 'This Outfit Includes'),
            const SizedBox(height: 12),
            garments.isEmpty
                ? Text(
                    outfit.isCustom
                        ? 'The wardrobe pieces used here have been removed.'
                        : 'No garment breakdown available.',
                    style: AppTextStyles.body,
                  )
                : Row(
                    children: garments
                        .map((g) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: AuraCard(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Column(
                                    children: [
                                      Icon(g.icon, color: AppColors.violet),
                                      const SizedBox(height: 8),
                                      Text(g.name, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
                                    ],
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
            const SizedBox(height: 24),
            SectionHeader(title: 'Why this outfit?'),
            const SizedBox(height: 12),
            AuraCard(
              child: Column(
                children: reasons
                    .map((r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text(r, style: AppTextStyles.body)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GradientButton(
                    label: 'Try On',
                    icon: Icons.center_focus_strong,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => TryOnScreen(initialOutfit: outfit)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlineActionButton(
                    label: 'Save',
                    icon: outfit.isFavorite ? Icons.favorite : Icons.favorite_border,
                    onPressed: () {
                      context.read<AppState>().toggleFavorite(outfit);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Outfit outfit) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete outfit?', style: AppTextStyles.h2),
        content: Text('Remove "${outfit.name}" from your outfits. This won\'t delete the wardrobe items it uses.', style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<AppState>().deleteCustomOutfit(outfit.id);
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
