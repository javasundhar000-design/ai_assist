import 'package:equatable/equatable.dart';
import '../../../app/constants/app_constants.dart';
import '../../../models/room_and_design_models.dart';

/// Everything the engine needs to produce a recommendation (Sec. 14 Input).
class RecommendationInput extends Equatable {
  final RoomType roomType;
  final double floorAreaSqm; // 0 if unknown
  final Set<String> existingObjectTypes; // detectedObjects.objectType values
  final InteriorStyle style;
  final double budget; // 0 = no budget limit
  final String? colorPreference; // free-text, matched loosely against colors

  const RecommendationInput({
    required this.roomType,
    required this.floorAreaSqm,
    required this.existingObjectTypes,
    required this.style,
    required this.budget,
    this.colorPreference,
  });

  @override
  List<Object?> get props => [
        roomType,
        floorAreaSqm,
        existingObjectTypes,
        style,
        budget,
        colorPreference,
      ];
}

/// One recommended furniture slot (Sec. 14 Output: "Recommended Furniture").
class RecommendedFurnitureItem extends Equatable {
  final FurnitureCategory category;
  final String suggestionLabel; // e.g. "3-Seater Sofa" or "Compact Loveseat"
  final String rationale;
  final bool alreadyPresent; // detected in the room scan already
  final bool overBudget; // matched item exists but exceeds remaining budget
  final FurnitureModel? matchedCatalogItem; // real catalog match, if any

  const RecommendedFurnitureItem({
    required this.category,
    required this.suggestionLabel,
    required this.rationale,
    required this.alreadyPresent,
    required this.overBudget,
    this.matchedCatalogItem,
  });

  @override
  List<Object?> get props => [
        category,
        suggestionLabel,
        rationale,
        alreadyPresent,
        overBudget,
        matchedCatalogItem,
      ];
}

/// One layout placement hint (Sec. 14 Output: "Recommended Layout").
/// Descriptive guidance only — real spatial placement comes from AR
/// anchors in Phase 12, this is the rule-based starting suggestion.
class LayoutSuggestion extends Equatable {
  final String item;
  final String placement;
  const LayoutSuggestion({required this.item, required this.placement});

  @override
  List<Object?> get props => [item, placement];
}

/// Full engine output (Sec. 14).
class RecommendationResult extends Equatable {
  final List<RecommendedFurnitureItem> furniture;
  final List<String> colors;
  final List<String> materials;
  final List<LayoutSuggestion> layout;
  final double estimatedTotalCost;

  const RecommendationResult({
    required this.furniture,
    required this.colors,
    required this.materials,
    required this.layout,
    required this.estimatedTotalCost,
  });

  @override
  List<Object?> get props =>
      [furniture, colors, materials, layout, estimatedTotalCost];
}
