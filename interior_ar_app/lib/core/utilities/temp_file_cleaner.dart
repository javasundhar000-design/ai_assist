import 'dart:io';

/// Section 29: "Do not store sensitive camera images unnecessarily."
/// Every vision screen captures a photo purely to run OCR/detection on
/// it — none of them need to keep the file afterward. Call this right
/// after you're done reading the result (text/labels extracted), not
/// before, since the ML Kit calls still need the file on disk.
class TempFileCleaner {
  TempFileCleaner._();

  static Future<void> deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort cleanup — a failed delete of a temp camera capture
      // is not worth surfacing to the user.
    }
  }
}
