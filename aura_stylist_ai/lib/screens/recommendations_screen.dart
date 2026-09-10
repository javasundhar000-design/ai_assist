import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/outfit_card.dart';
import '../services/gemini_image_service.dart';
import 'outfit_details_screen.dart';
import 'create_outfit_screen.dart';

/// One Gemini-generated image held in memory until the user decides to
/// save it into their wardrobe (at which point it's written to disk).
class _GeneratedImage {
  final String title;
  final Uint8List bytes;
  const _GeneratedImage({required this.title, required this.bytes});
}

class RecommendationsScreen extends StatefulWidget {
  final String? initialOccasion;
  const RecommendationsScreen({super.key, this.initialOccasion});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  int _tab = 0; // 0 = Outfits, 1 = Individual Items
  String _query = '';
  String _occasionFilter = 'All';
  final _searchController = TextEditingController();

  static const _occasions = ['All', 'Office', 'Casual', 'Party', 'Wedding'];

  final _geminiImageService = GeminiImageService();
  final _discoverQueryController = TextEditingController(text: 'a stylish casual outfit');
  List<_GeneratedImage> _discoverResults = [];
  bool _discoverLoading = false;
  String? _discoverError;

  @override
  void initState() {
    super.initState();
    if (widget.initialOccasion != null) {
      // Home's category chips use display labels ("Formal") that map to
      // the outfit model's occasion field ("Office") for real filtering.
      const labelToOccasion = {'Formal': 'Office', 'Casual': 'Casual', 'Party': 'Party', 'Wedding': 'Wedding', 'Sports': 'Sports'};
      final mapped = labelToOccasion[widget.initialOccasion];
      if (mapped != null && _occasions.contains(mapped)) _occasionFilter = mapped;
    }
    if (GeminiImageService.hasApiKey) _generateImages();
  }

  /// Fires off a few parallel Gemini calls for the same prompt so the rail
  /// shows several distinct options — each call independently sampled, so
  /// the results genuinely differ even for an identical prompt. Failures on
  /// individual calls don't block the others; only if every call fails does
  /// the section show an error.
  Future<void> _generateImages() async {
    if (!GeminiImageService.hasApiKey) {
      setState(() => _discoverError =
          'Add a Gemini API key to generate outfit images — see the README for the --dart-define flag.');
      return;
    }
    setState(() {
      _discoverLoading = true;
      _discoverError = null;
    });

    final prompt = _discoverQueryController.text.trim().isEmpty ? 'a stylish casual outfit' : _discoverQueryController.text.trim();
    final fullPrompt = '$prompt, full outfit, fashion product photography, plain neutral studio background, high quality, well-lit';
    final results = <_GeneratedImage>[];
    String? lastError;

    await Future.wait(List.generate(3, (_) async {
      try {
        final bytes = await _geminiImageService.generateImage(prompt: fullPrompt);
        results.add(_GeneratedImage(title: prompt, bytes: bytes));
      } catch (e) {
        lastError = e.toString();
      }
    }));

    if (!mounted) return;
    setState(() {
      _discoverResults = results;
      _discoverLoading = false;
      if (results.isEmpty) _discoverError = lastError ?? 'Could not generate images for that prompt.';
    });
  }

  Future<void> _addDiscoverItemToWardrobe(_GeneratedImage item) async {
    final category = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('Add to wardrobe as...', style: AppTextStyles.h2),
            ),
            ...['Tops', 'Bottoms', 'Shoes', 'Accessories'].map(
              (c) => ListTile(
                title: Text(c, style: AppTextStyles.bodyStrong),
                onTap: () => Navigator.of(sheetContext).pop(c),
              ),
            ),
          ],
        ),
      ),
    );
    if (category == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final importsDir = Directory('${docsDir.path}/wardrobe_imports');
      if (!await importsDir.exists()) await importsDir.create(recursive: true);
      final fileName = 'generated_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedFile = await File('${importsDir.path}/$fileName').writeAsBytes(item.bytes);

      if (!mounted) return;
      await context.read<AppState>().addWardrobeItem(
            name: item.title,
            category: category,
            icon: _iconForCategory(category),
            color: AppColors.violet,
            imagePath: savedFile.path,
          );
      messenger.showSnackBar(SnackBar(content: Text('Added "${item.title}" to your wardrobe.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Couldn\'t add that image: $e')));
    }
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Tops':
        return Icons.checkroom;
      case 'Bottoms':
        return Icons.dry_cleaning;
      case 'Shoes':
        return Icons.hiking;
      default:
        return Icons.watch;
    }
  }
  @override
  void dispose() {
    _searchController.dispose();
    _discoverQueryController.dispose();
    super.dispose();
  }

  List<Outfit> _filteredOutfits(List<Outfit> outfits) {
    return outfits.where((o) {
      final matchesOccasion = _occasionFilter == 'All' || o.occasion == _occasionFilter;
      final matchesQuery = o.matches(_query);
      return matchesOccasion && matchesQuery;
    }).toList();
  }

  void _showOccasionFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter by Occasion', style: AppTextStyles.h2),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _occasions.map((v) {
                    final selected = v == _occasionFilter;
                    return ChoiceChip(
                      label: Text(v),
                      selected: selected,
                      onSelected: (_) {
                        setSheetState(() {});
                        setState(() => _occasionFilter = v);
                        Navigator.of(sheetContext).pop();
                      },
                      labelStyle: AppTextStyles.caption.copyWith(color: selected ? Colors.white : AppColors.textSecondary),
                      selectedColor: AppColors.violet,
                      backgroundColor: AppColors.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>(); // rebuild when favorites/wardrobe/custom outfits change elsewhere
    final results = _filteredOutfits(appState.allOutfits);
    final wardrobeResults = appState.wardrobe;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('Recommendations', style: AppTextStyles.h1),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _occasionFilter != 'All',
              smallSize: 8,
              backgroundColor: AppColors.magenta,
              child: const Icon(Icons.tune),
            ),
            onPressed: _showOccasionFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDiscoverSection(),
          const Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: AppTextStyles.bodyStrong,
              decoration: InputDecoration(
                hintText: 'Search outfits or items...',
                hintStyle: AppTextStyles.body,
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  borderSide: const BorderSide(color: AppColors.violet, width: 1.4),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Row(
                children: [
                  Expanded(child: _TabButton(label: 'Outfits', selected: _tab == 0, onTap: () => setState(() => _tab = 0))),
                  Expanded(child: _TabButton(label: 'Individual Items', selected: _tab == 1, onTap: () => setState(() => _tab = 1))),
                ],
              ),
            ),
          ),
          if (_occasionFilter != 'All')
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 10, AppSpacing.lg, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text('Occasion: $_occasionFilter'),
                  onDeleted: () => setState(() => _occasionFilter = 'All'),
                  backgroundColor: AppColors.surfaceElevated,
                  labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                  deleteIconColor: AppColors.textMuted,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _tab == 0
                ? (results.isEmpty
                    ? Center(child: Text('No outfits match your filters.', style: AppTextStyles.body))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
                        itemCount: results.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.62,
                        ),
                        itemBuilder: (context, i) {
                          final outfit = results[i];
                          return GestureDetector(
                            onLongPress: outfit.isCustom ? () => _confirmDeleteOutfit(context, outfit) : null,
                            child: OutfitCard(
                              outfit: outfit,
                              width: double.infinity,
                              onFavoriteToggle: () => context.read<AppState>().toggleFavorite(outfit),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => OutfitDetailsScreen(outfit: outfit)),
                              ),
                            ),
                          );
                        },
                      ))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
                    itemCount: wardrobeResults
                        .where((w) => _query.trim().isEmpty || w.name.toLowerCase().contains(_query.toLowerCase()))
                        .length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, i) {
                      final filtered = wardrobeResults
                          .where((w) => _query.trim().isEmpty || w.name.toLowerCase().contains(_query.toLowerCase()))
                          .toList();
                      final item = filtered[i];
                      return AuraCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FashionImagePlaceholder(accent: item.color, icon: item.icon, height: 90, width: double.infinity),
                            const SizedBox(height: 8),
                            Text(item.name, style: AppTextStyles.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(item.category, style: AppTextStyles.caption),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.violet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Create Outfit', style: AppTextStyles.bodyStrong.copyWith(color: Colors.white)),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateOutfitScreen()),
        ),
      ),
    );
  }

  Widget _buildDiscoverSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Generate outfit ideas', style: AppTextStyles.h2)),
              const AiBadge(label: 'Gemini', icon: Icons.auto_awesome),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 20),
                onPressed: _discoverLoading ? null : _generateImages,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _discoverQueryController,
                  style: AppTextStyles.body,
                  onSubmitted: (_) => _generateImages(),
                  decoration: InputDecoration(
                    hintText: 'e.g. "denim jacket outfit", "streetwear look"',
                    hintStyle: AppTextStyles.caption,
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.sm), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _discoverLoading ? null : _generateImages,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.violet, borderRadius: BorderRadius.circular(AppRadii.sm)),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 168,
            child: _discoverLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.violet),
                        SizedBox(height: 8),
                        Text('Generating with Gemini...', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  )
                : _discoverError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(_discoverError!, style: AppTextStyles.caption, textAlign: TextAlign.center),
                        ),
                      )
                    : _discoverResults.isEmpty
                        ? Center(child: Text('Type a description and tap generate.', style: AppTextStyles.caption))
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _discoverResults.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              final item = _discoverResults[i];
                              return SizedBox(
                                width: 118,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(AppRadii.md),
                                          child: Image.memory(
                                            item.bytes,
                                            height: 118,
                                            width: 118,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              height: 118,
                                              width: 118,
                                              color: AppColors.surface,
                                              child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => _addDiscoverItemToWardrobe(item),
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: const BoxDecoration(color: AppColors.violet, shape: BoxShape.circle),
                                              child: const Icon(Icons.add, color: Colors.white, size: 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(item.title, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('AI-generated', style: AppTextStyles.caption.copyWith(fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteOutfit(BuildContext context, Outfit outfit) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete outfit?', style: AppTextStyles.h2),
        content: Text('Remove "${outfit.name}" from your outfits.', style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<AppState>().deleteCustomOutfit(outfit.id);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.bodyStrong.copyWith(color: selected ? Colors.white : AppColors.textSecondary),
        ),
      ),
    );
  }
}
