import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../furniture/providers/furniture_provider.dart';
import '../../room_analysis/providers/room_analysis_provider.dart';
import '../models/recommendation_models.dart';
import '../providers/design_preferences_provider.dart';
import '../services/recommendation_engine.dart';

class DesignRecommendationScreen extends ConsumerWidget {
  final String projectId;
  final String roomId;
  const DesignRecommendationScreen(
      {super.key, required this.projectId, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(designPreferencesProvider);
    final roomAsync = ref.watch(roomStreamProvider(roomId));
    final objectsAsync = ref.watch(detectedObjectsStreamProvider(roomId));
    final catalogAsync = ref.watch(furnitureListProvider);

    if (prefs.style == null) {
      // Guard against reaching this screen without a style — normal
      // navigation always sets one first (Get Recommendations is
      // disabled until a style is picked).
      return Scaffold(
        appBar: AppBar(title: const Text('Recommendations')),
        body: AppErrorView(
          message: 'Choose an interior style first.',
          onRetry: () => context.pop(),
        ),
      );
    }

    final loading = roomAsync.isLoading ||
        objectsAsync.isLoading ||
        catalogAsync.isLoading;
    final error = roomAsync.hasError || objectsAsync.hasError;

    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: SafeArea(
        child: loading
            ? const AppLoadingView(label: 'Building your recommendations…')
            : error
                ? const AppErrorView(
                    message: 'Could not load room data for recommendations.')
                : Builder(builder: (context) {
                    final room = roomAsync.value;
                    if (room == null) {
                      return const AppErrorView(message: 'Room not found.');
                    }
                    final objects = objectsAsync.value ?? const [];
                    final catalog = catalogAsync.value ?? const [];

                    final result = RecommendationEngine.generate(
                      input: RecommendationInput(
                        roomType: room.roomType,
                        floorAreaSqm: room.floorArea,
                        existingObjectTypes:
                            objects.map((o) => o.objectType).toSet(),
                        style: prefs.style!,
                        budget: prefs.budget,
                        colorPreference: prefs.colorPreference,
                      ),
                      catalog: catalog,
                    );

                    return _RecommendationBody(
                      projectId: projectId,
                      roomId: roomId,
                      budget: prefs.budget,
                      result: result,
                    );
                  }),
      ),
    );
  }
}

class _RecommendationBody extends StatelessWidget {
  final String projectId;
  final String roomId;
  final double budget;
  final RecommendationResult result;
  const _RecommendationBody({
    required this.projectId,
    required this.roomId,
    required this.budget,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionHeader(title: 'Recommended Furniture'),
        const SizedBox(height: 10),
        ...result.furniture.map((f) => _FurnitureRow(item: f)),
        const SizedBox(height: 8),
        Card(
          color: scheme.surfaceVariant,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimated Total'),
                Text(
                  '\$${result.estimatedTotalCost.toStringAsFixed(0)} '
                  'of \$${budget.toStringAsFixed(0)} budget',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Recommended Colors'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: result.colors.map((c) => Chip(label: Text(c))).toList(),
        ),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Recommended Materials'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              result.materials.map((m) => Chip(label: Text(m))).toList(),
        ),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Recommended Layout'),
        const SizedBox(height: 10),
        ...result.layout.map((l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.arrow_right_alt, color: scheme.primary, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: l.item,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: '  →  '),
                          TextSpan(text: l.placement),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => context
              .push('/projects/$projectId/room-analysis/$roomId/ar'),
          child: const Text('Continue to AR Visualization'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => context.push('/furniture'),
          child: const Text('Browse Full Furniture Catalog'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _FurnitureRow extends StatelessWidget {
  final RecommendedFurnitureItem item;
  const _FurnitureRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final match = item.matchedCatalogItem;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: item.alreadyPresent
                  ? scheme.surfaceVariant
                  : scheme.primaryContainer,
              child: Icon(
                item.alreadyPresent ? Icons.check : Icons.chair_alt_outlined,
                color: item.alreadyPresent
                    ? scheme.outline
                    : scheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.suggestionLabel,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(item.rationale,
                      style: Theme.of(context).textTheme.bodySmall),
                  if (match != null && !item.alreadyPresent) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => context.push('/furniture/${match.id}'),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${match.name} — \$${match.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              size: 16, color: scheme.primary),
                        ],
                      ),
                    ),
                    if (item.overBudget)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Over your remaining budget',
                          style: TextStyle(fontSize: 11, color: scheme.error),
                        ),
                      ),
                  ] else if (!item.alreadyPresent) ...[
                    const SizedBox(height: 4),
                    Text(
                      'No matching catalog item yet',
                      style: TextStyle(fontSize: 11, color: scheme.outline),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
