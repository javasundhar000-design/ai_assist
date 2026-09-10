import 'dart:ui';

import 'package:aura_stylist_ai/features/tryon/domain/entities/body_anchor_points.dart';
import 'package:aura_stylist_ai/features/tryon/domain/entities/clothing_anchor_config.dart';
import 'package:aura_stylist_ai/features/tryon/domain/services/clothing_transform_calculator.dart';
import 'package:aura_stylist_ai/features/vision/domain/entities/face_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

BodyAnchorPoints _buildAnchors({
  Offset? leftAnkle,
  Offset? rightAnkle,
  double bodyRotationRadians = 0,
}) {
  return BodyAnchorPoints(
    neck: const Offset(100, 90),
    leftShoulder: const Offset(60, 100),
    rightShoulder: const Offset(140, 100),
    chestCenter: const Offset(100, 144),
    waist: const Offset(100, 270),
    leftHip: const Offset(70, 300),
    rightHip: const Offset(130, 300),
    hipCenter: const Offset(100, 300),
    shoulderWidth: 80,
    hipWidth: 60,
    torsoHeight: 200,
    bodyRotationRadians: bodyRotationRadians,
    imageSize: const Size(200, 600),
    leftAnkle: leftAnkle,
    rightAnkle: rightAnkle,
  );
}

void main() {
  const calculator = ClothingTransformCalculator();

  group('neckToChest (shirt/jacket)', () {
    test('widens with widthScale and sizes from shoulderWidth', () {
      final anchors = _buildAnchors();
      const config = ClothingAnchorConfig(
        reference: AnchorReference.neckToChest,
        widthScale: 1.2,
        aspectRatio: 1.0,
      );
      final transform = calculator.calculate(config, anchors);

      expect(transform, isNotNull);
      expect(transform!.width, closeTo(80 * 1.2, 0.01));
      expect(transform.height, closeTo(80 * 1.2, 0.01)); // aspectRatio 1.0
    });

    test('verticalOffsetFraction moves the center further from the neck', () {
      final anchors = _buildAnchors();
      const near = ClothingAnchorConfig(
        reference: AnchorReference.neckToChest,
        verticalOffsetFraction: 0.5,
      );
      const far = ClothingAnchorConfig(
        reference: AnchorReference.neckToChest,
        verticalOffsetFraction: 2.0,
      );

      final nearTransform = calculator.calculate(near, anchors)!;
      final farTransform = calculator.calculate(far, anchors)!;

      final neckToNear = (nearTransform.center - anchors.neck).distance;
      final neckToFar = (farTransform.center - anchors.neck).distance;
      expect(neckToFar, greaterThan(neckToNear));
    });

    test('rotation matches the body rotation', () {
      final anchors = _buildAnchors(bodyRotationRadians: 0.3);
      const config = ClothingAnchorConfig(reference: AnchorReference.neckToChest);
      final transform = calculator.calculate(config, anchors)!;
      expect(transform.rotationRadians, 0.3);
    });
  });

  group('hipToBelow (pants)', () {
    test('sizes from hipWidth, not shoulderWidth', () {
      final anchors = _buildAnchors();
      const config = ClothingAnchorConfig(reference: AnchorReference.hipToBelow, widthScale: 1.0);
      final transform = calculator.calculate(config, anchors)!;
      expect(transform.width, closeTo(60, 0.01)); // hipWidth, not shoulderWidth (80)
    });
  });

  group('headTop (hat/hair)', () {
    test('positions above the neck (smaller y)', () {
      final anchors = _buildAnchors();
      const config = ClothingAnchorConfig(reference: AnchorReference.headTop);
      final transform = calculator.calculate(config, anchors)!;
      expect(transform.center.dy, lessThan(anchors.neck.dy));
    });
  });

  group('eyesLevel (glasses)', () {
    test('uses face eye landmarks when a face is present', () {
      final anchors = _buildAnchors();
      const config = ClothingAnchorConfig(reference: AnchorReference.eyesLevel, widthScale: 1.0);
      final face = FaceAnalysis(
        boundingBox: const Rect.fromLTWH(50, 20, 100, 100),
        landmarks: const {
          FaceLandmarkKind.leftEye: Offset(80, 50),
          FaceLandmarkKind.rightEye: Offset(120, 50),
        },
        contours: const {},
        headEulerAngleX: 0,
        headEulerAngleY: 0,
        headEulerAngleZ: 0,
        imageSize: const Size(200, 600),
      );

      final transform = calculator.calculate(config, anchors, face: face)!;

      expect(transform.center, const Offset(100, 50));
      expect(transform.width, closeTo(40 * 2.4, 0.01)); // (rightEye-leftEye).distance * 2.4
    });

    test('falls back to a pose-only estimate with no face', () {
      final anchors = _buildAnchors();
      const config = ClothingAnchorConfig(reference: AnchorReference.eyesLevel);
      final transform = calculator.calculate(config, anchors);
      expect(transform, isNotNull);
      expect(transform!.width, closeTo(anchors.shoulderWidth * 0.5, 0.01));
    });
  });

  group('ankles (shoes)', () {
    test('returns null when either ankle is missing', () {
      final anchors = _buildAnchors(leftAnkle: const Offset(75, 550));
      const config = ClothingAnchorConfig(reference: AnchorReference.ankles);
      expect(calculator.calculate(config, anchors), isNull);
    });

    test('centers between both ankles when both are visible', () {
      final anchors = _buildAnchors(
        leftAnkle: const Offset(80, 550),
        rightAnkle: const Offset(120, 550),
      );
      const config = ClothingAnchorConfig(reference: AnchorReference.ankles);
      final transform = calculator.calculate(config, anchors)!;
      expect(transform.center, const Offset(100, 550));
    });
  });

  group('chestPendant (accessories)', () {
    test('is small and centered at chestCenter', () {
      final anchors = _buildAnchors();
      const config = ClothingAnchorConfig(reference: AnchorReference.chestPendant);
      final transform = calculator.calculate(config, anchors)!;
      expect(transform.center, anchors.chestCenter);
      expect(transform.width, lessThan(anchors.shoulderWidth));
    });
  });
}
