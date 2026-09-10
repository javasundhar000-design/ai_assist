import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/constants/app_constants.dart';
import '../../../models/room_and_design_models.dart';
import '../../authentication/providers/auth_provider.dart';
import '../repositories/furniture_repository.dart';

final furnitureRepositoryProvider = Provider<FurnitureRepository>((ref) {
  return FurnitureRepository(ref.watch(realtimeDatabaseServiceProvider));
});

final furnitureListProvider = StreamProvider<List<FurnitureModel>>((ref) {
  return ref.watch(furnitureRepositoryProvider).watchAll();
});

const kPriceUpperBound = 5000.0;
const kSizeUpperBoundCm = 300.0; // width filter, in cm

@immutable
class FurnitureFilters {
  final String query;
  final FurnitureCategory? category;
  final InteriorStyle? style;
  final RangeValues priceRange;
  final RangeValues sizeRange;

  const FurnitureFilters({
    this.query = '',
    this.category,
    this.style,
    this.priceRange = const RangeValues(0, kPriceUpperBound),
    this.sizeRange = const RangeValues(0, kSizeUpperBoundCm),
  });

  bool get isDefault =>
      query.isEmpty &&
      category == null &&
      style == null &&
      priceRange.start == 0 &&
      priceRange.end == kPriceUpperBound &&
      sizeRange.start == 0 &&
      sizeRange.end == kSizeUpperBoundCm;
}

class FurnitureFilterController extends StateNotifier<FurnitureFilters> {
  FurnitureFilterController() : super(const FurnitureFilters());

  void setQuery(String query) {
    state = FurnitureFilters(
      query: query,
      category: state.category,
      style: state.style,
      priceRange: state.priceRange,
      sizeRange: state.sizeRange,
    );
  }

  void setCategory(FurnitureCategory? category) {
    state = FurnitureFilters(
      query: state.query,
      category: category,
      style: state.style,
      priceRange: state.priceRange,
      sizeRange: state.sizeRange,
    );
  }

  void setStyle(InteriorStyle? style) {
    state = FurnitureFilters(
      query: state.query,
      category: state.category,
      style: style,
      priceRange: state.priceRange,
      sizeRange: state.sizeRange,
    );
  }

  void setPriceRange(RangeValues range) {
    state = FurnitureFilters(
      query: state.query,
      category: state.category,
      style: state.style,
      priceRange: range,
      sizeRange: state.sizeRange,
    );
  }

  void setSizeRange(RangeValues range) {
    state = FurnitureFilters(
      query: state.query,
      category: state.category,
      style: state.style,
      priceRange: state.priceRange,
      sizeRange: range,
    );
  }

  void reset() => state = const FurnitureFilters();
}

final furnitureFilterProvider =
    StateNotifierProvider<FurnitureFilterController, FurnitureFilters>(
  (ref) => FurnitureFilterController(),
);

/// The catalog after applying the current filters. Filtering happens
/// client-side over the (typically small, prototype-scale) catalog
/// already streamed from Realtime Database — fine for a few hundred
/// items, but would want server-side querying at real catalog scale.
final filteredFurnitureProvider = Provider<AsyncValue<List<FurnitureModel>>>((ref) {
  final furnitureAsync = ref.watch(furnitureListProvider);
  final filters = ref.watch(furnitureFilterProvider);

  return furnitureAsync.whenData((items) {
    return items.where((item) {
      if (filters.query.isNotEmpty &&
          !item.name.toLowerCase().contains(filters.query.toLowerCase())) {
        return false;
      }
      if (filters.category != null && item.category != filters.category) {
        return false;
      }
      if (filters.style != null && item.style != filters.style) {
        return false;
      }
      if (item.price < filters.priceRange.start ||
          item.price > filters.priceRange.end) {
        return false;
      }
      if (item.width < filters.sizeRange.start ||
          item.width > filters.sizeRange.end) {
        return false;
      }
      return true;
    }).toList();
  });
});
