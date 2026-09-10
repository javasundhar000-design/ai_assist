import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../models/room_and_design_models.dart';
import '../../furniture/providers/furniture_provider.dart';
import '../../furniture/widgets/furniture_card.dart';

/// Returns the chosen [FurnitureModel], or null if dismissed without a
/// choice. Reuses the Phase 9 catalog stream rather than duplicating
/// fetch logic.
Future<FurnitureModel?> showFurniturePickerSheet(BuildContext context) {
  return showModalBottomSheet<FurnitureModel>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _FurniturePickerContent(),
  );
}

class _FurniturePickerContent extends ConsumerWidget {
  const _FurniturePickerContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(furnitureListProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Choose Furniture',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Expanded(
              child: catalogAsync.when(
                loading: () => const AppLoadingView(),
                error: (e, st) =>
                    const AppErrorView(message: 'Could not load furniture.'),
                data: (items) {
                  final placeable =
                      items.where((f) => f.modelUrl.isNotEmpty).toList();
                  if (placeable.isEmpty) {
                    return const AppEmptyView(
                      icon: Icons.view_in_ar_outlined,
                      message:
                          'No furniture with a 3D model is available yet.',
                    );
                  }
                  return GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: placeable.length,
                    itemBuilder: (context, index) {
                      final item = placeable[index];
                      return FurnitureCard(
                        furniture: item,
                        onTap: () => Navigator.of(context).pop(item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
