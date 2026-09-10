import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../models/room_and_design_models.dart';
import '../providers/design_provider.dart';

class DesignComparisonSelectScreen extends ConsumerStatefulWidget {
  final String projectId;
  const DesignComparisonSelectScreen({super.key, required this.projectId});

  @override
  ConsumerState<DesignComparisonSelectScreen> createState() =>
      _DesignComparisonSelectScreenState();
}

class _DesignComparisonSelectScreenState
    extends ConsumerState<DesignComparisonSelectScreen> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final designsAsync = ref.watch(projectDesignsProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Compare Designs')),
      body: designsAsync.when(
        loading: () => const AppLoadingView(),
        error: (e, st) =>
            const AppErrorView(message: 'Could not load your designs.'),
        data: (designs) {
          final active = designs.where((d) => !d.isDeleted).toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          if (active.length < 2) {
            return const AppEmptyView(
              icon: Icons.compare_arrows_outlined,
              message:
                  'You need at least two saved designs to compare.\nSave '
                  'another version from AR Visualization first.',
            );
          }

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Choose exactly two designs (${_selected.length}/2 selected)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: active.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final design = active[index];
                      final isSelected = _selected.contains(design.id);
                      final disableUnselected =
                          _selected.length >= 2 && !isSelected;
                      return _SelectableDesignTile(
                        design: design,
                        selected: isSelected,
                        enabled: !disableUnselected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selected.add(design.id);
                            } else {
                              _selected.remove(design.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _selected.length == 2
                          ? () {
                              final ids = _selected.toList();
                              context.push(
                                '/projects/${widget.projectId}/designs/compare'
                                '?a=${ids[0]}&b=${ids[1]}',
                              );
                            }
                          : null,
                      child: const Text('Compare'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SelectableDesignTile extends StatelessWidget {
  final DesignModel design;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  const _SelectableDesignTile({
    required this.design,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        value: selected,
        onChanged: enabled ? onChanged : null,
        title: Text(design.name),
        subtitle: Text(design.style.label),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
