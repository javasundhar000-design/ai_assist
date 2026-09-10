import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'outfit_details_screen.dart';

/// Lets the user build a real outfit by selecting pieces from their own
/// wardrobe, naming it, and tagging an occasion. Saved outfits show up
/// everywhere seed outfits do — Recommendations, Favorites, Try-On, History.
class CreateOutfitScreen extends StatefulWidget {
  const CreateOutfitScreen({super.key});

  @override
  State<CreateOutfitScreen> createState() => _CreateOutfitScreenState();
}

class _CreateOutfitScreenState extends State<CreateOutfitScreen> {
  final _nameController = TextEditingController();
  final Set<String> _selectedIds = {};
  String _occasion = 'Casual';
  bool _saving = false;

  static const _occasions = ['Office', 'Casual', 'Party', 'Wedding', 'Sports'];
  static const _occasionColors = {
    'Office': Color(0xFF6D5EF5),
    'Casual': Color(0xFF38BDF8),
    'Party': Color(0xFFEC4899),
    'Wedding': Color(0xFFF59E0B),
    'Sports': Color(0xFF34D399),
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save(List<WardrobeItem> wardrobe) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Give your outfit a name.')));
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one piece from your wardrobe.')));
      return;
    }
    setState(() => _saving = true);
    final outfit = await context.read<AppState>().createOutfit(
          name: _nameController.text.trim(),
          occasion: _occasion,
          wardrobeItemIds: _selectedIds.toList(),
          accent: _occasionColors[_occasion] ?? AppColors.violet,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OutfitDetailsScreen(outfit: outfit)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<AppState>().wardrobe;

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text('Create Outfit', style: AppTextStyles.h1)),
      body: wardrobe.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Your wardrobe is empty. Add some items first, then come back to build an outfit from them.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: TextField(
                    controller: _nameController,
                    style: AppTextStyles.bodyStrong,
                    decoration: InputDecoration(
                      labelText: 'Outfit name',
                      labelStyle: AppTextStyles.body,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.violet, width: 1.4)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Occasion', style: AppTextStyles.caption),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    scrollDirection: Axis.horizontal,
                    itemCount: _occasions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final o = _occasions[i];
                      final selected = o == _occasion;
                      return ChoiceChip(
                        label: Text(o),
                        selected: selected,
                        onSelected: (_) => setState(() => _occasion = o),
                        labelStyle: AppTextStyles.caption.copyWith(color: selected ? Colors.white : AppColors.textSecondary),
                        selectedColor: _occasionColors[o],
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill), side: const BorderSide(color: AppColors.border)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select pieces (${_selectedIds.length} chosen)',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 16),
                    itemCount: wardrobe.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, i) {
                      final item = wardrobe[i];
                      final selected = _selectedIds.contains(item.id);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected) {
                            _selectedIds.remove(item.id);
                          } else {
                            _selectedIds.add(item.id);
                          }
                        }),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppRadii.md),
                                    border: Border.all(color: selected ? AppColors.violet : Colors.transparent, width: 2),
                                  ),
                                  child: item.imagePath != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(AppRadii.md),
                                          child: Image.file(File(item.imagePath!), height: 90, width: double.infinity, fit: BoxFit.cover),
                                        )
                                      : FashionImagePlaceholder(accent: item.color, icon: item.icon, height: 90, width: double.infinity),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Icon(
                                    selected ? Icons.check_circle : Icons.radio_button_unchecked,
                                    size: 18,
                                    color: selected ? AppColors.violet : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(item.name, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  child: GradientButton(
                    label: _saving ? 'Saving...' : 'Save Outfit',
                    icon: Icons.check,
                    onPressed: _saving ? null : () => _save(wardrobe),
                  ),
                ),
              ],
            ),
    );
  }
}
