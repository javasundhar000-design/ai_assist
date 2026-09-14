import '../../../models/permission.dart';
import '../vision_capture_screen.dart';

/// Spec §8: Medicine Recognition. Never invents missing fields — the
/// generic result view already renders "Information could not be clearly
/// read." for any null field.
class MedicineScreen extends VisionCaptureScreen {
  MedicineScreen({super.key})
      : super(
          title: 'Read Medicine',
          description:
              'Capture the medicine package. AI Assist will read the name, strength, expiry, and manufacturer if clearly visible.',
          permission: Permission.readMedicine,
          historyTaskType: 'medicine',
          loadingMessage: 'Recognizing medicine...',
          lowConfidenceNotice: 'Some information could not be clearly read.',
          call: (service, bytes) => service.recognizeMedicine(bytes),
        );
}
