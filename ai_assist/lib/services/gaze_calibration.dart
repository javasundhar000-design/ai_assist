import 'dart:convert';
import 'dart:ui' show Offset;
import 'package:shared_preferences/shared_preferences.dart';
import 'gaze_tracking_service.dart';

/// The result of running EyeCalibrationScreen: your own personal head-angle
/// extremes for "look left" / "look right" / "look up" / "look down",
/// captured relative to your own neutral center position.
///
/// This is what makes head-pose tracking usable per-person: everyone's
/// neutral head position and range of motion is different, so a fixed
/// angle threshold would work for nobody. Calibrating against your own
/// extremes and linearly mapping between them is what
/// [normalize] does.
class GazeCalibrationData {
  final double yawLeft;
  final double yawCenter;
  final double yawRight;
  final double pitchUp;
  final double pitchCenter;
  final double pitchDown;

  const GazeCalibrationData({
    required this.yawLeft,
    required this.yawCenter,
    required this.yawRight,
    required this.pitchUp,
    required this.pitchCenter,
    required this.pitchDown,
  });

  /// Maps a live HeadPose reading to a normalized (0..1, 0..1) position
  /// within whatever gaze-controlled area is currently on screen — (0,0) is
  /// top-left ("look up and left"), (1,1) is bottom-right ("look down and
  /// right"). Values are clamped, so looking further than your calibrated
  /// extreme just pins the cursor at the edge rather than moving it
  /// off-screen.
  ///
  /// Note this reuses the same normalized space for both the calibration
  /// screen and the eye keyboard's grid — each screen maps (0..1, 0..1)
  /// onto its own visible area, rather than this class knowing about
  /// absolute screen pixels.
  Offset normalize(HeadPose pose) {
    final spanX = yawRight - yawLeft;
    final spanY = pitchDown - pitchUp;
    final nx = spanX == 0 ? 0.5 : ((pose.yawDegrees - yawLeft) / spanX).clamp(0.0, 1.0);
    final ny = spanY == 0 ? 0.5 : ((pose.pitchDegrees - pitchUp) / spanY).clamp(0.0, 1.0);
    return Offset(nx, ny);
  }

  Map<String, dynamic> toJson() => {
        'yawLeft': yawLeft,
        'yawCenter': yawCenter,
        'yawRight': yawRight,
        'pitchUp': pitchUp,
        'pitchCenter': pitchCenter,
        'pitchDown': pitchDown,
      };

  factory GazeCalibrationData.fromJson(Map<String, dynamic> json) => GazeCalibrationData(
        yawLeft: (json['yawLeft'] as num).toDouble(),
        yawCenter: (json['yawCenter'] as num).toDouble(),
        yawRight: (json['yawRight'] as num).toDouble(),
        pitchUp: (json['pitchUp'] as num).toDouble(),
        pitchCenter: (json['pitchCenter'] as num).toDouble(),
        pitchDown: (json['pitchDown'] as num).toDouble(),
      );
}

/// Persists calibration on-device (SharedPreferences — this data isn't
/// sensitive, unlike the OpenRouter key, so it doesn't need secure storage).
class GazeCalibrationStore {
  static const _key = 'ai_assist_gaze_calibration_v1';

  Future<void> save(GazeCalibrationData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }

  Future<GazeCalibrationData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return GazeCalibrationData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
