import 'dart:ui';

import 'package:aura_stylist_ai/features/vision/domain/entities/face_analysis.dart';
import 'package:aura_stylist_ai/features/vision/domain/entities/face_shape.dart';
import 'package:aura_stylist_ai/features/vision/domain/services/face_shape_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

const _centerX = 100.0;
const _length = 200.0; // default box height; overridden per-case below

FaceAnalysis _buildFace({
  required double length,
  required double cheekWidth,
  required double foreheadWidth,
  required double jawWidth,
}) {
  final box = Rect.fromLTWH(0, 0, cheekWidth + 40, length);
  final foreheadY = box.top + box.height * 0.12;
  final jawY = box.top + box.height * 0.88;
  final cheekY = box.top + box.height * 0.5;

  final contour = <Offset>[
    Offset(_centerX - foreheadWidth / 2, foreheadY),
    Offset(_centerX + foreheadWidth / 2, foreheadY),
    Offset(_centerX - jawWidth / 2, jawY),
    Offset(_centerX + jawWidth / 2, jawY),
    // Filler points in the "safe" mid-height zone, away from the forehead
    // and jaw sampling bands, just to satisfy the >=10 point minimum.
    for (final f in [0.3, 0.4, 0.5, 0.6, 0.7, 0.8])
      Offset(_centerX + (f - 0.5) * 60, box.top + box.height * f),
  ];

  return FaceAnalysis(
    boundingBox: box,
    landmarks: {
      FaceLandmarkKind.leftCheek: Offset(_centerX - cheekWidth / 2, cheekY),
      FaceLandmarkKind.rightCheek: Offset(_centerX + cheekWidth / 2, cheekY),
    },
    contours: {FaceContourKind.face: contour},
    headEulerAngleX: 0,
    headEulerAngleY: 0,
    headEulerAngleZ: 0,
    imageSize: const Size(300, 300),
  );
}

void main() {
  const estimator = FaceShapeEstimator();

  test('long face with even proportions -> oval', () {
    final face = _buildFace(length: 200, cheekWidth: 100, foreheadWidth: 95, jawWidth: 95);
    expect(estimator.estimate(face), FaceShape.oval);
  });

  test('long face, narrow jaw, wide forehead -> heart', () {
    final face = _buildFace(length: 200, cheekWidth: 100, foreheadWidth: 100, jawWidth: 70);
    expect(estimator.estimate(face), FaceShape.heart);
  });

  test('long face, narrow jaw AND narrow forehead (wide cheekbones) -> diamond', () {
    final face = _buildFace(length: 200, cheekWidth: 100, foreheadWidth: 60, jawWidth: 70);
    expect(estimator.estimate(face), FaceShape.diamond);
  });

  test('short face with even, wide proportions -> square', () {
    final face = _buildFace(length: 110, cheekWidth: 100, foreheadWidth: 95, jawWidth: 95);
    expect(estimator.estimate(face), FaceShape.square);
  });

  test('medium-length face with even, wide proportions -> round', () {
    final face = _buildFace(length: 130, cheekWidth: 100, foreheadWidth: 95, jawWidth: 95);
    expect(estimator.estimate(face), FaceShape.round);
  });

  test('returns null when no face contour is available', () {
    final face = FaceAnalysis(
      boundingBox: const Rect.fromLTWH(0, 0, 100, _length),
      landmarks: const {},
      contours: const {},
      headEulerAngleX: 0,
      headEulerAngleY: 0,
      headEulerAngleZ: 0,
      imageSize: const Size(300, 300),
    );
    expect(estimator.estimate(face), isNull);
  });
}
