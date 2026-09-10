import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/outfit_card.dart';
import 'outfit_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final bool embedded;
  const FavoritesScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final favorites = appState.favoriteOutfits;

    final body = favorites.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('No favorites yet — tap the heart on any outfit to save it here.',
                  textAlign: TextAlign.center, style: AppTextStyles.body),
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100),
            itemCount: favorites.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 14,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (context, i) {
              final outfit = favorites[i];
              return OutfitCard(
                outfit: outfit,
                width: double.infinity,
                onFavoriteToggle: () => context.read<AppState>().toggleFavorite(outfit),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => OutfitDetailsScreen(outfit: outfit)),
                ),
              );
            },
          );

    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: Text('Favorites', style: AppTextStyles.h1),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text('Favorites', style: AppTextStyles.h1)),
      body: body,
    );
  }
}
