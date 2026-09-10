import 'dart:ui';

import 'package:aura_stylist_ai/features/tryon/domain/services/body_anchor_calculator.dart';
import 'package:aura_stylist_ai/features/vision/domain/entities/pose_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

PoseAnalysis _buildPose({
  double leftShoulderX = 60,
  double rightShoulderX = 140,
  double shoulderY = 100,
  double leftHipX = 70,
  double rightHipX = 130,
  double hipY = 300,
  double? noseX,
  double? noseY,
  double likelihood = 0.9,
  bool includeAnkles = false,
}) {
  final landmarks = <PoseLandmarkKind, PoseKeypoint>{
    PoseLandmarkKind.leftShoulder:
        PoseKeypoint(x: leftShoulderX, y: shoulderY, z: 0, likelihood: likelihood),
    PoseLandmarkKind.rightShoulder:
        PoseKeypoint(x: rightShoulderX, y: shoulderY, z: 0, likelihood: likelihood),
    PoseLandmarkKind.leftHip: PoseKeypoint(x: leftHipX, y: hipY, z: 0, likelihood: likelihood),
    PoseLandmarkKind.rightHip: PoseKeypoint(x: rightHipX, y: hipY, z: 0, likelihood: likelihood),
  };
  if (noseX != null && noseY != null) {
    landmarks[PoseLandmarkKind.nose] =
        PoseKeypoint(x: noseX, y: noseY, z: 0, likelihood: likelihood);
  }
  if (includeAnkles) {
    landmarks[PoseLandmarkKind.leftAnkle] =
        PoseKeypoint(x: 75, y: 550, z: 0, likelihood: likelihood);
    landmarks[PoseLandmarkKind.rightAnkle] =
        PoseKeypoint(x: 125, y: 550, z: 0, likelihood: likelihood);
  }
  return PoseAnalysis(landmarks: landmarks, imageSize: const Size(200, 600));
}

void main() {
  const calculator = BodyAnchorCalculator();

  test('computes shoulder/hip midpoints and widths correctly', () {
    final anchors = calculator.calculate(_buildPose());

    expect(anchors, isNotNull);
    expect(anchors!.shoulderWidth, closeTo(80, 0.01)); // 140-60
    expect(anchors.hipWidth, closeTo(60, 0.01)); // 130-70
    expect(anchors.hipCenter, const Offset(100, 300));
    expect(anchors.torsoHeight, closeTo(200, 0.01)); // 300-100
  });

  test('chestCenter sits between shoulders and hips, closer to shoulders', () {
    final anchors = calculator.calculate(_buildPose())!;
    // shoulderMid = (100,100), hipMid = (100,300); chest at 22% toward hip.
    expect(anchors.chestCenter.dy, closeTo(100 + 200 * 0.22, 0.01));
  });

  test('waist sits closer to hips than chestCenter does', () {
    final anchors = calculator.calculate(_buildPose())!;
    expect(anchors.waist.dy, greaterThan(anchors.chestCenter.dy));
    expect(anchors.waist.dy, lessThan(anchors.hipCenter.dy));
  });

  test('neck extrapolates toward the nose when visible', () {
    final withNose = calculator.calculate(_buildPose(noseX: 100, noseY: 40))!;
    final withoutNose = calculator.calculate(_buildPose())!;

    // With a nose well above the shoulders, the neck should end up at
    // least as high (smaller y) as the no-nose fallback estimate.
    expect(withNose.neck.dy, lessThanOrEqualTo(withoutNose.neck.dy));
  });

  test('bodyRotationRadians is ~0 for level shoulders', () {
    final anchors = calculator.calculate(_buildPose())!;
    expect(anchors.bodyRotationRadians.abs(), lessThan(0.01));
  });

  test('bodyRotationRadians is nonzero when shoulders are tilted', () {
    final tilted = const PoseAnalysis(
      imageSize: Size(200, 600),
      landmarks: {
        PoseLandmarkKind.leftShoulder: PoseKeypoint(x: 60, y: 80, z: 0, likelihood: 0.9),
        PoseLandmarkKind.rightShoulder: PoseKeypoint(x: 140, y: 120, z: 0, likelihood: 0.9),
        PoseLandmarkKind.leftHip: PoseKeypoint(x: 70, y: 300, z: 0, likelihood: 0.9),
        PoseLandmarkKind.rightHip: PoseKeypoint(x: 130, y: 300, z: 0, likelihood: 0.9),
      },
    );
    final tiltedAnchors = calculator.calculate(tilted);
    expect(tiltedAnchors, isNotNull);
    expect(tiltedAnchors!.bodyRotationRadians.abs(), greaterThan(0.01));
  });

  test('returns null when a required landmark has low confidence', () {
    final anchors = calculator.calculate(_buildPose(likelihood: 0.2));
    expect(anchors, isNull);
  });

  test('returns null when a required landmark is missing entirely', () {
    const pose = PoseAnalysis(landmarks: {}, imageSize: Size(200, 600));
    expect(calculator.calculate(pose), isNull);
  });

  test('ankles are included when visible, null when not', () {
    final withAnkles = calculator.calculate(_buildPose(includeAnkles: true))!;
    expect(withAnkles.leftAnkle, isNotNull);
    expect(withAnkles.rightAnkle, isNotNull);

    final withoutAnkles = calculator.calculate(_buildPose())!;
    expect(withoutAnkles.leftAnkle, isNull);
    expect(withoutAnkles.rightAnkle, isNull);
  });
}
