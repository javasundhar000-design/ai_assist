import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/constants/app_constants.dart';
import '../../../core/widgets/app_state_views.dart';
import '../providers/furniture_provider.dart';
import '../widgets/furniture_card.dart';
import '../widgets/furniture_filter_sheet.dart';

class FurnitureCatalogScreen extends ConsumerStatefulWidget {
  const FurnitureCatalogScreen({super.key});

  @override
  ConsumerState<FurnitureCatalogScreen> createState() =>
      _FurnitureCatalogScreenState();
}

class _FurnitureCatalogScreenState
    extends ConsumerState<FurnitureCatalogScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredFurnitureProvider);
    final rawList = ref.watch(furnitureListProvider);
    final filters = ref.watch(furnitureFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Furniture Catalog'),
        actions: [
          IconButton(
            tooltip: 'Filter',
            icon: Badge(
              isLabelVisible: !filters.isDefault,
              smallSize: 8,
              child: const Icon(Icons.tune),
            ),
            onPressed: () => showFurnitureFilterSheet(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search furniture…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(furnitureFilterProvider.notifier)
                                .setQuery('');
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (v) {
                  ref.read(furnitureFilterProvider.notifier).setQuery(v);
                  setState(() {});
                },
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    label: 'All',
                    selected: filters.category == null,
                    onSelected: () => ref
                        .read(furnitureFilterProvider.notifier)
                        .setCategory(null),
                  ),
                  const SizedBox(width: 8),
                  ...FurnitureCategory.values.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _CategoryChip(
                          label: c.label,
                          selected: filters.category == c,
                          onSelected: () => ref
                              .read(furnitureFilterProvider.notifier)
                              .setCategory(filters.category == c ? null : c),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.when(
                loading: () => const AppLoadingView(),
                error: (e, st) => AppErrorView(
                  message: 'Could not load the furniture catalog.',
                  onRetry: () => ref.invalidate(furnitureListProvider),
                ),
                data: (items) {
                  final catalogIsEmpty =
                      rawList.valueOrNull?.isEmpty ?? false;
                  if (catalogIsEmpty) {
                    return const AppEmptyView(
                      icon: Icons.inventory_2_outlined,
                      message:
                          'The furniture catalog is empty.\nAsk an admin to '
                          'add items to the catalog — see the README for '
                          'the seeding steps.',
                    );
                  }
                  if (items.isEmpty) {
                    return AppEmptyView(
                      icon: Icons.search_off,
                      message: 'No furniture matches your search or filters.',
                      action: OutlinedButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(furnitureFilterProvider.notifier).reset();
                          setState(() {});
                        },
                        child: const Text('Clear Filters'),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return FurnitureCard(
                        furniture: item,
                        onTap: () => context.push('/furniture/${item.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
