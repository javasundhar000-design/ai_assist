import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Draws a garment shape that actually tracks the detected body — this is
/// the real AR-fitting layer: given ML Kit's live pose landmarks, it maps
/// each shape's control points onto the wearer's actual shoulders, hips,
/// knees, wrists, etc., every frame.
///
/// There's no real garment photograph to texture-map (see the app's
/// placeholder-imagery note), so shapes are rendered as smooth, filled
/// silhouettes in the garment's color — the same honest trade-off as the
/// rest of the UI's `FashionImagePlaceholder`. Swap the path-building here
/// for a texture-mapped mesh once real garment cutouts exist; the landmark
/// tracking underneath is unchanged either way.
class PoseGarmentPainter extends CustomPainter {
  final Pose? pose;
  final Size imageSize; // size of the camera frame, already rotation-corrected
  final bool mirror; // true for front camera preview
  final Color garmentColor;
  final String category; // Tops, Bottoms, Shoes, Accessories
  final String itemName;

  PoseGarmentPainter({
    required this.pose,
    required this.imageSize,
    required this.mirror,
    required this.garmentColor,
    required this.category,
    required this.itemName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pose = this.pose;
    if (pose == null || imageSize.width == 0 || imageSize.height == 0) return;

    Offset? point(PoseLandmarkType type) {
      final lm = pose.landmarks[type];
      if (lm == null || lm.likelihood < 0.55) return null;
      final scaleX = size.width / imageSize.width;
      final scaleY = size.height / imageSize.height;
      final x = mirror ? size.width - (lm.x * scaleX) : lm.x * scaleX;
      return Offset(x, lm.y * scaleY);
    }

    switch (category) {
      case 'Tops':
        _paintTop(canvas, point);
        break;
      case 'Bottoms':
        _paintBottoms(canvas, point);
        break;
      case 'Shoes':
        _paintShoes(canvas, point);
        break;
      default:
        _paintAccessory(canvas, point);
    }
  }

  void _paintTop(Canvas canvas, Offset? Function(PoseLandmarkType) point) {
    final ls = point(PoseLandmarkType.leftShoulder);
    final rs = point(PoseLandmarkType.rightShoulder);
    final lh = point(PoseLandmarkType.leftHip);
    final rh = point(PoseLandmarkType.rightHip);
    final le = point(PoseLandmarkType.leftElbow);
    final re = point(PoseLandmarkType.rightElbow);
    if (ls == null || rs == null || lh == null || rh == null) return;

    final shoulderWidth = (rs - ls).distance;
    final collarDrop = shoulderWidth * 0.12;
    final sleeveL = le ?? Offset(ls.dx - shoulderWidth * 0.25, ls.dy + shoulderWidth * 0.4);
    final sleeveR = re ?? Offset(rs.dx + shoulderWidth * 0.25, rs.dy + shoulderWidth * 0.4);

    final path = Path()
      ..moveTo(ls.dx, ls.dy - collarDrop)
      ..lineTo(sleeveL.dx, sleeveL.dy)
      ..lineTo(ls.dx - shoulderWidth * 0.02, ls.dy + shoulderWidth * 0.15)
      ..lineTo(lh.dx, lh.dy)
      ..lineTo(rh.dx, rh.dy)
      ..lineTo(rs.dx + shoulderWidth * 0.02, rs.dy + shoulderWidth * 0.15)
      ..lineTo(sleeveR.dx, sleeveR.dy)
      ..lineTo(rs.dx, rs.dy - collarDrop)
      ..quadraticBezierTo((ls.dx + rs.dx) / 2, (ls.dy + rs.dy) / 2 + collarDrop * 1.4, ls.dx, ls.dy - collarDrop)
      ..close();

    _fillAndStroke(canvas, path);
  }

  void _paintBottoms(Canvas canvas, Offset? Function(PoseLandmarkType) point) {
    final lh = point(PoseLandmarkType.leftHip);
    final rh = point(PoseLandmarkType.rightHip);
    final lk = point(PoseLandmarkType.leftKnee);
    final rk = point(PoseLandmarkType.rightKnee);
    final la = point(PoseLandmarkType.leftAnkle);
    final ra = point(PoseLandmarkType.rightAnkle);
    if (lh == null || rh == null) return;

    final hipWidth = (rh - lh).distance;
    final legHalfWidth = hipWidth * 0.22;

    Path leg(Offset hip, Offset? knee, Offset? ankle, double dir) {
      final k = knee ?? Offset(hip.dx, hip.dy + hipWidth * 1.1);
      final a = ankle ?? Offset(k.dx, k.dy + hipWidth * 1.1);
      return Path()
        ..moveTo(hip.dx - legHalfWidth * dir, hip.dy)
        ..lineTo(hip.dx + legHalfWidth * dir, hip.dy)
        ..lineTo(k.dx + legHalfWidth * 0.8 * dir, k.dy)
        ..lineTo(a.dx + legHalfWidth * 0.6 * dir, a.dy)
        ..lineTo(a.dx - legHalfWidth * 0.6 * dir, a.dy)
        ..lineTo(k.dx - legHalfWidth * 0.8 * dir, k.dy)
        ..close();
    }

    _fillAndStroke(canvas, leg(lh, lk, la, -1));
    _fillAndStroke(canvas, leg(rh, rk, ra, 1));
  }

  void _paintShoes(Canvas canvas, Offset? Function(PoseLandmarkType) point) {
    for (final ankleType in [PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle]) {
      final a = point(ankleType);
      if (a == null) continue;
      canvas.drawOval(Rect.fromCenter(center: a, width: 34, height: 20), Paint()..color = garmentColor.withOpacity(0.9));
      canvas.drawOval(
        Rect.fromCenter(center: a, width: 34, height: 20),
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _paintAccessory(Canvas canvas, Offset? Function(PoseLandmarkType) point) {
    final name = itemName.toLowerCase();

    if (name.contains('sunglass') || name.contains('glass')) {
      final le = point(PoseLandmarkType.leftEye);
      final re = point(PoseLandmarkType.rightEye);
      if (le != null && re != null) {
        final mid = Offset((le.dx + re.dx) / 2, (le.dy + re.dy) / 2);
        final width = (re - le).distance * 2.6;
        final rect = Rect.fromCenter(center: mid, width: width, height: width * 0.32);
        _fillAndStroke(canvas, Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6))));
      }
      return;
    }

    Offset? anchor;
    double radius = 16;
    if (name.contains('watch')) {
      anchor = point(PoseLandmarkType.rightWrist) ?? point(PoseLandmarkType.leftWrist);
      radius = 10;
    } else {
      anchor = point(PoseLandmarkType.rightHip); // bags and anything else: hang near the hip
    }

    if (anchor == null) return;
    _fillAndStroke(canvas, Path()..addOval(Rect.fromCenter(center: anchor, width: radius * 2, height: radius * 2)));
  }

  void _fillAndStroke(Canvas canvas, Path path) {
    canvas.drawPath(path, Paint()..color = garmentColor.withOpacity(0.78));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant PoseGarmentPainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.garmentColor != garmentColor ||
        oldDelegate.category != category ||
        oldDelegate.itemName != itemName ||
        oldDelegate.mirror != mirror;
  }
}
