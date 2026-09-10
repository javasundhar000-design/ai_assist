import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the images captured during one scan session in memory (as
/// XFile — local temp-file references from the camera plugin). Cleared
/// once the scan is confirmed & uploaded, or if the user backs out of
/// the flow entirely.
class ScanSessionController extends StateNotifier<List<XFile>> {
  ScanSessionController() : super(const []);

  void addImage(XFile file) => state = [...state, file];

  void removeAt(int index) {
    final updated = [...state]..removeAt(index);
    state = updated;
  }

  void clear() => state = const [];
}

/// autoDispose: if the user leaves the whole scan flow (pops back to
/// project details) the captured images are released rather than lingering
/// in memory indefinitely.
final scanSessionProvider =
    StateNotifierProvider.autoDispose<ScanSessionController, List<XFile>>(
  (ref) => ScanSessionController(),
);
