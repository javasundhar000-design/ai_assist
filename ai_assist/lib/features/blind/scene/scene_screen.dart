import '../../../models/permission.dart';
import '../vision_capture_screen.dart';

/// Spec §11: Scene Understanding.
class SceneUnderstandingScreen extends VisionCaptureScreen {
  SceneUnderstandingScreen({super.key})
      : super(
          title: 'Understand Surroundings',
          description:
              'Capture your surroundings. AI Assist will describe the environment, obstacles, and useful directional information.',
          permission: Permission.sceneUnderstanding,
          historyTaskType: 'scene',
          loadingMessage: 'Understanding scene...',
          call: (service, bytes) => service.understandScene(bytes),
        );
}
