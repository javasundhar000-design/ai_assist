import 'dart:ui';

import 'package:aura_stylist_ai/features/gestures/domain/entities/gesture_type.dart';
import 'package:aura_stylist_ai/features/gestures/domain/services/pose_gesture_classifier.dart';
import 'package:aura_stylist_ai/features/vision/domain/entities/pose_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

const _imageSize = Size(400, 800);
final _baseTime = DateTime(2026, 1, 1, 12);

PoseAnalysis _poseWithWrists({
  double? rightX,
  double? rightY,
  double? leftX,
  double? leftY,
  double noseY = 200,
  double likelihood = 0.9,
}) {
  return PoseAnalysis(
    imageSize: _imageSize,
    landmarks: {
      if (rightX != null && rightY != null)
        PoseLandmarkKind.rightWrist:
            PoseKeypoint(x: rightX, y: rightY, z: 0, likelihood: likelihood),
      if (leftX != null && leftY != null)
        PoseLandmarkKind.leftWrist:
            PoseKeypoint(x: leftX, y: leftY, z: 0, likelihood: likelihood),
      PoseLandmarkKind.nose: PoseKeypoint(x: 200, y: noseY, z: 0, likelihood: likelihood),
    },
  );
}

void main() {
  group('PoseGestureClassifier - swipe detection', () {
    test('rightward raw motion + mirrorHorizontal=false -> swipeRight', () {
      final classifier = PoseGestureClassifier()..mirrorHorizontal = false;
      GestureType? detected;

      // Right wrist moving steadily rightward (x: 50 -> 250) over 200ms,
      // well within the 450ms window and past the 22% width (88px)
      // displacement threshold.
      for (var i = 0; i <= 4; i++) {
        final t = _baseTime.add(Duration(milliseconds: i * 50));
        final x = 50.0 + i * 50; // 50, 100, 150, 200, 250
        final event = classifier.classify(_poseWithWrists(rightX: x, rightY: 400), t);
        if (event != null) detected = event.type;
      }

      expect(detected, GestureType.swipeRight);
    });

    test('leftward raw motion + mirrorHorizontal=false -> swipeLeft', () {
      final classifier = PoseGestureClassifier()..mirrorHorizontal = false;
      GestureType? detected;

      for (var i = 0; i <= 4; i++) {
        final t = _baseTime.add(Duration(milliseconds: i * 50));
        final x = 250.0 - i * 50;
        final event = classifier.classify(_poseWithWrists(rightX: x, rightY: 400), t);
        if (event != null) detected = event.type;
      }

      expect(detected, GestureType.swipeLeft);
    });

    test('mirrorHorizontal=true flips the on-screen swipe direction', () {
      final classifier = PoseGestureClassifier()..mirrorHorizontal = true;
      GestureType? detected;

      // Raw motion is rightward (sensor space), but the mirrored front
      // camera preview shows this moving left on screen.
      for (var i = 0; i <= 4; i++) {
        final t = _baseTime.add(Duration(milliseconds: i * 50));
        final x = 50.0 + i * 50;
        final event = classifier.classify(_poseWithWrists(rightX: x, rightY: 400), t);
        if (event != null) detected = event.type;
      }

      expect(detected, GestureType.swipeLeft);
    });

    test('vertical drift disqualifies a swipe', () {
      final classifier = PoseGestureClassifier()..mirrorHorizontal = false;
      GestureType? detected;

      for (var i = 0; i <= 4; i++) {
        final t = _baseTime.add(Duration(milliseconds: i * 50));
        final x = 50.0 + i * 50;
        final y = 400.0 + i * 60; // too much vertical movement (300px total)
        final event = classifier.classify(_poseWithWrists(rightX: x, rightY: y), t);
        if (event != null) detected = event.type;
      }

      expect(detected, isNull);
    });

    test('small horizontal displacement below threshold does not swipe', () {
      final classifier = PoseGestureClassifier()..mirrorHorizontal = false;
      GestureType? detected;

      for (var i = 0; i <= 4; i++) {
        final t = _baseTime.add(Duration(milliseconds: i * 50));
        final x = 50.0 + i * 5; // only 20px total, well under 88px threshold
        final event = classifier.classify(_poseWithWrists(rightX: x, rightY: 400), t);
        if (event != null) detected = event.type;
      }

      expect(detected, isNull);
    });
  });

  group('PoseGestureClassifier - raised hand', () {
    test('wrist above nose held past raisedHoldDuration -> raisedRightHand', () {
      final classifier = PoseGestureClassifier(
        raisedHoldDuration: const Duration(milliseconds: 200),
      );
      GestureType? detected;

      for (var i = 0; i <= 6; i++) {
        final t = _baseTime.add(Duration(milliseconds: i * 50));
        // Right wrist above the nose (y=200) the whole time.
        final event = classifier.classify(
          _poseWithWrists(rightX: 200, rightY: 100, noseY: 200),
          t,
        );
        if (event != null) detected = event.type;
      }

      expect(detected, GestureType.raisedRightHand);
    });

    test('does not fire before the hold duration elapses', () {
      final classifier = PoseGestureClassifier(
        raisedHoldDuration: const Duration(milliseconds: 500),
      );

      // Only 100ms of holding — short of the 500ms requirement.
      GestureType? detected;
      for (var i = 0; i <= 2; i++) {
        final t = _baseTime.add(Duration(milliseconds: i * 50));
        final event = classifier.classify(
          _poseWithWrists(rightX: 200, rightY: 100, noseY: 200),
          t,
        );
        if (event != null) detected = event.type;
      }

      expect(detected, isNull);
    });

    test('both wrists held above nose -> bothHandsUp', () {
      final classifier = PoseGestureClassifier(
        raisedHoldDuration: const Duration(milliseconds: 200),
      );
      GestureType? detected;

      for (var i = 0; i <= 6; i++) {
        final t = _baseTime.add(Duration(milliseconds: i * 50));
        final event = classifier.classify(
          _poseWithWrists(
            rightX: 250,
            rightY: 100,
            leftX: 150,
            leftY: 100,
            noseY: 200,
          ),
          t,
        );
        if (event != null) detected = event.type;
      }

      expect(detected, GestureType.bothHandsUp);
    });

    test('low-confidence landmarks are ignored', () {
      final classifier = PoseGestureClassifier(
        raisedHoldDuration: const Duration(milliseconds: 100),
      );
      GestureType? detected;

      for (var i = 0; i <= 4; i++) {
        final t = _baseTime.add(Duration(milliseconds: i * 50));
        final event = classifier.classify(
          _poseWithWrists(rightX: 200, rightY: 100, noseY: 200, likelihood: 0.2),
          t,
        );
        if (event != null) detected = event.type;
      }

      expect(detected, isNull);
    });
  });

  group('PoseGestureClassifier - debounce', () {
    test('same gesture does not re-fire within the cooldown window', () {
      final classifier = PoseGestureClassifier(
        raisedHoldDuration: const Duration(milliseconds: 100),
        gestureCooldown: const Duration(milliseconds: 800),
      );

      var emitCount = 0;
      // Stay well under the 800ms cooldown boundary (first emission lands
      // at t=100ms; 100+800=900ms is when a second one would legitimately
      // become allowed) so this test isn't sensitive to an off-by-one at
      // the exact cooldown edge.
      for (var i = 0; i <= 15; i++) {
        final t = _baseTime.add(Duration(milliseconds: i * 50));
        final event = classifier.classify(
          _poseWithWrists(rightX: 200, rightY: 100, noseY: 200),
          t,
        );
        if (event != null) emitCount++;
      }

      // ~1000ms of continuous holding with an 800ms cooldown should only
      // emit once (the raised-hand state resets each hold cycle only when
      // the wrist actually drops, which never happens here).
      expect(emitCount, 1);
    });

    test('reset() clears temporal state so a new session starts fresh', () {
      final classifier = PoseGestureClassifier(
        raisedHoldDuration: const Duration(milliseconds: 100),
        gestureCooldown: const Duration(milliseconds: 800),
      );

      GestureType? first;
      for (var i = 0; i <= 4; i++) {
        final t = _baseTime.add(Duration(milliseconds: i * 50));
        final event = classifier.classify(
          _poseWithWrists(rightX: 200, rightY: 100, noseY: 200),
          t,
        );
        if (event != null) first = event.type;
      }
      expect(first, GestureType.raisedRightHand);

      classifier.reset();

      // Immediately after reset, holding again should still need to pass
      // the full hold duration again — reset must not leave any residual
      // "already raised since" timestamp behind.
      final immediateEvent = classifier.classify(
        _poseWithWrists(rightX: 200, rightY: 100, noseY: 200),
        _baseTime.add(const Duration(milliseconds: 300)),
      );
      expect(immediateEvent, isNull);
    });
  });
}
