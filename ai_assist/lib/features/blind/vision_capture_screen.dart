import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../models/permission.dart';
import '../../services/ai_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/permission_guard.dart';

typedef VisionCall = Future<VisionResult> Function(AiService service, Uint8List imageBytes);

/// One shared flow implements Read Document (§7), Medicine (§8), Object
/// (§9), Currency (§10), and Scene Understanding (§11): all five are
/// structurally identical — capture image -> send to backend -> vision
/// model -> display result -> optional TTS. Only the copy, permission, and
/// which AiService method is called differ per role feature.
class VisionCaptureScreen extends ConsumerStatefulWidget {
  final String title;
  final String description;
  final Permission permission;
  final String loadingMessage;
  final String lowConfidenceNotice;
  final VisionCall call;

  const VisionCaptureScreen({
    super.key,
    required this.title,
    required this.description,
    required this.permission,
    required this.call,
    this.loadingMessage = 'Analyzing image...',
    this.lowConfidenceNotice = 'Some text could not be clearly recognized.',
  });

  @override
  ConsumerState<VisionCaptureScreen> createState() => _VisionCaptureScreenState();
}

enum _Stage { capture, loading, result, error }

class _VisionCaptureScreenState extends ConsumerState<VisionCaptureScreen> {
  _Stage _stage = _Stage.capture;
  VisionResult? _result;
  String _errorMessage = '';
  bool _isSpeaking = false;

  Future<void> _pick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      setState(() => _stage = _Stage.loading);
      final bytes = await File(file.path).readAsBytes();
      final aiService = ref.read(aiServiceProvider);
      final result = await widget.call(aiService, bytes);
      if (!mounted) return;
      setState(() {
        _result = result;
        _stage = _Stage.result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Image could not be processed.';
        _stage = _Stage.error;
      });
    }
  }

  Future<void> _speak(String text) async {
    final tts = ref.read(ttsServiceProvider);
    setState(() => _isSpeaking = true);
    await tts.speak(text);
  }

  void _reset() => setState(() {
        _stage = _Stage.capture;
        _result = null;
        _isSpeaking = false;
      });

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      required: widget.permission,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _Stage.capture:
        return _buildCapture();
      case _Stage.loading:
        return LoadingView(message: widget.loadingMessage);
      case _Stage.error:
        return ErrorView(message: _errorMessage, onRetry: _reset);
      case _Stage.result:
        return _buildResult();
    }
  }

  Widget _buildCapture() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.description, style: Theme.of(context).textTheme.bodyLarge),
        const Spacer(),
        const Icon(Icons.center_focus_strong_rounded, size: 96, color: AppColors.primary),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton.icon(
          onPressed: () => _pick(ImageSource.camera),
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Open Camera'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _pick(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Choose from Gallery'),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildResult() {
    final result = _result!;
    return ListView(
      children: [
        if (result.confidenceIsLow)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(widget.lowConfidenceNotice)),
              ],
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Result', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                SelectableText(
                  result.summary,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
                ),
                if (result.fields.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  for (final entry in result.fields.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 130,
                            child: Text(entry.key,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            child: Text(entry.value ??
                                'Information could not be clearly read.'),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _speak(result.summary),
                icon: Icon(_isSpeaking ? Icons.volume_up_rounded : Icons.play_arrow_rounded),
                label: Text(_isSpeaking ? 'Speaking...' : 'Play'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filledTonal(
              tooltip: 'Pause',
              onPressed: () => ref.read(ttsServiceProvider).pause(),
              icon: const Icon(Icons.pause_rounded),
            ),
            IconButton.filledTonal(
              tooltip: 'Stop',
              onPressed: () {
                ref.read(ttsServiceProvider).stop();
                setState(() => _isSpeaking = false);
              },
              icon: const Icon(Icons.stop_rounded),
            ),
            IconButton.filledTonal(
              tooltip: 'Replay',
              onPressed: () => ref.read(ttsServiceProvider).replay(),
              icon: const Icon(Icons.replay_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(onPressed: _reset, child: const Text('Try Another Image')),
      ],
    );
  }
}
