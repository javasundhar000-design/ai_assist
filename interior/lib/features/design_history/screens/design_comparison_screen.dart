import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_state_views.dart';
import '../providers/design_provider.dart';
import '../services/design_comparison_service.dart';

class DesignComparisonScreen extends ConsumerWidget {
  final String designIdA;
  final String designIdB;
  const DesignComparisonScreen(
      {super.key, required this.designIdA, required this.designIdB});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deps = ref.watch(designComparisonDepsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Design Comparison')),
      body: FutureBuilder(
        future: Future.wait([
          loadDesignComparisonBundle(deps: deps, designId: designIdA),
          loadDesignComparisonBundle(deps: deps, designId: designIdB),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const AppErrorView(
                message: 'Could not load one or both designs.');
          }
          final a = snapshot.data![0];
          final b = snapshot.data![1];

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _DesignHeader(name: a.design.name, label: 'A')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _DesignHeader(name: b.design.name, label: 'B')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _ComparisonRow(
                    label: 'Style',
                    valueA: a.design.style.label,
                    valueB: b.design.style.label,
                  ),
                  _ComparisonRow(
                    label: 'Furniture',
                    valueA: a.furnitureNames.isEmpty
                        ? '—'
                        : a.furnitureNames.join(', '),
                    valueB: b.furnitureNames.isEmpty
                        ? '—'
                        : b.furnitureNames.join(', '),
                  ),
                  _ComparisonRow(
                    label: 'Colors',
                    valueA: a.colors.isEmpty ? '—' : a.colors.join(', '),
                    valueB: b.colors.isEmpty ? '—' : b.colors.join(', '),
                  ),
                  _ComparisonRow(
                    label: 'Materials',
                    valueA: a.materials.isEmpty ? '—' : a.materials.join(', '),
                    valueB: b.materials.isEmpty ? '—' : b.materials.join(', '),
                  ),
                  _ComparisonRow(
                    label: 'Layout',
                    valueA: a.layoutSummary,
                    valueB: b.layoutSummary,
                  ),
                  _ComparisonRow(
                    label: 'Space Usage',
                    valueA: _formatSpaceUsage(a.spaceUsageFraction),
                    valueB: _formatSpaceUsage(b.spaceUsageFraction),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Layout and Space Usage are computed from each '
                            'design\'s actual saved furniture positions and '
                            'the room\'s estimated floor area — not '
                            'generic descriptions.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatSpaceUsage(double? fraction) {
    if (fraction == null) return 'Unknown (no room data)';
    return '${(fraction * 100).round()}% of floor area';
  }
}

class _DesignHeader extends StatelessWidget {
  final String name;
  final String label;
  const _DesignHeader({required this.name, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('DESIGN $label',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimaryContainer)),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String valueA;
  final String valueB;
  const _ComparisonRow({
    required this.label,
    required this.valueA,
    required this.valueB,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.outline, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(valueA)),
              const SizedBox(width: 12),
              Expanded(child: Text(valueB)),
            ],
          ),
          const Divider(height: 20),
        ],
      ),
    );
  }
}
