import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../firebase/storage/storage_service.dart';
import '../../../models/project_model.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../room_analysis/providers/room_analysis_provider.dart';
import '../../room_analysis/repositories/room_analysis_repository.dart';
import '../../room_analysis/services/room_dimension_estimator.dart';
import '../../room_analysis/services/room_vision_service.dart';
import '../repositories/room_scan_repository.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final roomScanRepositoryProvider = Provider<RoomScanRepository>((ref) {
  return RoomScanRepository(
    db: ref.watch(realtimeDatabaseServiceProvider),
    storage: ref.watch(storageServiceProvider),
  );
});

/// Which stage of "Confirm Scan -> Analyze Room" (Sec. 9 flow) is active.
enum ScanStage { idle, uploading, analyzing, done }

class ScanUploadState {
  final ScanStage stage;
  final double progress; // 0.0-1.0 within the current stage
  final String? error; // may accompany a completed room (non-fatal)
  final String? completedRoomId;

  const ScanUploadState({
    this.stage = ScanStage.idle,
    this.progress = 0,
    this.error,
    this.completedRoomId,
  });

  bool get isUploading => stage == ScanStage.uploading;
  bool get isAnalyzing => stage == ScanStage.analyzing;
  bool get isBusy => isUploading || isAnalyzing;

  ScanUploadState copyWith({
    ScanStage? stage,
    double? progress,
    String? error,
    String? completedRoomId,
  }) {
    return ScanUploadState(
      stage: stage ?? this.stage,
      progress: progress ?? this.progress,
      error: error,
      completedRoomId: completedRoomId ?? this.completedRoomId,
    );
  }
}

class ScanUploadController extends StateNotifier<ScanUploadState> {
  final RoomScanRepository _scanRepo;
  final RoomAnalysisRepository _analysisRepo;
  final RoomVisionService _visionService;

  ScanUploadController(
    this._scanRepo,
    this._analysisRepo,
    this._visionService,
  ) : super(const ScanUploadState());

  Future<void> confirmScan({
    required ProjectModel project,
    required List<XFile> images,
  }) async {
    if (images.isEmpty) {
      state = state.copyWith(
          error: 'Capture at least one photo before confirming.');
      return;
    }

    // --- Stage 1: upload (Phase 7) ---
    state = const ScanUploadState(stage: ScanStage.uploading, progress: 0);
    String roomId;
    try {
      roomId = await _scanRepo.confirmScan(
        project: project,
        images: images,
        onProgress: (p) => state = state.copyWith(progress: p),
      );
    } on AppException catch (e) {
      state = ScanUploadState(stage: ScanStage.idle, error: e.message);
      return;
    } catch (e) {
      state = const ScanUploadState(
        stage: ScanStage.idle,
        error:
            'Scan upload failed. Please check your connection and try again.',
      );
      return;
    }

    // --- Stage 2: on-device analysis (Phase 8) ---
    // A failure here is treated as non-fatal: the photos and room are
    // already safely saved, so the user can still open the room and
    // proceed manually rather than losing their scan entirely
    // (Sec. 29: never let a failure destroy prior work).
    state = state.copyWith(stage: ScanStage.analyzing, progress: 0);
    try {
      final detections = await _visionService.analyzeImages(
        images.map((x) => File(x.path)).toList(),
        onProgress: (p) => state = state.copyWith(progress: p),
      );
      await _analysisRepo.saveDetectedObjects(roomId, detections);
      final dims = RoomDimensionEstimator.estimate(project.roomType);
      await _analysisRepo.updateRoomDimensions(roomId, dims);
      state = ScanUploadState(
        stage: ScanStage.done,
        progress: 1,
        completedRoomId: roomId,
      );
    } catch (e) {
      state = ScanUploadState(
        stage: ScanStage.done,
        completedRoomId: roomId,
        error:
            'Photos were saved, but automatic object detection could not '
            'complete. You can still view the room and continue.',
      );
    }
  }

  void reset() => state = const ScanUploadState();
}

final scanUploadControllerProvider =
    StateNotifierProvider.autoDispose<ScanUploadController, ScanUploadState>(
  (ref) => ScanUploadController(
    ref.watch(roomScanRepositoryProvider),
    ref.watch(roomAnalysisRepositoryProvider),
    ref.watch(roomVisionServiceProvider),
  ),
);
