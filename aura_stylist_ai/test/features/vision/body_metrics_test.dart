import 'dart:ui';

import 'package:aura_stylist_ai/features/vision/domain/entities/body_metrics.dart';
import 'package:aura_stylist_ai/features/vision/domain/entities/pose_analysis.dart';
import 'package:aura_stylist_ai/features/vision/domain/services/body_metrics_calculator.dart';
import 'package:aura_stylist_ai/features/vision/domain/services/body_type_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

PoseAnalysis _buildPose({
  required double shoulderWidth,
  required double hipWidth,
  required double torsoHeight,
  double shoulderZDiff = 0,
  double likelihood = 0.9,
}) {
  const centerX = 100.0;
  const shoulderY = 50.0;
  final hipY = shoulderY + torsoHeight;

  return PoseAnalysis(
    imageSize: const Size(300, 400),
    landmarks: {
      PoseLandmarkKind.leftShoulder: PoseKeypoint(
        x: centerX - shoulderWidth / 2,
        y: shoulderY,
        z: shoulderZDiff / 2,
        likelihood: likelihood,
      ),
      PoseLandmarkKind.rightShoulder: PoseKeypoint(
        x: centerX + shoulderWidth / 2,
        y: shoulderY,
        z: -shoulderZDiff / 2,
        likelihood: likelihood,
      ),
      PoseLandmarkKind.leftHip: PoseKeypoint(
        x: centerX - hipWidth / 2,
        y: hipY,
        z: 0,
        likelihood: likelihood,
      ),
      PoseLandmarkKind.rightHip: PoseKeypoint(
        x: centerX + hipWidth / 2,
        y: hipY,
        z: 0,
        likelihood: likelihood,
      ),
    },
  );
}

void main() {
  group('BodyMetricsCalculator', () {
    const calculator = BodyMetricsCalculator();

    test('computes shoulder width, hip width, torso height, and ratio', () {
      final pose = _buildPose(shoulderWidth: 120, hipWidth: 100, torsoHeight: 150);
      final metrics = calculator.calculate(pose);

      expect(metrics, isNotNull);
      expect(metrics!.shoulderWidth, closeTo(120, 0.01));
      expect(metrics.hipWidth, closeTo(100, 0.01));
      expect(metrics.torsoHeight, closeTo(150, 0.01));
      expect(metrics.shoulderToHipRatio, closeTo(1.2, 0.01));
    });

    test('facingCamera when shoulders have near-zero z asymmetry', () {
      final pose = _buildPose(
        shoulderWidth: 100,
        hipWidth: 100,
        torsoHeight: 100,
        shoulderZDiff: 0,
      );
      final metrics = calculator.calculate(pose);
      expect(metrics!.orientation, BodyOrientation.facingCamera);
    });

    test('turnedRight/turnedLeft when shoulders have z asymmetry', () {
      final turnedRight = calculator.calculate(
        _buildPose(shoulderWidth: 100, hipWidth: 100, torsoHeight: 100, shoulderZDiff: 1.0),
      );
      final turnedLeft = calculator.calculate(
        _buildPose(shoulderWidth: 100, hipWidth: 100, torsoHeight: 100, shoulderZDiff: -1.0),
      );

      expect(turnedRight!.orientation, BodyOrientation.turnedRight);
      expect(turnedLeft!.orientation, BodyOrientation.turnedLeft);
    });

    test('returns null when a required landmark has low confidence', () {
      final pose = _buildPose(
        shoulderWidth: 100,
        hipWidth: 100,
        torsoHeight: 100,
        likelihood: 0.2,
      );
      expect(calculator.calculate(pose), isNull);
    });

    test('returns null when a required landmark is missing entirely', () {
      const pose = PoseAnalysis(landmarks: {}, imageSize: Size(300, 400));
      expect(calculator.calculate(pose), isNull);
    });
  });

  group('BodyTypeEstimator', () {
    const estimator = BodyTypeEstimator();

    BodyMetrics metricsWithRatio(double ratio) => BodyMetrics(
          shoulderWidth: ratio * 100,
          hipWidth: 100,
          torsoHeight: 150,
          shoulderToHipRatio: ratio,
          bodyRotationDegrees: 0,
          orientation: BodyOrientation.facingCamera,
        );

    test('high shoulder-to-hip ratio -> athletic', () {
      expect(estimator.estimate(metricsWithRatio(1.3)), BodyType.athletic);
    });

    test('moderately shoulder-dominant -> average', () {
      expect(estimator.estimate(metricsWithRatio(1.1)), BodyType.average);
    });

    test('roughly even ratio -> slim', () {
      expect(estimator.estimate(metricsWithRatio(0.95)), BodyType.slim);
    });

    test('hip-dominant ratio -> broad', () {
      expect(estimator.estimate(metricsWithRatio(0.7)), BodyType.broad);
    });

    test('zero ratio returns null (unmeasurable)', () {
      expect(estimator.estimate(metricsWithRatio(0)), isNull);
    });
  });
}
