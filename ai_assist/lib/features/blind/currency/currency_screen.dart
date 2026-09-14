import '../../../models/permission.dart';
import '../vision_capture_screen.dart';

/// Spec §10: Currency Recognition. Never guesses — low-confidence responses
/// surface "I cannot confidently identify the currency." via the shared
/// low-confidence notice.
class CurrencyRecognitionScreen extends VisionCaptureScreen {
  CurrencyRecognitionScreen({super.key})
      : super(
          title: 'Recognize Currency',
          description: 'Capture a currency note or coin to identify it.',
          permission: Permission.recognizeCurrency,
          historyTaskType: 'currency',
          loadingMessage: 'Identifying currency...',
          lowConfidenceNotice: 'I cannot confidently identify the currency.',
          call: (service, bytes) => service.recognizeCurrency(bytes),
        );
}
