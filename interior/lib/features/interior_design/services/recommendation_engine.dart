import '../../../models/room_and_design_models.dart';
import '../models/recommendation_models.dart';
import 'detected_type_mapping.dart';
import 'style_catalog.dart';

/// Rule-based interior design recommendation engine (Sec. 14).
///
/// Deliberately simple and table-driven rather than "smart" — every
/// decision traces back to a rule in [StyleCatalog] or the logic below,
/// so it's auditable and easy to extend without an external AI service.
/// This is the "keep this recommendation engine modular so its rules can
/// be improved later" requirement in Sec. 14.
class RecommendationEngine {
  RecommendationEngine._();

  /// Below this floor area, the engine swaps in compact furniture labels
  /// where a plan item defines one (e.g. "3-Seater Sofa" -> "Compact
  /// Loveseat"). This is a sizing *hint* for recommendations, not the
  /// full physical fit-checking that Space Validation (Phase 13) does
  /// against actual placed furniture dimensions.
  static const double _smallSpaceThresholdSqm = 12.0;

  static RecommendationResult generate({
    required RecommendationInput input,
    required List<FurnitureModel> catalog,
  }) {
    final palette = StyleCatalog.paletteFor(input.style);
    final plan = StyleCatalog.planFor(input.roomType);
    final isSmallSpace =
        input.floorAreaSqm > 0 && input.floorAreaSqm < _smallSpaceThresholdSqm;

    final existingCategories = input.existingObjectTypes
        .map(detectedTypeToCategory)
        .whereType<FurnitureCategory>()
        .toSet();

    final furnitureItems = <RecommendedFurnitureItem>[];
    var remainingBudget = input.budget > 0 ? input.budget : double.infinity;

    for (final planItem in plan) {
      final alreadyPresent = existingCategories.contains(planItem.category);

      FurnitureModel? match;
      var overBudget = false;

      if (!alreadyPresent) {
        final candidates = _rankedCandidates(
          catalog: catalog,
          category: planItem.category,
          style: input.style,
          colorPreference: input.colorPreference,
        );

        // Prefer the best-ranked candidate that fits what's left of the
        // budget; if none fit, still surface the best match but flag it.
        final affordable =
            candidates.where((c) => c.price <= remainingBudget).toList();
        match = affordable.isNotEmpty ? affordable.first : null;

        if (match == null && candidates.isNotEmpty) {
          match = candidates.first;
          overBudget = input.budget > 0;
        }
        if (match != null && !overBudget) {
          remainingBudget -= match.price;
        }
      }

      furnitureItems.add(RecommendedFurnitureItem(
        category: planItem.category,
        suggestionLabel: (isSmallSpace && planItem.compactLabel != null)
            ? planItem.compactLabel!
            : planItem.label,
        rationale: alreadyPresent
            ? 'Already detected in your room scan — no need to add another.'
            : planItem.rationale,
        alreadyPresent: alreadyPresent,
        overBudget: overBudget,
        matchedCatalogItem: match,
      ));
    }

    final estimatedTotalCost = furnitureItems
        .where((f) => !f.alreadyPresent && !f.overBudget)
        .fold<double>(0, (sum, f) => sum + (f.matchedCatalogItem?.price ?? 0));

    return RecommendationResult(
      furniture: furnitureItems,
      colors: palette.colors,
      materials: palette.materials,
      layout: plan
          .map((p) => LayoutSuggestion(item: p.label, placement: p.placement))
          .toList(),
      estimatedTotalCost: estimatedTotalCost,
    );
  }

  /// Ranks catalog items for one furniture slot: exact style match first,
  /// then color-preference match, then cheapest — all as simple,
  /// explicit tie-breakers rather than a black-box score.
  static List<FurnitureModel> _rankedCandidates({
    required List<FurnitureModel> catalog,
    required FurnitureCategory category,
    required InteriorStyle style,
    required String? colorPreference,
  }) {
    final candidates = catalog.where((f) => f.category == category).toList();
    candidates.sort((a, b) {
      final styleRank = (a.style == style ? 0 : 1) - (b.style == style ? 0 : 1);
      if (styleRank != 0) return styleRank;

      if (colorPreference != null && colorPreference.trim().isNotEmpty) {
        final query = colorPreference.trim().toLowerCase();
        final aColorMatch = a.color.toLowerCase().contains(query) ? 0 : 1;
        final bColorMatch = b.color.toLowerCase().contains(query) ? 0 : 1;
        if (aColorMatch != bColorMatch) return aColorMatch - bColorMatch;
      }

      return a.price.compareTo(b.price);
    });
    return candidates;
  }
}
