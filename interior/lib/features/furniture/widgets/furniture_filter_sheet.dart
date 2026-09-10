import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/constants/app_constants.dart';
import '../providers/furniture_provider.dart';

Future<void> showFurnitureFilterSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _FilterSheetContent(),
  );
}

class _FilterSheetContent extends ConsumerStatefulWidget {
  const _FilterSheetContent();

  @override
  ConsumerState<_FilterSheetContent> createState() =>
      _FilterSheetContentState();
}

class _FilterSheetContentState extends ConsumerState<_FilterSheetContent> {
  late InteriorStyle? _style;
  late RangeValues _priceRange;
  late RangeValues _sizeRange;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(furnitureFilterProvider);
    _style = filters.style;
    _priceRange = filters.priceRange;
    _sizeRange = filters.sizeRange;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter Furniture', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Text('Style', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<InteriorStyle?>(
            value: _style,
            decoration: const InputDecoration(labelText: 'Any style'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any style')),
              ...InteriorStyle.values.map(
                (s) => DropdownMenuItem(value: s, child: Text(s.label)),
              ),
            ],
            onChanged: (v) => setState(() => _style = v),
          ),
          const SizedBox(height: 20),
          Text(
            'Price: \$${_priceRange.start.round()} - \$${_priceRange.end.round()}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: kPriceUpperBound,
            divisions: 20,
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: (v) => setState(() => _priceRange = v),
          ),
          const SizedBox(height: 12),
          Text(
            'Width: ${_sizeRange.start.round()}cm - ${_sizeRange.end.round()}cm',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          RangeSlider(
            values: _sizeRange,
            min: 0,
            max: kSizeUpperBoundCm,
            divisions: 20,
            labels: RangeLabels(
              '${_sizeRange.start.round()}cm',
              '${_sizeRange.end.round()}cm',
            ),
            onChanged: (v) => setState(() => _sizeRange = v),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _style = null;
                      _priceRange = const RangeValues(0, kPriceUpperBound);
                      _sizeRange = const RangeValues(0, kSizeUpperBoundCm);
                    });
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final controller =
                        ref.read(furnitureFilterProvider.notifier);
                    controller.setStyle(_style);
                    controller.setPriceRange(_priceRange);
                    controller.setSizeRange(_sizeRange);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
