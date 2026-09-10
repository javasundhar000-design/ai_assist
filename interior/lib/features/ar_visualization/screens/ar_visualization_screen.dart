import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../app/constants/app_constants.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../design_history/providers/design_provider.dart';
import '../../room_analysis/providers/room_analysis_provider.dart';
import '../providers/ar_visualization_provider.dart';
import '../widgets/furniture_picker_sheet.dart';
import '../widgets/selected_furniture_toolbar.dart';
import '../widgets/space_validation_badge.dart';

class ArVisualizationScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String roomId;
  const ArVisualizationScreen(
      {super.key, required this.projectId, required this.roomId});

  @override
  ConsumerState<ArVisualizationScreen> createState() =>
      _ArVisualizationScreenState();
}

enum _PermissionState { checking, granted, denied }

class _ArVisualizationScreenState extends ConsumerState<ArVisualizationScreen> {
  _PermissionState _permission = _PermissionState.checking;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _consumeEditHandoff();
  }

  /// If Design History's "Continue in AR" / Edit sent furniture items
  /// over via [designEditHandoffProvider], queue them for re-placement.
  /// See the doc comment on ArVisualizationController.startEditQueue for
  /// why positions aren't restored automatically.
  void _consumeEditHandoff() {
    final handoff = ref.read(designEditHandoffProvider);
    if (handoff != null) {
      ref
          .read(arVisualizationControllerProvider.notifier)
          .startEditQueue(handoff.designName, handoff.items);
      ref.read(designEditHandoffProvider.notifier).state = null;
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _permission = status.isGranted
          ? _PermissionState.granted
          : _PermissionState.denied;
    });
  }

  Future<void> _saveDesign() async {
    final state = ref.read(arVisualizationControllerProvider);
    if (state.placed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Place at least one item first.')),
      );
      return;
    }
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _SaveDesignDialog(),
    );
    if (name == null || name.trim().isEmpty) return;

    setState(() => _saving = true);
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;
      final repo = ref.read(designRepositoryProvider);
      // Style isn't tracked within this screen's own state — the style
      // chosen back in Phase 10's Recommendations screen doesn't persist
      // across this navigation gap (that provider is autoDispose,
      // correctly scoped to that screen's own lifecycle). Defaulting to
      // "contemporary" here is a reasonable placeholder; wiring the
      // actual chosen style through end-to-end is a natural follow-up
      // once Design History (Phase 14) needs to filter/display by style.
      await repo.saveDesign(
        userId: user.uid,
        projectId: widget.projectId,
        roomId: widget.roomId,
        name: name.trim(),
        style: InteriorStyle.contemporary,
        furniture:
            state.placed.map((p) => p.toDesignFurnitureInstance()).toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Design saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not save the design. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(arVisualizationControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        ref.read(arVisualizationControllerProvider.notifier).dismissError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Visualization'),
        actions: [
          IconButton(
            tooltip: 'Save Design',
            icon: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            onPressed: _saving ? null : _saveDesign,
          ),
        ],
      ),
      body: switch (_permission) {
        _PermissionState.checking => const AppLoadingView(),
        _PermissionState.denied => AppErrorView(
            message:
                'Camera permission is required for AR. Enable it in Settings.',
            onRetry: openAppSettings,
          ),
        _PermissionState.granted => _ArContent(roomId: widget.roomId),
      },
    );
  }
}

class _ArContent extends ConsumerWidget {
  final String roomId;
  const _ArContent({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(arVisualizationControllerProvider);
    final controller = ref.read(arVisualizationControllerProvider.notifier);

    // Feed Phase 8's room/detected-object data into the AR controller
    // as soon as it's available, so Space Validation (Phase 13) has
    // real room dimensions to check against. fireImmediately covers the
    // case where the data is already cached by the time this screen
    // opens (e.g. the user just came from Room Analysis).
    ref.listen(roomStreamProvider(roomId), (prev, next) {
      final room = next.valueOrNull;
      if (room != null) controller.setRoomContext(room);
    }, fireImmediately: true);
    ref.listen(detectedObjectsStreamProvider(roomId), (prev, next) {
      final objects = next.valueOrNull;
      if (objects != null) controller.setDetectedObjects(objects);
    }, fireImmediately: true);

    return Stack(
      children: [
        ARView(
          onARViewCreated: (sessionManager, objectManager, anchorManager,
                  locationManager) =>
              controller.onViewCreated(
            sessionManager: sessionManager,
            objectManager: objectManager,
            anchorManager: anchorManager,
            locationManager: locationManager,
          ),
          planeDetectionConfig: PlaneDetectionConfig.horizontal,
        ),
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: _InstructionBanner(
            hasPending: state.pendingFurniture != null,
            pendingName: state.pendingFurniture?.name,
            hasPlaced: state.placed.isNotEmpty,
            sessionReady: state.sessionReady,
            editingDesignName: state.editingDesignName,
            editQueueRemaining: state.editQueueRemaining,
            editQueueTotal: state.editQueue.length,
          ),
        ),
        Positioned(
          top: 64,
          right: 16,
          child: SpaceValidationBadge(issues: state.issues),
        ),
        if (state.selected != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SelectedFurnitureToolbar(
              selected: state.selected!,
              onRotateLeft: () => controller.rotateSelected(-15),
              onRotateRight: () => controller.rotateSelected(15),
              onScaleUp: () => controller.scaleSelected(1.1),
              onScaleDown: () => controller.scaleSelected(0.9),
              onReplace: () async {
                final newItem = await showFurniturePickerSheet(context);
                if (newItem != null) {
                  await controller.replaceSelected(newItem);
                }
              },
              onDelete: () => controller.deleteSelected(),
              onDismiss: () => controller.select(null),
            ),
          )
        else
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () async {
                final item = await showFurniturePickerSheet(context);
                if (item != null) {
                  controller.setPendingFurniture(item);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Furniture'),
            ),
          ),
      ],
    );
  }
}

class _InstructionBanner extends StatelessWidget {
  final bool hasPending;
  final String? pendingName;
  final bool hasPlaced;
  final bool sessionReady;
  final String? editingDesignName;
  final int editQueueRemaining;
  final int editQueueTotal;

  const _InstructionBanner({
    required this.hasPending,
    required this.pendingName,
    required this.hasPlaced,
    required this.sessionReady,
    this.editingDesignName,
    this.editQueueRemaining = 0,
    this.editQueueTotal = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (!sessionReady) return const SizedBox.shrink();

    final isEditing = editingDesignName != null && editQueueRemaining > 0;

    final String text;
    if (isEditing && hasPending) {
      final placedSoFar = editQueueTotal - editQueueRemaining + 1;
      text = 'Editing "$editingDesignName" — tap a surface to place '
          '$pendingName ($placedSoFar of $editQueueTotal). Note: this '
          'places the same items again — their exact old positions '
          'aren\'t restored (see Design Details for why).';
    } else if (hasPending) {
      text = 'Move your phone to detect a surface, then tap it to place '
          '$pendingName.';
    } else if (!hasPlaced) {
      text = 'Move your phone slowly to detect the floor, then tap '
          '"Add Furniture" to get started.';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SaveDesignDialog extends StatefulWidget {
  const _SaveDesignDialog();

  @override
  State<_SaveDesignDialog> createState() => _SaveDesignDialogState();
}

class _SaveDesignDialogState extends State<_SaveDesignDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Design'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Design name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
