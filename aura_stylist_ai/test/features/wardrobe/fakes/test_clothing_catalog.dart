import 'dart:ui';

import 'package:aura_stylist_ai/features/tryon/domain/entities/clothing_anchor_config.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/clothing_item.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/clothing_layer.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/fit_type.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/occasion.dart';

/// A minimal 2-item "catalog" for wardrobe tests — enough to exercise
/// `WardrobeController.resolveItems` without depending on the full demo
/// catalog (which can grow/change independently of what these tests
/// check).
const testClothingCatalog = [
  ClothingItem(
    id: 'shirt-navy',
    name: 'Navy Shirt',
    layer: ClothingLayer.shirt,
    color: Color(0xFF1B2A4A),
    anchorConfig: ClothingAnchorConfig(reference: AnchorReference.neckToChest),
    fit: FitType.regular,
    suitableOccasions: [Occasion.office, Occasion.interview],
  ),
  ClothingItem(
    id: 'pant-denim',
    name: 'Denim Pants',
    layer: ClothingLayer.pant,
    color: Color(0xFF3A5A8C),
    anchorConfig: ClothingAnchorConfig(reference: AnchorReference.hipToBelow),
    fit: FitType.slim,
    suitableOccasions: [Occasion.casual],
  ),
];
