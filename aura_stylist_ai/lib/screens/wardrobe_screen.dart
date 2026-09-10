import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'create_outfit_screen.dart';

class WardrobeScreen extends StatefulWidget {
  final bool embedded;
  const WardrobeScreen({super.key, this.embedded = false});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  String _category = 'All';
  String _query = '';
  final _categories = const ['All', 'Tops', 'Bottoms', 'Shoes', 'Accessories'];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final items = appState.wardrobe.where((w) {
      final matchesCategory = _category == 'All' || w.category == _category;
      final matchesQuery = _query.trim().isEmpty || w.name.toLowerCase().contains(_query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: Text('Wardrobe', style: AppTextStyles.h1),
          ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: AppTextStyles.bodyStrong,
            decoration: InputDecoration(
              hintText: 'Search your wardrobe...',
              hintStyle: AppTextStyles.body,
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.pill), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.pill), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.pill), borderSide: const BorderSide(color: AppColors.violet, width: 1.4)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final cat = _categories[i];
              final selected = cat == _category;
              return ChoiceChip(
                label: Text(cat),
                selected: selected,
                onSelected: (_) => setState(() => _category = cat),
                labelStyle: AppTextStyles.caption.copyWith(color: selected ? Colors.white : AppColors.textSecondary),
                selectedColor: AppColors.violet,
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  side: const BorderSide(color: AppColors.border),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      appState.wardrobe.isEmpty
                          ? 'Your wardrobe is empty. Tap "Add Item" to add your first piece.'
                          : 'No items match your search.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return GestureDetector(
                      onLongPress: () => _confirmDelete(context, item),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              item.imagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(AppRadii.md),
                                      child: Image.file(
                                        File(item.imagePath!),
                                        height: 90,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => FashionImagePlaceholder(accent: item.color, icon: item.icon, height: 90, width: double.infinity),
                                      ),
                                    )
                                  : FashionImagePlaceholder(accent: item.color, icon: item.icon, height: 90, width: double.infinity),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () => context.read<AppState>().toggleWardrobeFavorite(item.id),
                                  child: Icon(
                                    item.isFavorite ? Icons.favorite : Icons.favorite_border,
                                    size: 16,
                                    color: item.isFavorite ? AppColors.magenta : Colors.white70,
                                  ),
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
      ],
    );

    final fab = _AddItemButton(onTap: () => _openAddItemSheet(context));
    final createOutfitFab = _CreateOutfitButton(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateOutfitScreen()),
      ),
    );

    if (widget.embedded) {
      return Stack(
        children: [
          body,
          Positioned(
            right: AppSpacing.lg,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [createOutfitFab, const SizedBox(height: 12), fab],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text('Wardrobe', style: AppTextStyles.h1)),
      body: body,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [createOutfitFab, const SizedBox(height: 12), fab],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WardrobeItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Remove item?', style: AppTextStyles.h2),
        content: Text('Remove "${item.name}" from your wardrobe.', style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<AppState>().removeWardrobeItem(item.id);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _openAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: const _AddItemForm(),
      ),
    );
  }
}

class _AddItemForm extends StatefulWidget {
  const _AddItemForm();

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _category = 'Tops';
  String? _imagePath;
  bool _saving = false;

  final _categories = const ['Tops', 'Bottoms', 'Shoes', 'Accessories'];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
      if (picked != null) setState(() => _imagePath = picked.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not access camera/gallery: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<AppState>().addWardrobeItem(
          name: _nameController.text.trim(),
          category: _category,
          icon: _iconForCategory(_category),
          color: AppColors.violet,
          imagePath: _imagePath,
        );
    if (mounted) Navigator.of(context).pop();
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
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Item', style: AppTextStyles.h1),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showImageSourceSheet(context),
              child: _imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: Image.file(File(_imagePath!), height: 140, width: double.infinity, fit: BoxFit.cover),
                    )
                  : Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined, color: AppColors.textMuted),
                          const SizedBox(height: 8),
                          Text('Add a photo', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              style: AppTextStyles.bodyStrong,
              decoration: InputDecoration(
                labelText: 'Item name',
                labelStyle: AppTextStyles.body,
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: BorderSide.none),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name for this item' : null,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: _categories.map((c) {
                final selected = c == _category;
                return ChoiceChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = c),
                  labelStyle: AppTextStyles.caption.copyWith(color: selected ? Colors.white : AppColors.textSecondary),
                  selectedColor: AppColors.violet,
                  backgroundColor: AppColors.surfaceElevated,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill), side: const BorderSide(color: AppColors.border)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            GradientButton(label: _saving ? 'Saving...' : 'Save Item', icon: Icons.check, onPressed: _saving ? null : _save),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.textPrimary),
              title: Text('Take a photo', style: AppTextStyles.bodyStrong),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.textPrimary),
              title: Text('Choose from gallery', style: AppTextStyles.bodyStrong),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateOutfitButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateOutfitButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.checkroom, color: AppColors.textPrimary, size: 18),
              const SizedBox(width: 6),
              Text('Create Outfit', style: AppTextStyles.bodyStrong),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddItemButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddItemButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
