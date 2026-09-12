import '../../../models/permission.dart';
import '../vision_capture_screen.dart';

/// Spec §7: Read Book / Document.
class ReadDocumentScreen extends VisionCaptureScreen {
  ReadDocumentScreen({super.key})
      : super(
          title: 'Read Book / Document',
          description:
              'Point your camera at a page, label, or sign. AI Assist will read the text aloud.',
          permission: Permission.readDocument,
          loadingMessage: 'Reading text...',
          call: (service, bytes) => service.extractText(bytes),
        );
}
