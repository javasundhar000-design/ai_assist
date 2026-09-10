import 'dart:ui';

import 'package:aura_stylist_ai/features/tryon/domain/entities/clothing_anchor_config.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/clothing_item.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/clothing_layer.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/fit_type.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/occasion.dart';
import 'package:aura_stylist_ai/features/tryon/presentation/providers/try_on_session_controller.dart';
import 'package:aura_stylist_ai/features/vision/domain/entities/pose_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

const _shirt = ClothingItem(
  id: 'shirt-1',
  name: 'Test Shirt',
  layer: ClothingLayer.shirt,
  color: Color(0xFF000000),
  anchorConfig: ClothingAnchorConfig(reference: AnchorReference.neckToChest),
  fit: FitType.regular,
  suitableOccasions: [Occasion.casual],
);

const _pants = ClothingItem(
  id: 'pants-1',
  name: 'Test Pants',
  layer: ClothingLayer.pant,
  color: Color(0xFF111111),
  anchorConfig: ClothingAnchorConfig(reference: AnchorReference.hipToBelow),
  fit: FitType.regular,
  suitableOccasions: [Occasion.casual],
);

PoseAnalysis _validPose() {
  return const PoseAnalysis(
    imageSize: Size(200, 600),
    landmarks: {
      PoseLandmarkKind.leftShoulder: PoseKeypoint(x: 60, y: 100, z: 0, likelihood: 0.9),
      PoseLandmarkKind.rightShoulder: PoseKeypoint(x: 140, y: 100, z: 0, likelihood: 0.9),
      PoseLandmarkKind.leftHip: PoseKeypoint(x: 70, y: 300, z: 0, likelihood: 0.9),
      PoseLandmarkKind.rightHip: PoseKeypoint(x: 130, y: 300, z: 0, likelihood: 0.9),
    },
  );
}

void main() {
  group('TryOnSessionController', () {
    test('selectItem() adds the item to selectedItems for its layer', () {
      final controller = TryOnSessionController();
      controller.selectItem(_shirt);
      expect(controller.state.selectedItems[ClothingLayer.shirt], _shirt);
    });

    test('selecting a second item for the same layer replaces the first', () {
      const otherShirt = ClothingItem(
        id: 'shirt-2',
        name: 'Other Shirt',
        layer: ClothingLayer.shirt,
        color: Color(0xFFFFFFFF),
        anchorConfig: ClothingAnchorConfig(reference: AnchorReference.neckToChest),
        fit: FitType.regular,
        suitableOccasions: [Occasion.casual],
      );
      final controller = TryOnSessionController();
      controller.selectItem(_shirt);
      controller.selectItem(otherShirt);
      expect(controller.state.selectedItems[ClothingLayer.shirt], otherShirt);
      expect(controller.state.selectedItems.length, 1);
    });

    test('removeLayer() clears both the selection and its transform', () {
      final controller = TryOnSessionController();
      controller.selectItem(_shirt);
      controller.onPoseUpdate(_validPose(), null);
      expect(controller.state.transforms.containsKey(ClothingLayer.shirt), isTrue);

      controller.removeLayer(ClothingLayer.shirt);

      expect(controller.state.selectedItems.containsKey(ClothingLayer.shirt), isFalse);
      expect(controller.state.transforms.containsKey(ClothingLayer.shirt), isFalse);
    });

    test('onPoseUpdate() computes transforms for every selected layer', () {
      final controller = TryOnSessionController();
      controller.selectItem(_shirt);
      controller.selectItem(_pants);

      controller.onPoseUpdate(_validPose(), null);

      expect(controller.state.anchors, isNotNull);
      expect(
        controller.state.transforms.keys,
        containsAll([ClothingLayer.shirt, ClothingLayer.pant]),
      );
    });

    test('onPoseUpdate() with an unusable pose keeps the last known state', () {
      final controller = TryOnSessionController();
      controller.selectItem(_shirt);
      controller.onPoseUpdate(_validPose(), null);
      final anchorsBefore = controller.state.anchors;

      const badPose = PoseAnalysis(landmarks: {}, imageSize: Size(200, 600));
      controller.onPoseUpdate(badPose, null);

      expect(controller.state.anchors, same(anchorsBefore));
      expect(controller.state.transforms.containsKey(ClothingLayer.shirt), isTrue);
    });

    test('selectItem() immediately computes a transform if anchors are already known', () {
      final controller = TryOnSessionController();
      controller.onPoseUpdate(_validPose(), null); // no items selected yet, but anchors get cached
      controller.selectItem(_shirt);

      expect(controller.state.transforms.containsKey(ClothingLayer.shirt), isTrue);
    });

    test('reset() clears everything', () {
      final controller = TryOnSessionController();
      controller.selectItem(_shirt);
      controller.onPoseUpdate(_validPose(), null);

      controller.reset();

      expect(controller.state.selectedItems, isEmpty);
      expect(controller.state.transforms, isEmpty);
      expect(controller.state.anchors, isNull);
    });
  });
}
