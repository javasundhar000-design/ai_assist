import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_state_views.dart';
import '../providers/furniture_provider.dart';

class FurnitureDetailsScreen extends ConsumerWidget {
  final String furnitureId;
  const FurnitureDetailsScreen({super.key, required this.furnitureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(furnitureRepositoryProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: FutureBuilder(
        future: repo.getById(furnitureId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView();
          }
          final item = snapshot.data;
          if (item == null) {
            return const AppErrorView(message: 'Furniture item not found.');
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 260,
                flexibleSpace: FlexibleSpaceBar(
                  background: item.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: scheme.surfaceVariant,
                            child: Icon(Icons.chair_alt_outlined,
                                size: 48, color: scheme.outline),
                          ),
                        )
                      : Container(
                          color: scheme.surfaceVariant,
                          child: Icon(Icons.chair_alt_outlined,
                              size: 48, color: scheme.outline),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(item.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall),
                          ),
                          Text(
                            '\$${item.price.toStringAsFixed(0)}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: scheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text(item.category.label)),
                          Chip(label: Text(item.style.label)),
                          if (item.material.isNotEmpty)
                            Chip(label: Text(item.material)),
                          if (item.color.isNotEmpty)
                            Chip(label: Text(item.color)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (item.description.isNotEmpty) ...[
                        Text('Description',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 6),
                        Text(item.description),
                        const SizedBox(height: 20),
                      ],
                      Text('Dimensions',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _DimStat(label: 'Width', value: '${item.width} cm'),
                          _DimStat(
                              label: 'Height', value: '${item.height} cm'),
                          _DimStat(label: 'Depth', value: '${item.depth} cm'),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text(
                              'Adding furniture to a design arrives with '
                              'the Design Editor phase.',
                            ),
                          )),
                          icon: const Icon(Icons.add),
                          label: const Text('Add to Design'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: item.modelUrl.isEmpty
                              ? null
                              : () => context.push('/furniture/${item.id}/3d'),
                          icon: const Icon(Icons.view_in_ar_outlined),
                          label: Text(
                            item.modelUrl.isEmpty
                                ? 'No 3D Model Available'
                                : 'View in 3D',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DimStat extends StatelessWidget {
  final String label;
  final String value;
  const _DimStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
