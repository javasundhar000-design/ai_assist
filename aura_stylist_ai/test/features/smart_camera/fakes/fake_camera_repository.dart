import 'package:aura_stylist_ai/core/errors/failure.dart';
import 'package:aura_stylist_ai/core/utils/result.dart';
import 'package:aura_stylist_ai/features/smart_camera/domain/entities/camera_frame.dart';
import 'package:aura_stylist_ai/features/smart_camera/domain/repositories/camera_repository.dart';


/// In-memory fake used for testing camera-orchestration logic (frame
/// stream start/stop, lens switching) without ever touching real camera
/// hardware or platform channels.
///
/// `controller` intentionally always returns `null` — nothing in the
/// controllers/state-machines under test needs a real `CameraController`
/// instance, and constructing one requires the platform channel that
/// isn't available outside a real device/emulator.
class FakeCameraRepository implements CameraRepository {
  bool initializeCalled = false;
  bool startFrameStreamCalled = false;
  bool stopFrameStreamCalled = false;
  bool switchLensCalled = false;
  bool disposeCalled = false;

  Failure? initializeFailure;
  Failure? startFrameStreamFailure;

  bool _isInitialized = false;

  @override
  CameraController? get controller => null;

  @override
  bool get isInitialized => _isInitialized;

  @override
  List<CameraDescription> get cameras => const [];

  /// Never emits by default — tests that only care about
  /// isStreaming/start-stop toggling don't need real frames, and
  /// constructing a real `CameraImage` requires the platform plugin.
  @override
  Stream<CameraFrame> get frameStream => const Stream.empty();

  @override
  Future<Result<void>> initialize({
    CameraLensDirection preferredLens = CameraLensDirection.front,
  }) async {
    initializeCalled = true;
    if (initializeFailure != null) return Err(initializeFailure!);
    _isInitialized = true;
    return const Success(null);
  }

  @override
  Future<Result<void>> startFrameStream() async {
    startFrameStreamCalled = true;
    if (startFrameStreamFailure != null) return Err(startFrameStreamFailure!);
    return const Success(null);
  }

  @override
  Future<Result<void>> stopFrameStream() async {
    stopFrameStreamCalled = true;
    return const Success(null);
  }

  @override
  Future<Result<void>> switchLens() async {
    switchLensCalled = true;
    return const Success(null);
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
    _isInitialized = false;
  }
}
