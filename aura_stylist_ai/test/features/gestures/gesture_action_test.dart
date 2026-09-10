import 'package:aura_stylist_ai/features/gestures/domain/entities/gesture_action.dart';
import 'package:aura_stylist_ai/features/gestures/domain/entities/gesture_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GestureType.isImplemented', () {
    test('the five pose-derivable gestures are implemented', () {
      expect(GestureType.swipeLeft.isImplemented, isTrue);
      expect(GestureType.swipeRight.isImplemented, isTrue);
      expect(GestureType.raisedRightHand.isImplemented, isTrue);
      expect(GestureType.raisedLeftHand.isImplemented, isTrue);
      expect(GestureType.bothHandsUp.isImplemented, isTrue);
    });

    test('the five hand-shape gestures are honestly marked unimplemented', () {
      expect(GestureType.openPalm.isImplemented, isFalse);
      expect(GestureType.closedFist.isImplemented, isFalse);
      expect(GestureType.thumbsUp.isImplemented, isFalse);
      expect(GestureType.thumbsDown.isImplemented, isFalse);
      expect(GestureType.peaceSign.isImplemented, isFalse);
    });
  });

  group('gestureActionMap', () {
    test('matches the spec\'s gesture -> action assignments', () {
      expect(gestureActionMap[GestureType.swipeLeft], GestureAction.previousOutfit);
      expect(gestureActionMap[GestureType.swipeRight], GestureAction.nextOutfit);
      expect(gestureActionMap[GestureType.thumbsUp], GestureAction.saveFavorite);
      expect(gestureActionMap[GestureType.peaceSign], GestureAction.capturePhoto);
      expect(gestureActionMap[GestureType.openPalm], GestureAction.openMenu);
      expect(gestureActionMap[GestureType.closedFist], GestureAction.closeMenu);
      expect(gestureActionMap[GestureType.raisedRightHand], GestureAction.startVoiceMode);
      expect(gestureActionMap[GestureType.raisedLeftHand], GestureAction.stopVoiceMode);
      expect(gestureActionMap[GestureType.bothHandsUp], GestureAction.resetTryOn);
    });

    test('thumbsDown has no assigned action, matching the spec', () {
      expect(gestureActionMap.containsKey(GestureType.thumbsDown), isFalse);
      expect(GestureType.thumbsDown.action, isNull);
    });

    test('every implemented gesture resolves to a non-null action', () {
      for (final type in GestureType.values.where((t) => t.isImplemented)) {
        expect(type.action, isNotNull, reason: '$type should have a mapped action');
      }
    });
  });

  group('GestureAction.isImplemented', () {
    test('startVoiceMode/stopVoiceMode are real now that Module 7 exists', () {
      expect(GestureAction.startVoiceMode.isImplemented, isTrue);
      expect(GestureAction.stopVoiceMode.isImplemented, isTrue);
      expect(GestureAction.startVoiceMode.owningModule, isNull);
      expect(GestureAction.stopVoiceMode.owningModule, isNull);
    });

    test('resetTryOn/openMenu/closeMenu are real now that Module 8 exists', () {
      expect(GestureAction.resetTryOn.isImplemented, isTrue);
      expect(GestureAction.openMenu.isImplemented, isTrue);
      expect(GestureAction.closeMenu.isImplemented, isTrue);
      expect(GestureAction.resetTryOn.owningModule, isNull);
      expect(GestureAction.openMenu.owningModule, isNull);
      expect(GestureAction.closeMenu.owningModule, isNull);
    });

    test('previousOutfit/nextOutfit/saveFavorite are real now that Module 10 exists', () {
      expect(GestureAction.previousOutfit.isImplemented, isTrue);
      expect(GestureAction.nextOutfit.isImplemented, isTrue);
      expect(GestureAction.saveFavorite.isImplemented, isTrue);
      expect(GestureAction.previousOutfit.owningModule, isNull);
      expect(GestureAction.nextOutfit.owningModule, isNull);
      expect(GestureAction.saveFavorite.owningModule, isNull);
    });

    test('capturePhoto still points to its owning (unbuilt) module', () {
      expect(GestureAction.capturePhoto.isImplemented, isFalse);
      expect(GestureAction.capturePhoto.owningModule, isNotNull);
    });
  });
}
