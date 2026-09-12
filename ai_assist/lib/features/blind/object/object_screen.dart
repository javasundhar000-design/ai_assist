import '../../../models/permission.dart';
import '../vision_capture_screen.dart';

/// Spec §9: Object Recognition.
class ObjectRecognitionScreen extends VisionCaptureScreen {
  ObjectRecognitionScreen({super.key})
      : super(
          title: 'Recognize Object',
          description:
              'Capture what is in front of you. AI Assist will describe nearby objects and their approximate position.',
          permission: Permission.recognizeObject,
          loadingMessage: 'Analyzing image...',
          call: (service, bytes) => service.recognizeObject(bytes),
        );
}
