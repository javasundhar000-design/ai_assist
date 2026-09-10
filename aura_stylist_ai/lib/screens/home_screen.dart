import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/outfit_card.dart';
import 'tryon_screen.dart';
import 'wardrobe_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'recommendations_screen.dart';
import 'outfit_details_screen.dart';
import 'ai_analysis_screen.dart';
import 'login_screen.dart';

/// Shell that owns the bottom navigation and swaps between the 5 primary
/// tabs without losing the nav bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  late final List<Widget> _tabs = [
    _DashboardTab(onNavigateTab: _setTab),
    const TryOnScreen(embedded: true),
    const WardrobeScreen(embedded: true),
    const FavoritesScreen(embedded: true),
    const HistoryScreen(embedded: true),
  ];

  void _setTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: _tabs)),
      bottomNavigationBar: AuraBottomNav(currentIndex: _index, onTap: _setTab),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;
  const _DashboardTab({required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final greetingName = (appState.email ?? 'there').split('@').first;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (context) => InkWell(
                  onTap: () => _showMenu(context),
                  child: const Icon(Icons.menu, color: AppColors.textPrimary),
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.magenta, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Hello, ${_capitalize(greetingName)} 👋', style: AppTextStyles.display.copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          Text("Let's dress you up today!", style: AppTextStyles.body),
          const SizedBox(height: 20),

          AuraCard(
            padding: const EdgeInsets.all(0),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiAnalysisScreen()),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.purple, AppColors.magenta],
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AiBadge(label: 'AI RECOMMENDATION', icon: Icons.auto_awesome),
                        const SizedBox(height: 10),
                        Text('Find the best outfit\nfor you',
                            style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 18)),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text('Get Started',
                              style: AppTextStyles.bodyStrong.copyWith(color: AppColors.purple)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FashionImagePlaceholder(
                    accent: Colors.white,
                    icon: Icons.person_2_outlined,
                    height: 110,
                    width: 90,
                    borderRadius: AppRadii.md,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          SectionHeader(
            title: 'Categories',
            trailing: 'See All',
            onTrailingTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecommendationsScreen()),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: MockData.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final cat = MockData.categories[i];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => RecommendationsScreen(initialOccasion: cat['label'] as String)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(cat['icon'] as IconData, color: AppColors.violet),
                      ),
                      const SizedBox(height: 6),
                      Text(cat['label'] as String, style: AppTextStyles.caption),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),

          SectionHeader(
            title: 'Top Picks For You',
            trailing: 'See All',
            onTrailingTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecommendationsScreen()),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: appState.allOutfits.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final outfit = appState.allOutfits[i];
                return OutfitCard(
                  outfit: outfit,
                  onFavoriteToggle: () => context.read<AppState>().toggleFavorite(outfit),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => OutfitDetailsScreen(outfit: outfit)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.textPrimary),
              title: Text('Log out', style: AppTextStyles.bodyStrong),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await context.read<AppState>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
