import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/constants/app_constants.dart';
import '../providers/design_preferences_provider.dart';
import '../services/style_catalog.dart';

const Map<InteriorStyle, IconData> _styleIcons = {
  InteriorStyle.modern: Icons.chair_alt_outlined,
  InteriorStyle.minimalist: Icons.crop_square_outlined,
  InteriorStyle.luxury: Icons.diamond_outlined,
  InteriorStyle.scandinavian: Icons.ac_unit_outlined,
  InteriorStyle.industrial: Icons.factory_outlined,
  InteriorStyle.traditional: Icons.castle_outlined,
  InteriorStyle.contemporary: Icons.blur_on_outlined,
  InteriorStyle.rustic: Icons.forest_outlined,
};

class DesignStyleSelectionScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String roomId;
  const DesignStyleSelectionScreen(
      {super.key, required this.projectId, required this.roomId});

  @override
  ConsumerState<DesignStyleSelectionScreen> createState() =>
      _DesignStyleSelectionScreenState();
}

class _DesignStyleSelectionScreenState
    extends ConsumerState<DesignStyleSelectionScreen> {
  final _colorController = TextEditingController();

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(designPreferencesProvider);
    final controller = ref.read(designPreferencesProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Interior Style')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Style', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Pick the interior style you want for this room.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: InteriorStyle.values.map((style) {
                  final selected = prefs.style == style;
                  final palette = StyleCatalog.paletteFor(style);
                  return _StyleCard(
                    style: style,
                    palette: palette,
                    selected: selected,
                    onTap: () => controller.setStyle(style),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Text('Budget', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '\$${prefs.budget.round()}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Slider(
                value: prefs.budget,
                min: 200,
                max: 10000,
                divisions: 49,
                label: '\$${prefs.budget.round()}',
                onChanged: controller.setBudget,
              ),
              const SizedBox(height: 20),
              Text('Color Preference (optional)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _colorController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Beige, Walnut, Charcoal',
                  prefixIcon: Icon(Icons.palette_outlined),
                ),
                onChanged: controller.setColorPreference,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: prefs.style == null
                      ? null
                      : () => context.push(
                            '/projects/${widget.projectId}/room-analysis/'
                            '${widget.roomId}/recommendations',
                          ),
                  child: const Text('Get Recommendations'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  final InteriorStyle style;
  final StylePalette palette;
  final bool selected;
  final VoidCallback onTap;

  const _StyleCard({
    required this.style,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              selected ? scheme.primaryContainer : scheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _styleIcons[style] ?? Icons.style_outlined,
              color: selected ? scheme.onPrimaryContainer : scheme.primary,
            ),
            const Spacer(),
            Text(
              style.label,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: palette.colors
                  .take(3)
                  .map((c) => _ColorDot(colorName: c))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final String colorName;
  const _ColorDot({required this.colorName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _swatchFor(colorName),
        border: Border.all(color: Colors.black12),
      ),
    );
  }

  Color _swatchFor(String name) {
    final key = name.toLowerCase();
    const table = {
      'white': Colors.white,
      'black': Colors.black,
      'charcoal': Color(0xFF36454F),
      'beige': Color(0xFFF5F0E6),
      'grey': Colors.grey,
      'light grey': Color(0xFFD9D9D9),
      'gold': Color(0xFFD4AF37),
      'emerald': Color(0xFF50C878),
      'light wood': Color(0xFFDEB887),
      'pale blue': Color(0xFFAFC8DC),
      'rust': Color(0xFFB7410E),
      'raw wood': Color(0xFFA97C50),
      'burgundy': Color(0xFF800020),
      'navy': Color(0xFF001F54),
      'taupe': Color(0xFF8B8589),
      'terracotta': Color(0xFFE2725B),
      'warm brown': Color(0xFF6B4226),
      'cream': Color(0xFFFFFDD0),
    };
    return table[key] ?? Colors.grey.shade400;
  }
}
